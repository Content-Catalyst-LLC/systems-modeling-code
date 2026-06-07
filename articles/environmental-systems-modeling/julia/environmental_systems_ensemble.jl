# environmental_systems_ensemble.jl
# Julia environmental stock and exposure ensemble workflow.

using DelimitedFiles
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_stock(
    scenario;
    n_steps = 120,
    initial_stock = 70.0,
    carrying_capacity = 100.0,
    growth_rate = 0.065,
    extraction_rate = 0.040,
    restoration_rate = 0.010,
    disturbance_step = 65,
    disturbance_size = 12.0
)
    stock = initial_stock
    rows = []

    for time in 1:n_steps
        regeneration = growth_rate * stock * (1.0 - stock / carrying_capacity)
        extraction = extraction_rate * stock
        restoration = restoration_rate * (carrying_capacity - stock)
        disturbance = time == disturbance_step ? disturbance_size : 0.0

        next_stock = max(0.0, min(carrying_capacity, stock + regeneration - extraction + restoration - disturbance))
        resilience_index = next_stock / carrying_capacity

        push!(rows, (
            scenario,
            time,
            next_stock,
            regeneration,
            extraction,
            restoration,
            disturbance,
            resilience_index
        ))

        stock = next_stock
    end

    return rows
end

function simulate_pollution(
    scenario;
    n_steps = 120,
    initial_concentration = 12.0,
    baseline_load = 4.2,
    decay_rate = 0.035,
    flow_rate = 2.5,
    exposure_weight = 1.0,
    intervention_step = 70,
    load_reduction_fraction = 0.0
)
    concentration = initial_concentration
    cumulative_exposure = 0.0
    volume = 100.0
    rows = []

    for time in 1:n_steps
        active_load = time >= intervention_step ? baseline_load * (1.0 - load_reduction_fraction) : baseline_load
        load_increment = active_load / volume
        decay_loss = decay_rate * concentration
        flow_loss = (flow_rate / volume) * concentration

        concentration = max(0.0, concentration + load_increment - decay_loss - flow_loss)
        exposure = concentration * exposure_weight
        cumulative_exposure += exposure

        push!(rows, (
            scenario,
            time,
            active_load,
            concentration,
            decay_loss,
            flow_loss,
            exposure_weight,
            exposure,
            cumulative_exposure,
            time >= intervention_step ? 1 : 0
        ))
    end

    return rows
end

scenarios = [
    ("baseline_pressure", Dict()),
    ("high_extraction", Dict(:extraction_rate => 0.065)),
    ("restoration_investment", Dict(:restoration_rate => 0.035)),
    ("larger_disturbance", Dict(:disturbance_size => 24.0)),
    ("lower_growth", Dict(:growth_rate => 0.040))
]

stock_rows = []
pollution_rows = []

for (name, kwargs) in scenarios
    append!(stock_rows, simulate_stock(name; kwargs...))
    load_reduction = name == "baseline_pressure" ? 0.0 : 0.25
    append!(pollution_rows, simulate_pollution(name; load_reduction_fraction = load_reduction))
end

stock_path = joinpath(tables_dir, "julia_environmental_stock_trajectories.csv")
stock_header = ["scenario" "time" "stock" "regeneration" "extraction" "restoration" "disturbance" "resilience_index"]
writedlm(stock_path, stock_header, ',')

stock_matrix = hcat(
    [row[1] for row in stock_rows],
    [row[2] for row in stock_rows],
    [row[3] for row in stock_rows],
    [row[4] for row in stock_rows],
    [row[5] for row in stock_rows],
    [row[6] for row in stock_rows],
    [row[7] for row in stock_rows],
    [row[8] for row in stock_rows]
)

open(stock_path, "a") do io
    writedlm(io, stock_matrix, ',')
end

pollution_path = joinpath(tables_dir, "julia_pollution_exposure_trajectories.csv")
pollution_header = ["scenario" "time" "active_load" "concentration" "decay_loss" "flow_loss" "exposure_weight" "exposure" "cumulative_exposure" "intervention_active"]
writedlm(pollution_path, pollution_header, ',')

pollution_matrix = hcat(
    [row[1] for row in pollution_rows],
    [row[2] for row in pollution_rows],
    [row[3] for row in pollution_rows],
    [row[4] for row in pollution_rows],
    [row[5] for row in pollution_rows],
    [row[6] for row in pollution_rows],
    [row[7] for row in pollution_rows],
    [row[8] for row in pollution_rows],
    [row[9] for row in pollution_rows],
    [row[10] for row in pollution_rows]
)

open(pollution_path, "a") do io
    writedlm(io, pollution_matrix, ',')
end

println("Julia environmental systems ensemble complete.")
println(stock_path)
println(pollution_path)
