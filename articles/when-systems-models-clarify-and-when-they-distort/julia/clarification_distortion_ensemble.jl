# clarification_distortion_ensemble.jl
# Julia clarification and distortion diagnostic workflow.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

cases = [
    ("infrastructure_resilience_model", 0.85, 0.70, 0.80, 0.65, 0.45, 0.65, 0.45, 0.50),
    ("public_health_capacity_model", 0.75, 0.85, 0.70, 0.60, 0.55, 0.70, 0.55, 0.65),
    ("urban_accessibility_model", 0.70, 0.50, 0.60, 0.70, 0.60, 0.75, 0.70, 0.55),
    ("energy_transition_pathway_model", 0.80, 0.80, 0.85, 0.55, 0.50, 0.65, 0.50, 0.60),
    ("machine_learning_risk_model", 0.45, 0.40, 0.35, 0.35, 0.85, 0.70, 0.85, 0.90),
    ("digital_twin_operations_model", 0.75, 0.65, 0.70, 0.50, 0.70, 0.60, 0.50, 0.75)
]

rows = []

for c in cases
    name, structural, dynamic, scenario, assumptions, false_precision, boundary, proxy, misuse = c

    clarification = 0.30 * structural + 0.25 * dynamic + 0.25 * scenario + 0.20 * assumptions
    distortion = 0.25 * false_precision + 0.30 * boundary + 0.20 * proxy + 0.25 * misuse
    net = clarification - distortion

    label = if net >= 0.20
        "strong_clarification_with_managed_risk"
    elseif net >= 0
        "useful_with_strong_caveats"
    else
        "high_distortion_risk_without_revision"
    end

    push!(rows, (name, clarification, distortion, net, label))
end

path = joinpath(tables_dir, "julia_clarification_distortion_model_cases.csv")
writedlm(path, ["model_case" "clarification_score" "distortion_risk_score" "net_interpretive_value" "use_label"], ',')

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

println("Julia clarification-distortion ensemble complete.")
println(path)
