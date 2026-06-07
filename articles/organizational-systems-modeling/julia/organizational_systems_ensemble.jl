# organizational_systems_ensemble.jl
# Julia organizational workload-capacity ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function bounded(value, low, high)
    return max(low, min(high, value))
end

function simulate_organization(
    scenario;
    n_steps = 100,
    capacity = 100.0,
    workload = 95.0,
    trust = 0.62,
    demand_growth = 0.45,
    hiring_rate = 0.65,
    learning_rate = 0.035,
    burnout_sensitivity = 0.090,
    recovery_rate = 0.040,
    attrition_sensitivity = 0.035,
    coordination_burden_rate = 0.10,
    trust_loss_rate = 0.030,
    trust_gain_rate = 0.010,
    seed_value = 42
)
    Random.seed!(seed_value)
    initial_workload = workload
    backlog = 0.0
    burnout = 0.10
    rows = []

    for time in 0:(n_steps - 1)
        pressure = workload / max(capacity, 1.0)
        slack = max(1.0 - pressure, 0.0)
        learning = learning_rate * capacity * slack * trust
        coordination_burden = coordination_burden_rate * max(pressure - 1.0, 0.0) * capacity
        burnout = max(0.0, burnout + burnout_sensitivity * max(pressure - 1.0, 0.0) - recovery_rate * slack)
        attrition = attrition_sensitivity * burnout * capacity
        effective_capacity = max(0.0, capacity + hiring_rate + learning - attrition - coordination_burden)
        delivery = min(workload, effective_capacity)
        backlog = max(0.0, backlog + workload - delivery)
        trust = bounded(trust + trust_gain_rate * slack - trust_loss_rate * max(pressure - 1.0, 0.0) - 0.005 * burnout + randn() * 0.005, 0.0, 1.0)

        push!(rows, (
            scenario,
            time,
            capacity,
            workload,
            pressure,
            slack,
            learning,
            coordination_burden,
            burnout,
            attrition,
            trust,
            delivery,
            backlog
        ))

        capacity = effective_capacity
        workload = initial_workload + demand_growth * (time + 1) + 0.10 * backlog
    end

    return rows
end

scenarios = [
    ("baseline_organization", Dict(:seed_value => 42)),
    ("high_demand_growth", Dict(:demand_growth => 0.85, :seed_value => 43)),
    ("faster_hiring", Dict(:hiring_rate => 1.25, :seed_value => 44)),
    ("learning_investment", Dict(:learning_rate => 0.070, :trust_gain_rate => 0.018, :seed_value => 45)),
    ("high_coordination_burden", Dict(:coordination_burden_rate => 0.22, :seed_value => 46)),
    ("resilient_learning_system", Dict(:capacity => 105.0, :workload => 92.0, :trust => 0.72, :demand_growth => 0.38, :hiring_rate => 0.85, :learning_rate => 0.075, :burnout_sensitivity => 0.060, :recovery_rate => 0.065, :attrition_sensitivity => 0.025, :coordination_burden_rate => 0.07, :seed_value => 49))
]

all_rows = []

for (name, kwargs) in scenarios
    append!(all_rows, simulate_organization(name; kwargs...))
end

trajectory_path = joinpath(tables_dir, "julia_organizational_system_trajectories.csv")
header = ["scenario" "time" "capacity" "workload" "pressure" "slack" "learning" "coordination_burden" "burnout" "attrition" "trust" "delivery" "backlog"]
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
    [row[13] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    final = subset[end]
    maximum_pressure = maximum([row[5] for row in subset])
    maximum_burnout = maximum([row[9] for row in subset])
    total_attrition = sum([row[10] for row in subset])
    average_delivery = mean([row[12] for row in subset])
    minimum_trust = minimum([row[11] for row in subset])
    label = maximum_pressure > 1.25 || maximum_burnout > 0.60 || minimum_trust < 0.30 ? "unsustainable operating pathway" : "manageable operating pathway"

    push!(summary_rows, (
        scenario,
        final[3],
        final[4],
        final[13],
        final[11],
        maximum_pressure,
        maximum_burnout,
        total_attrition,
        average_delivery,
        minimum_trust,
        label
    ))
end

summary_path = joinpath(tables_dir, "julia_organizational_system_summary.csv")
summary_header = ["scenario" "final_capacity" "final_workload" "final_backlog" "final_trust" "maximum_pressure" "maximum_burnout" "total_attrition" "average_delivery" "minimum_trust" "diagnostic_label"]
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
    [row[10] for row in summary_rows],
    [row[11] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia organizational systems ensemble complete.")
println(trajectory_path)
println(summary_path)
