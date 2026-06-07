# digital_twin_monitoring_ensemble.jl
# Julia digital twin monitoring ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_twin(
    scenario;
    n_steps = 120,
    initial_state = 50.0,
    state_persistence = 0.95,
    drift_amplitude = 0.15,
    process_noise = 0.60,
    observation_noise = 1.80,
    update_gain = 0.35,
    anomaly_threshold = 3.50,
    intervention_effect = 1.00,
    shock_times = Set([35, 80, 105]),
    shock_magnitude = 4.0,
    seed_value = 42
)
    Random.seed!(seed_value)

    true_state = zeros(n_steps)
    observed_state = zeros(n_steps)
    prediction_before_update = zeros(n_steps)
    twin_state = zeros(n_steps)
    residual = zeros(n_steps)
    anomaly_flag = zeros(Int, n_steps)
    intervention_flag = zeros(Int, n_steps)

    true_state[1] = initial_state
    observed_state[1] = true_state[1] + randn() * observation_noise
    twin_state[1] = observed_state[1]
    prediction_before_update[1] = twin_state[1]

    for time in 2:n_steps
        drift = drift_amplitude * sin(time / 12.0)
        shock = (time in shock_times) ? shock_magnitude : 0.0

        true_state[time] = state_persistence * true_state[time - 1] + drift + shock + randn() * process_noise
        observed_state[time] = true_state[time] + randn() * observation_noise

        prediction = state_persistence * twin_state[time - 1] + drift
        residual[time] = observed_state[time] - prediction

        if abs(residual[time]) > anomaly_threshold
            anomaly_flag[time] = 1
        end

        if residual[time] > anomaly_threshold
            intervention_flag[time] = 1
            prediction -= intervention_effect
        end

        prediction_before_update[time] = prediction
        twin_state[time] = prediction + update_gain * residual[time]
    end

    rows = []
    for time in 1:n_steps
        push!(rows, (
            scenario,
            time,
            true_state[time],
            observed_state[time],
            prediction_before_update[time],
            twin_state[time],
            residual[time],
            anomaly_flag[time],
            intervention_flag[time]
        ))
    end

    observed_mae = mean(abs.(observed_state .- true_state))
    twin_mae = mean(abs.(twin_state .- true_state))
    observed_rmse = sqrt(mean((observed_state .- true_state).^2))
    twin_rmse = sqrt(mean((twin_state .- true_state).^2))
    improvement = (observed_rmse - twin_rmse) / max(observed_rmse, 1e-12)

    summary = (
        scenario,
        observed_mae,
        twin_mae,
        observed_rmse,
        twin_rmse,
        sum(anomaly_flag),
        sum(intervention_flag),
        improvement,
        twin_rmse < observed_rmse ? "twin improved noisy observation" : "twin did not improve noisy observation"
    )

    return rows, summary
end

scenarios = [
    ("baseline_twin", Dict(:seed_value => 42)),
    ("high_noise_twin", Dict(:observation_noise => 3.20, :update_gain => 0.30, :anomaly_threshold => 4.80, :seed_value => 43)),
    ("shock_heavy_twin", Dict(:process_noise => 0.75, :shock_times => Set([25, 45, 65, 85, 105]), :shock_magnitude => 5.5, :seed_value => 44)),
    ("slow_update_twin", Dict(:update_gain => 0.18, :seed_value => 45)),
    ("resilient_twin", Dict(:process_noise => 0.45, :observation_noise => 1.25, :update_gain => 0.45, :anomaly_threshold => 3.25, :intervention_effect => 1.25, :shock_magnitude => 3.5, :seed_value => 46))
]

all_rows = []
summary_rows = []

for (name, kwargs) in scenarios
    rows, summary = simulate_twin(name; kwargs...)
    append!(all_rows, rows)
    push!(summary_rows, summary)
end

trajectory_path = joinpath(tables_dir, "julia_digital_twin_trajectories.csv")
trajectory_header = ["scenario" "time" "true_state" "observed_state" "prediction_before_update" "twin_state" "residual" "anomaly_flag" "intervention_flag"]
writedlm(trajectory_path, trajectory_header, ',')

trajectory_matrix = hcat(
    [row[1] for row in all_rows],
    [row[2] for row in all_rows],
    [row[3] for row in all_rows],
    [row[4] for row in all_rows],
    [row[5] for row in all_rows],
    [row[6] for row in all_rows],
    [row[7] for row in all_rows],
    [row[8] for row in all_rows],
    [row[9] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, trajectory_matrix, ',')
end

summary_path = joinpath(tables_dir, "julia_digital_twin_summary.csv")
summary_header = ["scenario" "MAE_observed" "MAE_twin" "RMSE_observed" "RMSE_twin" "anomaly_count" "intervention_count" "tracking_improvement_ratio" "diagnostic_label"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows],
    [row[8] for row in summary_rows],
    [row[9] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia digital twin monitoring ensemble complete.")
println(summary_path)
