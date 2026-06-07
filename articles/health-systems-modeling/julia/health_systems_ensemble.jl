# health_systems_ensemble.jl
# Julia health system pressure ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function bounded(value, low, high)
    return max(low, min(high, value))
end

function simulate_health_system(
    scenario;
    n_steps = 120,
    capacity = 100.0,
    demand = 92.0,
    trust = 0.64,
    demand_growth = 0.35,
    prevention_effect = 0.015,
    workforce_recovery = 0.035,
    burnout_sensitivity = 0.085,
    attrition_sensitivity = 0.030,
    hiring_rate = 0.50,
    access_barrier = 0.18,
    trust_loss_rate = 0.020,
    trust_gain_rate = 0.012,
    surge_start = 45,
    surge_end = 65,
    surge_intensity = 18.0,
    seed_value = 42
)
    Random.seed!(seed_value)
    initial_demand = demand
    backlog = 0.0
    burnout = 0.12
    rows = []

    for time in 0:(n_steps - 1)
        pressure = demand / max(capacity, 1.0)
        slack = max(1.0 - pressure, 0.0)
        burnout = max(0.0, burnout + burnout_sensitivity * max(pressure - 1.0, 0.0) - workforce_recovery * slack)
        attrition = attrition_sensitivity * burnout * capacity
        surge = surge_start <= time <= surge_end ? surge_intensity : 0.0
        effective_capacity = max(0.0, capacity + hiring_rate - attrition - 0.10 * max(pressure - 1.0, 0.0) * capacity)
        served = min(demand, effective_capacity)
        unmet_need = max(demand - served, 0.0)
        access_gap = access_barrier * demand + unmet_need
        backlog = max(0.0, backlog + demand - served)
        trust = bounded(trust + trust_gain_rate * slack - trust_loss_rate * max(pressure - 1.0, 0.0) - 0.004 * access_gap / max(demand, 1.0) + randn() * 0.004, 0.0, 1.0)

        push!(rows, (
            scenario,
            time,
            demand,
            capacity,
            effective_capacity,
            pressure,
            slack,
            burnout,
            attrition,
            served,
            unmet_need,
            backlog,
            access_gap,
            trust,
            surge > 0.0 ? 1 : 0
        ))

        capacity = effective_capacity
        prevention_reduction = prevention_effect * (time + 1)
        demand = max(0.0, initial_demand + demand_growth * (time + 1) + surge - prevention_reduction + 0.08 * backlog + randn() * 0.25)
    end

    return rows
end

scenarios = [
    ("baseline_health_system", Dict(:seed_value => 42)),
    ("higher_demand_growth", Dict(:demand_growth => 0.65, :seed_value => 43)),
    ("stronger_prevention", Dict(:prevention_effect => 0.060, :trust => 0.70, :trust_gain_rate => 0.018, :seed_value => 44)),
    ("larger_surge", Dict(:surge_intensity => 32.0, :seed_value => 45)),
    ("higher_access_barrier", Dict(:access_barrier => 0.32, :trust => 0.54, :trust_loss_rate => 0.035, :seed_value => 47)),
    ("resilient_prepared_system", Dict(:capacity => 108.0, :demand => 88.0, :trust => 0.74, :demand_growth => 0.28, :prevention_effect => 0.055, :workforce_recovery => 0.060, :burnout_sensitivity => 0.060, :attrition_sensitivity => 0.020, :hiring_rate => 0.95, :access_barrier => 0.12, :trust_loss_rate => 0.014, :trust_gain_rate => 0.020, :surge_intensity => 14.0, :seed_value => 49))
]

all_rows = []

for (name, kwargs) in scenarios
    append!(all_rows, simulate_health_system(name; kwargs...))
end

trajectory_path = joinpath(tables_dir, "julia_health_system_trajectories.csv")
header = ["scenario" "time" "demand" "capacity" "effective_capacity" "pressure" "slack" "burnout" "attrition" "served" "unmet_need" "backlog" "access_gap" "trust" "surge_active"]
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
    [row[11] for row in all_rows],
    [row[12] for row in all_rows],
    [row[13] for row in all_rows],
    [row[14] for row in all_rows],
    [row[15] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    final = subset[end]
    maximum_pressure = maximum([row[6] for row in subset])
    maximum_burnout = maximum([row[8] for row in subset])
    total_unmet_need = sum([row[11] for row in subset])
    average_access_gap = mean([row[13] for row in subset])
    minimum_trust = minimum([row[14] for row in subset])
    label = maximum_pressure > 1.25 || total_unmet_need > 1000 || minimum_trust < 0.35 ? "high strain health system pathway" : "manageable health system pathway"

    push!(summary_rows, (
        scenario,
        final[5],
        final[12],
        final[14],
        maximum_pressure,
        maximum_burnout,
        total_unmet_need,
        average_access_gap,
        minimum_trust,
        label
    ))
end

summary_path = joinpath(tables_dir, "julia_health_system_summary.csv")
summary_header = ["scenario" "final_capacity" "final_backlog" "final_trust" "maximum_pressure" "maximum_burnout" "total_unmet_need" "average_access_gap" "minimum_trust" "diagnostic_label"]
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

println("Julia health systems ensemble complete.")
println(trajectory_path)
println(summary_path)
