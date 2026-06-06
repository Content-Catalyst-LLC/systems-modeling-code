# stress_robustness_ensemble.jl
# Julia stress ensemble and lower-tail robustness diagnostics.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_strategy(demand_growth, capacity_loss, shock_duration, recovery_drag, redundancy, adaptive_response; steps=72)
    baseline_capacity = 100.0
    demand = 55.0
    capacity = baseline_capacity * (1.0 + redundancy)
    minimum_service = 1.0
    cumulative_unmet = 0.0
    failure_count = 0
    shock_start = 28

    for time in 1:steps
        demand *= 1.0 + demand_growth
        shock_active = time >= shock_start && time < shock_start + shock_duration

        if time == shock_start
            capacity = max(0.0, capacity - capacity_loss)
        end

        if shock_active
            demand *= 1.010
        else
            recovery_rate = max(0.0, 0.12 + adaptive_response - recovery_drag)
            target_capacity = baseline_capacity * (1.0 + redundancy)
            capacity += recovery_rate * (target_capacity - capacity)
        end

        service_ratio = demand <= 0 ? 1.0 : min(capacity / demand, 1.0)
        unmet = max(demand - capacity, 0.0)

        minimum_service = min(minimum_service, service_ratio)
        cumulative_unmet += unmet

        if service_ratio < 0.85
            failure_count += 1
        end
    end

    score = max(0.0, min(100.0, 100.0 - 70.0 * (1.0 - minimum_service) - 0.05 * cumulative_unmet - 0.40 * failure_count))

    return minimum_service, cumulative_unmet, failure_count / steps, score
end

Random.seed!(42)

strategies = [
    ("Strategy_A_efficiency", 0.02, 0.02),
    ("Strategy_B_balanced_resilience", 0.12, 0.06),
    ("Strategy_C_high_redundancy", 0.25, 0.03),
    ("Strategy_D_adaptive_pathway", 0.08, 0.11)
]

rows = []

for scenario_id in 1:600
    demand_growth = 0.008 + rand() * (0.035 - 0.008)
    capacity_loss = rand() * 45.0
    shock_duration = rand(1:20)
    recovery_drag = rand() * 0.09

    for (strategy, redundancy, adaptive_response) in strategies
        minimum_service, cumulative_unmet, failure_frequency, score = simulate_strategy(
            demand_growth,
            capacity_loss,
            shock_duration,
            recovery_drag,
            redundancy,
            adaptive_response
        )

        push!(rows, (
            scenario_id,
            strategy,
            demand_growth,
            capacity_loss,
            shock_duration,
            recovery_drag,
            minimum_service,
            cumulative_unmet,
            failure_frequency,
            score
        ))
    end
end

path = joinpath(tables_dir, "julia_stress_robustness_ensemble.csv")
header = ["scenario_id" "strategy" "demand_growth" "capacity_loss" "shock_duration" "recovery_drag" "minimum_service_ratio" "cumulative_unmet_demand" "failure_frequency" "resilience_score"]
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

println("Julia stress robustness ensemble complete.")
println(path)
