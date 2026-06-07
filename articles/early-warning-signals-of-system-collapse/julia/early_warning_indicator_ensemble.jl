# early_warning_indicator_ensemble.jl
# Julia early-warning indicator ensemble workflow.

using Statistics
using DelimitedFiles
using Random

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function linear_space(start_value, stop_value, count)
    step = (stop_value - start_value) / (count - 1)
    return [start_value + (i - 1) * step for i in 1:count]
end

function lag1_autocorrelation(values)
    if length(values) < 3
        return missing
    end

    left = values[1:end-1]
    right = values[2:end]

    if std(left) == 0 || std(right) == 0
        return missing
    end

    return cor(left, right)
end

function rolling_metrics(values, window)
    if length(values) < window
        return (missing, missing)
    end

    recent = values[end-window+1:end]
    return (var(recent), lag1_autocorrelation(recent))
end

function simulate_series(scenario, steps, stability_start, stability_end, noise_sd, window)
    Random.seed!(42)
    state = 0.0
    history = Float64[]
    rows = []
    stability_values = linear_space(stability_start, stability_end, steps)

    for time in 1:steps
        stability = stability_values[time]

        if time > 1
            state = stability * state + randn() * noise_sd
        end

        push!(history, state)
        rolling_variance, rolling_ac1 = rolling_metrics(history, window)

        push!(rows, (
            scenario,
            time,
            state,
            abs(state),
            stability,
            noise_sd,
            window,
            ismissing(rolling_variance) ? "" : rolling_variance,
            ismissing(rolling_ac1) ? "" : rolling_ac1
        ))
    end

    return rows
end

scenarios = [
    ("baseline_destabilization", 320, 0.55, 0.985, 1.00, 25),
    ("moderate_destabilization", 320, 0.45, 0.900, 1.00, 25),
    ("high_noise_destabilization", 320, 0.55, 0.985, 1.40, 25),
    ("low_noise_destabilization", 320, 0.55, 0.985, 0.65, 25)
]

all_rows = []

for scenario in scenarios
    append!(all_rows, simulate_series(scenario...))
end

trajectory_path = joinpath(tables_dir, "julia_early_warning_indicator_trajectories.csv")
header = ["scenario" "time" "state" "absolute_state" "stability" "noise_sd" "window" "rolling_variance" "rolling_autocorrelation"]
writedlm(trajectory_path, header, ',')

matrix = hcat(
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
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in scenarios
    name = scenario[1]
    subset = [row for row in all_rows if row[1] == name]
    states = [row[3] for row in subset]
    variances = [row[8] for row in subset if row[8] != ""]
    ac1s = [row[9] for row in subset if row[9] != ""]

    push!(summary_rows, (
        name,
        subset[end][5],
        states[end],
        maximum(abs.(states)),
        isempty(variances) ? "" : variances[end],
        isempty(ac1s) ? "" : ac1s[end]
    ))
end

summary_path = joinpath(tables_dir, "julia_early_warning_indicator_summary.csv")
summary_header = ["scenario" "final_stability" "final_state" "maximum_abs_state" "final_rolling_variance" "final_rolling_autocorrelation"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia early-warning indicator ensemble complete.")
println(summary_path)
