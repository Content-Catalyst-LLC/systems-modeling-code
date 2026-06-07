# ai_hybrid_ensemble.jl
# Julia hybrid systems learning ensemble workflow.

using DelimitedFiles
using Random
using Statistics
using LinearAlgebra

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function make_features(a, b, c, share)
    return [1.0, a, b, c, b^2, a*b, sin(a), share]
end

function simulate_scenario(name; n=1000, noise_scale=0.50, structural_weight=1.0, residual_strength=0.70, interaction_strength=0.25, drift_strength=0.0, seed=42)
    Random.seed!(seed)
    rows = []

    for index in 0:(n - 1)
        share = index / max(n - 1, 1)
        a = rand() * 10.0
        b = rand() * 6.0 - 3.0
        c = rand() * 7.0 + 1.0

        baseline = structural_weight * (1.8 * sin(a) + 0.6 * b - 0.4 * c)
        true_response = baseline + residual_strength * b^2 + interaction_strength * a * b + drift_strength * share * b + randn() * noise_scale
        residual = true_response - baseline

        push!(rows, (name, index, share, a, b, c, baseline, true_response, residual))
    end

    return rows
end

function fit_residual_model(rows)
    x = reduce(vcat, [make_features(row[4], row[5], row[6], row[3])' for row in rows])
    y = [row[9] for row in rows]
    weights = x \ y
    return weights
end

function predict_residual(weights, row)
    x = make_features(row[4], row[5], row[6], row[3])
    return dot(weights, x)
end

function rmse(actual, predicted)
    return sqrt(mean((actual .- predicted).^2))
end

function mae(actual, predicted)
    return mean(abs.(actual .- predicted))
end

scenarios = [
    ("baseline_hybrid", 1000, 0.50, 1.00, 0.70, 0.25, 0.00, 42),
    ("high_noise_system", 1000, 0.95, 1.00, 0.70, 0.25, 0.00, 43),
    ("strong_residual_system", 1000, 0.50, 1.00, 1.10, 0.38, 0.00, 44),
    ("drifting_system", 1000, 0.55, 1.00, 0.70, 0.25, 0.45, 45)
]

prediction_rows = []
summary_rows = []

for s in scenarios
    name, n, noise, structural_weight, residual_strength, interaction_strength, drift_strength, seed = s
    rows = simulate_scenario(
        name;
        n=n,
        noise_scale=noise,
        structural_weight=structural_weight,
        residual_strength=residual_strength,
        interaction_strength=interaction_strength,
        drift_strength=drift_strength,
        seed=seed
    )

    split = Int(floor(0.75 * length(rows)))
    train_rows = rows[1:split]
    test_rows = rows[(split + 1):end]
    weights = fit_residual_model(train_rows)

    actual = Float64[]
    baseline_pred = Float64[]
    hybrid_pred = Float64[]

    for row in test_rows
        learned_residual = predict_residual(weights, row)
        hybrid_prediction = row[7] + learned_residual

        push!(actual, row[8])
        push!(baseline_pred, row[7])
        push!(hybrid_pred, hybrid_prediction)

        push!(prediction_rows, (
            row[1],
            row[2],
            row[4],
            row[5],
            row[6],
            row[8],
            row[7],
            learned_residual,
            hybrid_prediction,
            row[8] - row[7],
            row[8] - hybrid_prediction
        ))
    end

    base_rmse = rmse(actual, baseline_pred)
    hybrid_rmse = rmse(actual, hybrid_pred)
    base_mae = mae(actual, baseline_pred)
    hybrid_mae = mae(actual, hybrid_pred)
    improvement = (base_rmse - hybrid_rmse) / max(base_rmse, 1e-12)

    push!(summary_rows, (
        name,
        base_rmse,
        hybrid_rmse,
        base_mae,
        hybrid_mae,
        improvement,
        hybrid_rmse < base_rmse ? "hybrid improved baseline" : "hybrid did not improve baseline"
    ))
end

prediction_path = joinpath(tables_dir, "julia_ai_hybrid_predictions.csv")
prediction_header = ["scenario" "index" "input_a" "input_b" "input_c" "true_response" "structural_baseline" "learned_residual" "hybrid_prediction" "baseline_error" "hybrid_error"]
writedlm(prediction_path, prediction_header, ',')

prediction_matrix = hcat(
    [row[1] for row in prediction_rows],
    [row[2] for row in prediction_rows],
    [row[3] for row in prediction_rows],
    [row[4] for row in prediction_rows],
    [row[5] for row in prediction_rows],
    [row[6] for row in prediction_rows],
    [row[7] for row in prediction_rows],
    [row[8] for row in prediction_rows],
    [row[9] for row in prediction_rows],
    [row[10] for row in prediction_rows],
    [row[11] for row in prediction_rows]
)

open(prediction_path, "a") do io
    writedlm(io, prediction_matrix, ',')
end

summary_path = joinpath(tables_dir, "julia_ai_hybrid_metrics.csv")
summary_header = ["scenario" "baseline_rmse" "hybrid_rmse" "baseline_mae" "hybrid_mae" "hybrid_improvement_ratio" "diagnostic_label"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia AI hybrid systems ensemble complete.")
println(summary_path)
