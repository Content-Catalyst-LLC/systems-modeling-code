# scenario_uncertainty_ensemble.jl
# Julia ensemble for scenario uncertainty and policy comparison.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function resilience_score(final_state, maximum_state, cumulative_cost)
    return max(0.0, min(100.0, 100.0 - 0.8 * final_state - 0.3 * maximum_state - 0.2 * cumulative_cost))
end

function simulate_policy(growth, policy_drag, external_shock, shock_time, resilience_buffer; steps=60)
    state = 20.0
    maximum_state = state
    minimum_state = state
    cumulative_cost = 0.0

    for time in 1:steps
        state = state + growth * state - policy_drag * state

        if time == shock_time
            state = max(0.0, state - external_shock / max(1.0, resilience_buffer))
        end

        policy_cost = 4.0 * policy_drag + 0.08 * resilience_buffer
        stress_cost = 0.03 * max(state - 35.0, 0.0)^2
        cumulative_cost += policy_cost + stress_cost

        maximum_state = max(maximum_state, state)
        minimum_state = min(minimum_state, state)
    end

    return (
        final_state=state,
        maximum_state=maximum_state,
        minimum_state=minimum_state,
        cumulative_cost=cumulative_cost,
        resilience_score=resilience_score(state, maximum_state, cumulative_cost)
    )
end

policies = [
    ("Policy_A_low_intervention", 0.010, 4.0),
    ("Policy_B_moderate_intervention", 0.025, 7.0),
    ("Policy_C_high_resilience", 0.020, 12.0)
]

rows = []

Random.seed!(4242)

for scenario_id in 1:300
    growth = rand() * 0.045 + 0.030
    external_shock = rand() * 18.0
    shock_time = rand(20:45)

    for (policy_name, policy_drag, resilience_buffer) in policies
        result = simulate_policy(growth, policy_drag, external_shock, shock_time, resilience_buffer)

        push!(rows, (
            scenario_id,
            policy_name,
            growth,
            external_shock,
            shock_time,
            policy_drag,
            resilience_buffer,
            result.final_state,
            result.maximum_state,
            result.cumulative_cost,
            result.resilience_score
        ))
    end
end

path = joinpath(tables_dir, "julia_scenario_uncertainty_ensemble.csv")
header = ["scenario_id" "policy" "growth" "external_shock" "shock_time" "policy_drag" "resilience_buffer" "final_state" "maximum_state" "cumulative_cost" "resilience_score"]
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
    [row[10] for row in rows],
    [row[11] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

scores = [row[11] for row in rows]
println("Julia scenario uncertainty ensemble complete.")
println("Median resilience score: ", median(scores))
println(path)
