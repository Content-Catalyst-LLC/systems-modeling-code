# public_policy_ensemble.jl
# Julia adaptive policy ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function bounded(value, low, high)
    return max(low, min(high, value))
end

function simulate_policy_system(
    scenario;
    n_steps = 100,
    target_state = 16.0,
    system_state = 12.0,
    institutional_capacity = 7.0,
    trust = 0.58,
    administrative_burden = 0.25,
    policy_intensity = 1.0,
    max_policy = 2.0,
    min_policy = 0.25,
    policy_increase_rate = 0.08,
    policy_decrease_rate = 0.05,
    policy_effect = 0.55,
    capacity_learning_rate = 0.09,
    burden_growth = 0.05,
    burden_relief = 0.025,
    side_effect_rate = 0.08,
    seed_value = 42
)
    Random.seed!(seed_value)
    side_effect = 0.0
    rows = []

    for time in 0:(n_steps - 1)
        uptake = bounded(
            0.42 + 0.30 * trust + 0.035 * institutional_capacity - 0.45 * administrative_burden,
            0.0,
            1.0
        )

        performance_gap = target_state - system_state

        if performance_gap > 0
            policy_intensity = min(max_policy, policy_intensity + policy_increase_rate)
        else
            policy_intensity = max(min_policy, policy_intensity - policy_decrease_rate)
        end

        push!(rows, (
            scenario,
            time,
            system_state,
            target_state,
            performance_gap,
            policy_intensity,
            institutional_capacity,
            trust,
            administrative_burden,
            uptake,
            side_effect
        ))

        next_state = system_state +
            policy_effect * policy_intensity * uptake -
            0.12 * system_state +
            0.05 * institutional_capacity +
            randn() * 0.12

        next_capacity = institutional_capacity + capacity_learning_rate * (system_state - institutional_capacity)
        next_burden = max(0.0, administrative_burden + burden_growth * policy_intensity - burden_relief * institutional_capacity)
        next_side_effect = max(0.0, side_effect + side_effect_rate * policy_intensity - 0.06 * side_effect)

        next_trust = bounded(
            trust + 0.015 * uptake - 0.018 * next_burden - 0.010 * next_side_effect,
            0.0,
            1.0
        )

        system_state = max(0.0, next_state)
        institutional_capacity = max(0.0, next_capacity)
        administrative_burden = next_burden
        side_effect = next_side_effect
        trust = next_trust
    end

    return rows
end

scenarios = [
    ("baseline_adaptive_policy", Dict(:seed_value => 42)),
    ("aggressive_policy_rule", Dict(:policy_increase_rate => 0.14, :max_policy => 2.4, :seed_value => 43)),
    ("low_capacity_learning", Dict(:capacity_learning_rate => 0.035, :seed_value => 44)),
    ("high_burden_design", Dict(:burden_growth => 0.10, :seed_value => 45)),
    ("trust_centered_design", Dict(:trust => 0.72, :burden_growth => 0.025, :side_effect_rate => 0.045, :seed_value => 46)),
    ("capacity_first_policy", Dict(:institutional_capacity => 9.0, :trust => 0.64, :administrative_burden => 0.20, :capacity_learning_rate => 0.13, :burden_growth => 0.030, :seed_value => 49))
]

all_rows = []

for (name, kwargs) in scenarios
    append!(all_rows, simulate_policy_system(name; kwargs...))
end

trajectory_path = joinpath(tables_dir, "julia_public_policy_adaptive_trajectories.csv")
header = ["scenario" "time" "system_state" "target_state" "performance_gap" "policy_intensity" "institutional_capacity" "trust" "administrative_burden" "uptake" "side_effect"]
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
    [row[9] for row in all_rows],
    [row[10] for row in all_rows],
    [row[11] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    final = subset[end]
    maximum_burden = maximum([row[9] for row in subset])
    maximum_side_effect = maximum([row[11] for row in subset])
    average_uptake = mean([row[10] for row in subset])
    average_policy = mean([row[6] for row in subset])
    label = maximum_burden > 1.0 || maximum_side_effect > 1.0 ? "high burden policy pathway" : "manageable policy pathway"

    push!(summary_rows, (
        scenario,
        final[3],
        final[6],
        final[7],
        final[8],
        maximum_burden,
        maximum_side_effect,
        average_uptake,
        average_policy,
        label
    ))
end

summary_path = joinpath(tables_dir, "julia_public_policy_adaptive_summary.csv")
summary_header = ["scenario" "final_system_state" "final_policy_intensity" "final_capacity" "final_trust" "maximum_burden" "maximum_side_effect" "average_uptake" "average_policy_intensity" "diagnostic_label"]
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
    [row[9] for row in summary_rows],
    [row[10] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia public policy ensemble complete.")
println(trajectory_path)
println(summary_path)
