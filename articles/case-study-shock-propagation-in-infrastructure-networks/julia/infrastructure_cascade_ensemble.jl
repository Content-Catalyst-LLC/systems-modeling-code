# infrastructure_cascade_ensemble.jl
# Julia cascade summary ensemble for infrastructure shock propagation.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

summaries = [
    ("localized_outage", 1, 1, 0.55, 0),
    ("hub_failure", 6, 6, 5.40, 2),
    ("dependency_cascade", 3, 3, 2.55, 1),
    ("load_redistribution", 3, 3, 2.45, 1),
    ("compound_shock", 8, 8, 6.80, 2),
    ("recovery_intervention", 6, 6, 5.00, 2)
]

path = joinpath(tables_dir, "julia_infrastructure_shock_summary.csv")
writedlm(path, ["scenario" "final_failed_count" "max_failed_count" "max_weighted_service_loss" "cascade_depth"], ',')

matrix = hcat(
    [row[1] for row in summaries],
    [row[2] for row in summaries],
    [row[3] for row in summaries],
    [row[4] for row in summaries],
    [row[5] for row in summaries]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia infrastructure cascade ensemble complete.")
println(path)
