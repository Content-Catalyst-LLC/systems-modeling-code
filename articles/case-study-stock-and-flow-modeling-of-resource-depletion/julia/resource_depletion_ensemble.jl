# resource_depletion_ensemble.jl
# Julia scenario ensemble for stock-and-flow resource depletion.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

scenarios = [
    ("baseline", 0.080, 0.015, 0.120, 0.45, 0.35),
    ("high_demand", 0.080, 0.035, 0.120, 0.45, 0.35),
    ("conservation", 0.080, 0.015, 0.120, 0.85, 0.55),
    ("technology_rebound", 0.080, 0.030, 0.180, 0.35, 0.30),
    ("regeneration_stress", 0.045, 0.015, 0.120, 0.45, 0.35),
    ("delayed_governance", 0.080, 0.025, 0.120, 0.20, 0.20)
]

rows = []

for s in scenarios
    name, regeneration_rate, demand_growth, extraction_efficiency, conservation_sensitivity, max_conservation = s
    stock = 80.0
    minimum_stock = stock
    cumulative_extraction = 0.0
    cumulative_regeneration = 0.0
    overshoot_periods = 0

    for t in 0:79
        demand = 4.0 * (1.0 + demand_growth)^t
        scarcity = max(0.0, 1.0 - stock / 70.0)
        conservation = min(max_conservation, conservation_sensitivity * scarcity)
        effective_demand = demand * (1.0 - conservation)
        regeneration = max(0.0, regeneration_rate * stock * (1.0 - stock / 100.0))
        extraction = min(effective_demand, min(extraction_efficiency * stock, stock + regeneration))

        if extraction > regeneration
            overshoot_periods += 1
        end

        cumulative_extraction += extraction
        cumulative_regeneration += regeneration
        stock = max(0.0, stock + regeneration - extraction)
        minimum_stock = min(minimum_stock, stock)
    end

    push!(rows, (name, stock, minimum_stock, cumulative_extraction, cumulative_regeneration, overshoot_periods))
end

path = joinpath(tables_dir, "julia_resource_depletion_summary.csv")
writedlm(path, ["scenario" "final_stock" "minimum_stock" "cumulative_extraction" "cumulative_regeneration" "overshoot_periods"], ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows],
    [row[6] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia resource depletion ensemble complete.")
println(path)
