# delay_oscillation_ensemble.jl
# Julia delay, oscillation, and policy resistance ensemble workflow.

using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function target_crossings(values, target)
    crossings = 0
    for i in 2:length(values)
        left_gap = values[i - 1] - target
        right_gap = values[i] - target
        if left_gap == 0 || right_gap == 0
            continue
        end
        if (left_gap < 0 && right_gap > 0) || (left_gap > 0 && right_gap < 0)
            crossings += 1
        end
    end
    return crossings
end

function simulate_delay_system(name, delay, correction_strength, counterresponse_strength, perception_smoothing; steps=100)
    target = 50.0
    state = zeros(Float64, steps)
    perceived_state = zeros(Float64, steps)
    intervention = zeros(Float64, steps)
    counterresponse = zeros(Float64, steps)

    state[1] = 80.0
    perceived_state[1] = 80.0

    for t in 2:steps
        perceived_state[t] = perception_smoothing * state[t - 1] + (1.0 - perception_smoothing) * perceived_state[t - 1]
        observed_index = max(1, t - delay)
        observed_gap = perceived_state[observed_index] - target
        intervention[t] = correction_strength * max(0.0, observed_gap)
        counterresponse[t] = counterresponse_strength * intervention[t]
        natural_pressure = 2.0 + 0.025 * state[t - 1]
        state[t] = max(0.0, state[t - 1] + natural_pressure + counterresponse[t] - intervention[t])
    end

    return state, perceived_state, intervention, counterresponse
end

scenarios = [
    ("timely_moderate_response", 1, 0.18, 0.00, 0.75),
    ("delayed_response", 6, 0.18, 0.00, 0.55),
    ("overcorrection", 6, 0.34, 0.00, 0.55),
    ("undercorrection", 6, 0.09, 0.00, 0.55),
    ("policy_resistance", 6, 0.24, 0.42, 0.55),
    ("slow_recognition_high_resistance", 10, 0.24, 0.55, 0.35)
]

summary_rows = []

for scenario in scenarios
    name, delay, correction_strength, counterresponse_strength, perception_smoothing = scenario
    state, perceived_state, intervention, counterresponse = simulate_delay_system(name, delay, correction_strength, counterresponse_strength, perception_smoothing)
    target = 50.0
    gaps = state .- target
    cumulative_intervention = sum(intervention)
    cumulative_counterresponse = sum(counterresponse)
    resistance_ratio = cumulative_intervention > 0 ? cumulative_counterresponse / cumulative_intervention : 0.0

    push!(summary_rows, (
        name,
        delay,
        correction_strength,
        counterresponse_strength,
        state[1],
        state[end],
        minimum(state),
        maximum(state),
        target_crossings(state, target),
        max(0.0, maximum(state .- target)),
        mean(abs.(gaps)),
        cumulative_intervention,
        cumulative_counterresponse,
        resistance_ratio
    ))
end

path = joinpath(tables_dir, "julia_delay_oscillation_summary.csv")
header = ["scenario" "delay" "correction_strength" "counterresponse_strength" "initial_state" "final_state" "minimum_state" "maximum_state" "target_crossings" "maximum_overshoot_above_target" "mean_absolute_target_gap" "cumulative_intervention" "cumulative_counterresponse" "resistance_ratio"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows],
    [row[8] for row in summary_rows],
    [row[9] for row in summary_rows],
    [row[10] for row in summary_rows],
    [row[11] for row in summary_rows],
    [row[12] for row in summary_rows],
    [row[13] for row in summary_rows],
    [row[14] for row in summary_rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia delay oscillation ensemble complete.")
println(path)
