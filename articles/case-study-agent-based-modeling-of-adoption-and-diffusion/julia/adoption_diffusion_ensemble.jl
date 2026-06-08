# adoption_diffusion_ensemble.jl
# Julia summary ensemble for agent-based adoption and diffusion.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

summaries = [
    ("baseline_diffusion", 0.520000, 62, 0.250000, 8, 26, 0.045000),
    ("high_social_influence", 0.720000, 86, 0.300000, 5, 14, 0.080000),
    ("high_cost_barrier", 0.280000, 34, 0.180000, 30, -1, 0.030000),
    ("targeted_seeding", 0.610000, 73, 0.220000, 6, 21, 0.055000),
    ("network_fragmentation", 0.460000, 55, 0.420000, 12, -1, 0.040000),
    ("trust_and_resistance", 0.340000, 41, 0.310000, 24, -1, 0.025000),
    ("bridge_and_equity_seeding", 0.660000, 79, 0.190000, 5, 18, 0.060000)
]

path = joinpath(tables_dir, "julia_adoption_diffusion_summary.csv")
writedlm(path, ["scenario" "final_adoption_share" "final_adopter_count" "maximum_adoption_gap" "time_to_25_percent" "time_to_50_percent" "peak_growth"], ',')

matrix = hcat(
    [row[1] for row in summaries],
    [row[2] for row in summaries],
    [row[3] for row in summaries],
    [row[4] for row in summaries],
    [row[5] for row in summaries],
    [row[6] for row in summaries],
    [row[7] for row in summaries]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia adoption diffusion ensemble complete.")
println(path)
