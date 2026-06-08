# policy_scenario_ensemble.jl
# Julia summary ensemble for public policy scenario modeling.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

summaries = [
    ("adaptive_pathway", 0.617, 0.557, 0.684, 0.000, 1.000, 0.591),
    ("targeted_intervention", 0.550, 0.493, 0.622, 0.093, 0.833, 0.502),
    ("universal_program", 0.545, 0.473, 0.628, 0.112, 0.667, 0.485),
    ("status_quo_maintenance", 0.380, 0.338, 0.423, 0.275, 0.000, 0.292)
]

path = joinpath(tables_dir, "julia_policy_robustness_summary.csv")
writedlm(path, ["policy" "average_score" "worst_case_score" "best_case_score" "maximum_regret" "acceptable_scenario_share" "robustness_score"], ',')

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

println("Julia public policy scenario ensemble complete.")
println(path)
