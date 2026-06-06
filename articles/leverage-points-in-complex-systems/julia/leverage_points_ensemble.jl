# leverage_points_ensemble.jl
# Julia intervention-depth ensemble workflow.

using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_system(feedback_gain, external_correction, information_delay, information_quality, buffer_capacity, rule_threshold, rule_feedback_gain, self_org_rate, goal_weight_resilience, implementation_delay; steps=96)
    state = zeros(Float64, steps)
    pressure = zeros(Float64, steps)
    resilience = zeros(Float64, steps)
    learning_capacity = zeros(Float64, steps)
    intervention = zeros(Float64, steps)
    buffer_remaining = zeros(Float64, steps)

    state[1] = 70.0
    pressure[1] = 50.0
    resilience[1] = 30.0
    buffer_remaining[1] = buffer_capacity

    for t in 2:steps
        observed_index = max(1, t - information_delay)
        delayed_signal = state[observed_index]
        current_signal = state[t - 1]
        observed_state = information_quality * current_signal + (1.0 - information_quality) * delayed_signal

        current_gain = feedback_gain
        if !isnan(rule_threshold) && observed_state > rule_threshold
            current_gain = rule_feedback_gain
        end

        learning_capacity[t] = min(100.0, learning_capacity[t - 1] + self_org_rate * (100.0 - learning_capacity[t - 1]) / 8.0)
        resilience_gap = max(0.0, 100.0 - resilience[t - 1])
        resilience_investment = goal_weight_resilience * resilience_gap

        buffer_absorption = min(buffer_remaining[t - 1], 0.10 * pressure[t - 1])
        buffer_remaining[t] = max(0.0, buffer_remaining[t - 1] - buffer_absorption + 0.02 * buffer_capacity)

        correction = 0.0
        if t >= implementation_delay
            correction = external_correction + 0.05 * max(0.0, observed_state - 40.0) + resilience_investment + 0.04 * learning_capacity[t]
        end

        intervention[t] = correction

        pressure[t] = max(0.0, 0.91 * pressure[t - 1] + 0.07 * state[t - 1] - 0.30 * correction - 0.08 * buffer_absorption - 0.04 * resilience[t - 1])
        resilience[t] = min(100.0, max(0.0, resilience[t - 1] + 0.18 * resilience_investment + 0.05 * learning_capacity[t] - 0.025 * pressure[t - 1]))
        state[t] = max(0.0, current_gain * state[t - 1] + 0.24 * pressure[t] - 0.34 * correction - 0.08 * buffer_absorption - 0.045 * resilience[t])
    end

    return state, pressure, resilience, learning_capacity, intervention
end

scenarios = [
    ("baseline", 0.96, 2.0, 6, 0.70, 0.0, NaN, 0.96, 0.00, 0.00, 1),
    ("parameter_intervention", 0.96, 5.0, 6, 0.70, 0.0, NaN, 0.96, 0.00, 0.00, 1),
    ("feedback_intervention", 0.78, 2.0, 6, 0.70, 0.0, NaN, 0.78, 0.00, 0.00, 1),
    ("rule_intervention", 0.96, 2.0, 2, 0.85, 0.0, 45.0, 0.70, 0.00, 0.00, 1),
    ("goal_intervention", 0.90, 2.0, 2, 0.90, 10.0, 45.0, 0.72, 0.12, 0.10, 1)
]

results = Dict{String, Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}, Vector{Float64}, Vector{Float64}}}()

for scenario in scenarios
    name, feedback_gain, external_correction, information_delay, information_quality, buffer_capacity, rule_threshold, rule_feedback_gain, self_org_rate, goal_weight, implementation_delay = scenario
    results[name] = simulate_system(feedback_gain, external_correction, information_delay, information_quality, buffer_capacity, rule_threshold, rule_feedback_gain, self_org_rate, goal_weight, implementation_delay)
end

baseline_final = results["baseline"][1][end]
rows = []

for scenario in scenarios
    name = scenario[1]
    state, pressure, resilience, learning_capacity, intervention = results[name]
    cumulative_intervention = sum(intervention)
    behavior_change = baseline_final - state[end]
    leverage_ratio = cumulative_intervention > 0 ? behavior_change / cumulative_intervention : 0.0

    push!(rows, (
        name,
        state[1],
        state[end],
        maximum(state),
        mean(pressure),
        resilience[end],
        learning_capacity[end],
        cumulative_intervention,
        behavior_change,
        leverage_ratio
    ))
end

path = joinpath(tables_dir, "julia_leverage_intervention_summary.csv")
header = ["scenario" "initial_state" "final_state" "maximum_state" "mean_pressure" "final_resilience" "final_learning_capacity" "cumulative_intervention" "behavior_change_from_baseline" "leverage_ratio"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows],
    [row[6] for row in rows],
    [row[7] for row in rows],
    [row[8] for row in rows],
    [row[9] for row in rows],
    [row[10] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia leverage points ensemble complete.")
println(path)
