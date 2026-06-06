# calibration_uncertainty_ensemble.jl
# Julia ensemble for calibration uncertainty and validation diagnostics.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_model(growth_rate, carrying_capacity, n_steps, initial_state)
    values = zeros(Float64, n_steps)
    values[1] = initial_state

    for i in 2:n_steps
        previous = values[i - 1]
        values[i] = max(0.0, previous + growth_rate * previous * (1.0 - previous / carrying_capacity))
    end

    return values
end

function rmse(actual, predicted)
    return sqrt(mean((actual .- predicted).^2))
end

Random.seed!(42)

n_steps = 80
train_cutoff = 52
true_growth_rate = 0.095
true_capacity = 120.0
noise_sd = 0.85

true_state = simulate_model(true_growth_rate, true_capacity, n_steps, 10.0)
observed = [max(0.0, value + randn() * noise_sd) for value in true_state]

train_observed = observed[1:train_cutoff]
valid_observed = observed[(train_cutoff + 1):end]

rows = []

for run_id in 1:500
    growth_rate = 0.040 + rand() * (0.200 - 0.040)
    carrying_capacity = 70.0 + rand() * (180.0 - 70.0)

    train_predicted = simulate_model(growth_rate, carrying_capacity, length(train_observed), train_observed[1])
    valid_predicted = simulate_model(growth_rate, carrying_capacity, length(valid_observed) + 1, train_observed[end])[2:end]

    train_rmse = rmse(train_observed, train_predicted)
    valid_rmse = rmse(valid_observed, valid_predicted)

    push!(rows, (
        run_id,
        growth_rate,
        carrying_capacity,
        train_rmse,
        valid_rmse,
        valid_rmse - train_rmse
    ))
end

path = joinpath(tables_dir, "julia_calibration_uncertainty_ensemble.csv")
header = ["run_id" "growth_rate" "carrying_capacity" "calibration_rmse" "validation_rmse" "generalization_gap"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows],
    [row[6] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

best = rows[argmin([row[5] for row in rows])]

println("Julia calibration uncertainty ensemble complete.")
println("Best validation RMSE: ", best[5])
println(path)
