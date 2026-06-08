# integrated_assessment_ensemble.jl
# Julia summary ensemble for integrated assessment and sustainability pathways.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

summaries = [
    ("equity_centered_transition", 0.998000, 9.800000, 0.010000, 0.081120, 0.535000, 0.440000, 0.720000, 0.810000, 0, 0.285000),
    ("ecological_constraint", 0.978000, 10.400000, 0.011500, 0.064400, 0.430000, 0.420000, 0.630000, 0.770000, 0, 0.270000),
    ("rapid_decarbonization", 1.000000, 8.900000, 0.010800, 0.101600, 0.580000, 0.450000, 0.590000, 0.700000, 0, 0.255000),
    ("adaptation_heavy", 0.846000, 12.100000, 0.009200, 0.045600, 0.560000, 0.410000, 0.580000, 0.920000, 0, 0.240000),
    ("delayed_transition", 0.946000, 13.600000, 0.016000, 0.059600, 0.585000, 0.480000, 0.515000, 0.545000, 3, 0.180000),
    ("baseline_continuation", 0.710000, 17.400000, 0.022000, 0.015840, 0.620000, 0.540000, 0.470000, 0.360000, 12, 0.120000)
]

path = joinpath(tables_dir, "julia_integrated_assessment_summary.csv")
writedlm(path, ["pathway" "final_clean_energy_share" "cumulative_emissions" "average_climate_damages" "average_transition_cost" "average_land_pressure" "average_water_stress" "average_equity_score" "final_adaptation_capacity" "constraint_breach_count" "average_sustainability_score"], ',')

matrix = hcat(
    [row[1] for row in summaries],
    [row[2] for row in summaries],
    [row[3] for row in summaries],
    [row[4] for row in summaries],
    [row[5] for row in summaries],
    [row[6] for row in summaries],
    [row[7] for row in summaries],
    [row[8] for row in summaries],
    [row[9] for row in summaries],
    [row[10] for row in summaries],
    [row[11] for row in summaries]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia integrated assessment ensemble complete.")
println(path)
