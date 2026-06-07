# urban_systems_ensemble.jl
# Julia urban growth and infrastructure ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_urban_system(
    scenario;
    n_steps = 100,
    population = 100.0,
    housing = 112.0,
    transport = 90.0,
    service_capacity = 120.0,
    growth_pressure = 1.10,
    accessibility_attraction = 1.25,
    congestion_penalty = 0.70,
    housing_constraint_penalty = 0.45,
    housing_build_rate = 0.65,
    transport_investment_rate = 0.45,
    service_investment_rate = 0.35,
    periodic_policy_investment = 8.0,
    policy_interval = 20,
    pressure_penalty = 0.70,
    seed_value = 42
)
    Random.seed!(seed_value)
    rows = []

    for time in 1:n_steps
        accessibility = transport / (1.0 + 0.010 * population)
        congestion = population / max(transport, 1.0)
        housing_gap = max(population - housing, 0.0)
        housing_pressure = population / max(housing, 1.0)
        service_pressure = population / max(service_capacity, 1.0)
        policy_investment = time % policy_interval == 0 ? periodic_policy_investment : 0.0

        push!(rows, (
            scenario,
            time,
            population,
            housing,
            transport,
            service_capacity,
            accessibility,
            congestion,
            housing_gap,
            housing_pressure,
            service_pressure,
            policy_investment
        ))

        pressure_drag = pressure_penalty * max(service_pressure - 1.0, 0.0)
        congestion_drag = congestion_penalty * max(congestion - 1.0, 0.0)
        housing_drag = housing_constraint_penalty * housing_gap / 20.0

        population_change = growth_pressure +
            accessibility_attraction * accessibility / 55.0 -
            congestion_drag -
            housing_drag -
            pressure_drag +
            randn() * 0.10

        population = max(0.0, population + population_change)
        housing = max(0.0, housing + housing_build_rate + 0.020 * population - 0.004 * housing)
        transport = max(1.0, transport + transport_investment_rate + 0.010 * housing - 0.030 * max(congestion - 1.0, 0.0))
        service_capacity = max(1.0, service_capacity + service_investment_rate + policy_investment - 0.003 * service_capacity)
    end

    return rows
end

scenarios = [
    ("baseline_neighborhood", Dict(:seed_value => 42)),
    ("strong_growth_pressure", Dict(:growth_pressure => 1.65, :seed_value => 43)),
    ("housing_constraint", Dict(:housing => 106.0, :housing_build_rate => 0.25, :seed_value => 44)),
    ("transport_investment", Dict(:transport_investment_rate => 1.15, :service_investment_rate => 0.85, :periodic_policy_investment => 10.0, :seed_value => 45)),
    ("managed_growth", Dict(:housing => 118.0, :transport => 95.0, :service_capacity => 130.0, :growth_pressure => 1.00, :housing_build_rate => 1.05, :transport_investment_rate => 0.90, :service_investment_rate => 0.80, :periodic_policy_investment => 12.0, :policy_interval => 15, :seed_value => 49))
]

all_rows = []

for (name, kwargs) in scenarios
    append!(all_rows, simulate_urban_system(name; kwargs...))
end

trajectory_path = joinpath(tables_dir, "julia_urban_system_trajectories.csv")
header = ["scenario" "time" "population" "housing" "transport" "service_capacity" "accessibility" "congestion" "housing_gap" "housing_pressure" "service_pressure" "policy_investment"]
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
    [row[12] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    final = subset[end]
    maximum_service_pressure = maximum([row[11] for row in subset])
    maximum_housing_gap = maximum([row[9] for row in subset])
    average_accessibility = mean([row[7] for row in subset])
    label = maximum_service_pressure > 1.0 || maximum_housing_gap > 10.0 ? "capacity constrained pathway" : "managed growth pathway"

    push!(summary_rows, (
        scenario,
        final[3],
        final[4],
        final[5],
        final[6],
        final[7],
        maximum_service_pressure,
        maximum_housing_gap,
        average_accessibility,
        label
    ))
end

summary_path = joinpath(tables_dir, "julia_urban_system_summary.csv")
summary_header = ["scenario" "final_population" "final_housing" "final_transport" "final_service_capacity" "final_accessibility" "maximum_service_pressure" "maximum_housing_gap" "average_accessibility" "diagnostic_label"]
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

println("Julia urban systems ensemble complete.")
println(trajectory_path)
println(summary_path)
