# conceptual_formal_gap_ensemble.jl
# Julia ensemble for conceptual-to-formal systems modeling gap diagnostics.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function clamp(value, low, high)
    return max(low, min(high, value))
end

function simulate_member(seed)
    Random.seed!(seed)

    demand_growth = rand() * 0.012 + 0.012
    capacity_growth = rand() * 0.014 + 0.004
    rework_rate = rand() * 0.018 + 0.008
    intervention_pressure = rand() * 0.70 + 0.10
    systems_redesign_strength = rand() * 0.80 + 0.10
    uncertainty_humility = rand() * 0.80 + 0.10
    delay_factor = rand() * 0.70 + 0.10

    demand = 80.0
    capacity = 70.0
    backlog = 22.0
    trust = 58.0
    rework = 8.0
    learning = 22.0

    final_conceptual_score = 0.0
    final_modeled_score = 0.0
    maximum_backlog = backlog
    minimum_trust = trust

    for period in 0:80
        service_gap = max(demand + backlog - capacity, 0.0)
        service_quality = clamp(100.0 - service_gap * 0.50 - rework * 0.35, 0.0, 100.0)

        conceptual_score = clamp(
            50.0 + systems_redesign_strength * 24.0 + uncertainty_humility * 14.0 -
            intervention_pressure * 8.0 - service_gap * 0.08,
            0.0,
            100.0
        )

        modeled_score = clamp(
            service_quality * 0.30 + trust * 0.25 + learning * 0.20 + capacity * 0.10 -
            backlog * 0.10 - rework * 0.15,
            0.0,
            100.0
        )

        final_conceptual_score = conceptual_score
        final_modeled_score = modeled_score
        maximum_backlog = max(maximum_backlog, backlog)
        minimum_trust = min(minimum_trust, trust)

        pressure_gain = intervention_pressure * 4.0
        redesign_gain = systems_redesign_strength * 3.2
        delayed_learning_effect = learning * 0.03 * (1.0 - delay_factor)

        demand += demand_growth * demand
        capacity += capacity_growth * capacity + redesign_gain + delayed_learning_effect - rework * 0.015
        backlog += demand * 0.10 + rework * 0.30 - capacity * 0.09 - redesign_gain * 0.80
        rework += service_gap * rework_rate + pressure_gain * 0.15 - redesign_gain * 0.45
        trust += -backlog * 0.006 + service_quality * 0.006 + redesign_gain * 0.10
        learning += uncertainty_humility * 1.3 + systems_redesign_strength * 1.1 - intervention_pressure * 0.45

        demand = clamp(demand, 0.0, 200.0)
        capacity = clamp(capacity, 0.0, 200.0)
        backlog = clamp(backlog, 0.0, 200.0)
        trust = clamp(trust, 0.0, 100.0)
        rework = clamp(rework, 0.0, 120.0)
        learning = clamp(learning, 0.0, 100.0)
    end

    return (
        seed=seed,
        demand_growth=demand_growth,
        capacity_growth=capacity_growth,
        rework_rate=rework_rate,
        intervention_pressure=intervention_pressure,
        systems_redesign_strength=systems_redesign_strength,
        uncertainty_humility=uncertainty_humility,
        delay_factor=delay_factor,
        final_conceptual_score=final_conceptual_score,
        final_modeled_score=final_modeled_score,
        conceptual_model_gap=final_conceptual_score - final_modeled_score,
        maximum_backlog=maximum_backlog,
        minimum_trust=minimum_trust
    )
end

rows = [simulate_member(8000 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_conceptual_formal_gap_ensemble.csv")
header = ["seed" "demand_growth" "capacity_growth" "rework_rate" "intervention_pressure" "systems_redesign_strength" "uncertainty_humility" "delay_factor" "final_conceptual_score" "final_modeled_score" "conceptual_model_gap" "maximum_backlog" "minimum_trust"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.demand_growth for row in rows],
    [row.capacity_growth for row in rows],
    [row.rework_rate for row in rows],
    [row.intervention_pressure for row in rows],
    [row.systems_redesign_strength for row in rows],
    [row.uncertainty_humility for row in rows],
    [row.delay_factor for row in rows],
    [row.final_conceptual_score for row in rows],
    [row.final_modeled_score for row in rows],
    [row.conceptual_model_gap for row in rows],
    [row.maximum_backlog for row in rows],
    [row.minimum_trust for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia conceptual-formal gap ensemble complete.")
println("Median modeled score: ", median([row.final_modeled_score for row in rows]))
println(path)
