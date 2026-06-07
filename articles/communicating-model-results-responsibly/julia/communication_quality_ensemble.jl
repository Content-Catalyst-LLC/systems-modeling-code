# communication_quality_ensemble.jl
# Julia model communication diagnostics.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

results = [
    ("R1", "scenario", 0.55, 0.88, 0.80, 0.85, 0.70, 0.75),
    ("R2", "forecast", 9000.0, 16000.0, 0.60, 0.75, 0.55, 0.60),
    ("R3", "ranking", 0.75, 0.89, 0.70, 0.55, 0.65, 0.45),
    ("R4", "map", 0.40, 0.82, 0.45, 0.40, 0.50, 0.40),
    ("R5", "optimization", 0.80, 0.96, 0.65, 0.60, 0.60, 0.55),
    ("R6", "dashboard", 0.62, 0.86, 0.55, 0.50, 0.55, 0.35)
]

rows = []

for r in results
    result_id, result_type, lower_bound, upper_bound, assumption, uncertainty, boundary, misuse = r
    width = upper_bound - lower_bound
    quality = 0.30 * assumption + 0.30 * uncertainty + 0.20 * boundary + 0.20 * misuse

    risk = if uncertainty < 0.60 && width > 0.20
        "high_false_precision_risk"
    elseif uncertainty < 0.70
        "moderate_false_precision_risk"
    else
        "lower_false_precision_risk"
    end

    push!(rows, (result_id, result_type, width, quality, risk))
end

path = joinpath(tables_dir, "julia_model_result_communication_diagnostics.csv")
writedlm(path, ["result_id" "result_type" "uncertainty_width" "communication_quality_score" "false_precision_risk"], ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia communication quality ensemble complete.")
println(path)
