# climate_resilience_ensemble.jl
# Julia summary ensemble for resilience modeling under climate stress.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

summaries = [
    ("targeted_resilience_investment", 0.720000, 0.590000, 0, 0, 0.870000, 0.060000, 0, 0.699000),
    ("moderate_climate_stress", 0.690000, 0.560000, 0, 0, 0.720000, 0.080000, 0, 0.662000),
    ("transformation_pathway", 0.610000, 0.520000, 5, 2, 0.760000, 0.170000, 1, 0.476000),
    ("repeated_shocks", 0.590000, 0.480000, 9, 3, 0.610000, 0.160000, 0, 0.399000),
    ("delayed_adaptation", 0.550000, 0.430000, 14, 4, 0.600000, 0.210000, 0, 0.266500),
    ("compound_climate_stress", 0.490000, 0.360000, 24, 5, 0.500000, 0.300000, 0, 0.025000)
]

path = joinpath(tables_dir, "julia_climate_resilience_summary.csv")
writedlm(path, ["scenario" "average_service" "minimum_service" "time_below_threshold" "threshold_crossings" "final_adaptive_capacity" "final_degradation" "transformed" "resilience_score"], ',')

matrix = hcat(
    [row[1] for row in summaries],
    [row[2] for row in summaries],
    [row[3] for row in summaries],
    [row[4] for row in summaries],
    [row[5] for row in summaries],
    [row[6] for row in summaries],
    [row[7] for row in summaries],
    [row[8] for row in summaries],
    [row[9] for row in summaries]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia climate resilience ensemble complete.")
println(path)
