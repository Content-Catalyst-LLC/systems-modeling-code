# assumption_boundary_ensemble.jl
# Julia assumption risk and boundary scenario comparison workflow.

using DelimitedFiles
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

assumptions = [
    ("A1", "boundary", 0.80, 0.75, 0.90),
    ("A2", "data", 0.55, 0.60, 0.70),
    ("A3", "parameter", 0.40, 0.85, 0.65),
    ("A4", "behavioral", 0.70, 0.50, 0.60),
    ("A5", "scenario", 0.65, 0.80, 0.85),
    ("A6", "normative", 0.75, 0.90, 0.95),
    ("A7", "scale", 0.50, 0.65, 0.75),
    ("A8", "causal", 0.45, 0.80, 0.80),
    ("A9", "measurement", 0.70, 0.70, 0.85)
]

assumption_rows = []

for row in assumptions
    assumption_id, category, uncertainty, sensitivity, consequence = row
    risk_score = uncertainty * sensitivity * consequence
    label = risk_score >= 0.45 ? "high" : (risk_score >= 0.25 ? "moderate" : "lower")
    push!(assumption_rows, (assumption_id, category, uncertainty, sensitivity, consequence, risk_score, label))
end

assumption_path = joinpath(tables_dir, "julia_assumption_register.csv")
writedlm(assumption_path, ["assumption_id" "category" "uncertainty" "sensitivity" "consequence" "risk_score" "risk_label"], ',')

assumption_matrix = hcat(
    [row[1] for row in assumption_rows],
    [row[2] for row in assumption_rows],
    [row[3] for row in assumption_rows],
    [row[4] for row in assumption_rows],
    [row[5] for row in assumption_rows],
    [row[6] for row in assumption_rows],
    [row[7] for row in assumption_rows]
)

open(assumption_path, "a") do io
    writedlm(io, assumption_matrix, ',')
end

boundaries = [
    ("narrow_asset_boundary", 0.80, 0.60, 0.35, 0.50),
    ("expanded_service_boundary", 0.72, 0.75, 0.55, 0.65),
    ("community_resilience_boundary", 0.65, 0.78, 0.85, 0.78),
    ("long_horizon_boundary", 0.60, 0.82, 0.70, 0.90),
    ("multi_stakeholder_boundary", 0.62, 0.76, 0.88, 0.82)
]

boundary_rows = []

for row in boundaries
    boundary, capital_cost, reliability, equity, resilience = row
    composite = 0.20 * capital_cost + 0.30 * reliability + 0.25 * equity + 0.25 * resilience
    push!(boundary_rows, (boundary, capital_cost, reliability, equity, resilience, composite))
end

boundary_path = joinpath(tables_dir, "julia_boundary_scenario_comparison.csv")
writedlm(boundary_path, ["boundary" "capital_cost" "service_reliability" "equity_performance" "long_term_resilience" "composite_score"], ',')

boundary_matrix = hcat(
    [row[1] for row in boundary_rows],
    [row[2] for row in boundary_rows],
    [row[3] for row in boundary_rows],
    [row[4] for row in boundary_rows],
    [row[5] for row in boundary_rows],
    [row[6] for row in boundary_rows]
)

open(boundary_path, "a") do io
    writedlm(io, boundary_matrix, ',')
end

println("Julia assumption and boundary ensemble complete.")
println(boundary_path)
