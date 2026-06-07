# participatory_scenario_ensemble.jl
# Julia stakeholder scenario scoring and disagreement diagnostics.

using DelimitedFiles
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

stakeholders = [
    ("community_residents", 0.30, 0.10, 0.20, 0.30, 0.10),
    ("frontline_staff", 0.20, 0.15, 0.25, 0.20, 0.20),
    ("technical_experts", 0.15, 0.20, 0.30, 0.15, 0.20),
    ("public_agency", 0.20, 0.25, 0.25, 0.15, 0.15),
    ("service_users", 0.35, 0.10, 0.15, 0.30, 0.10),
    ("resource_managers", 0.15, 0.20, 0.30, 0.15, 0.20)
]

scenarios = [
    ("targeted_service_expansion", 0.85, 0.55, 0.65, 0.90, 0.60),
    ("infrastructure_repair_priority", 0.55, 0.65, 0.85, 0.50, 0.75),
    ("digital_monitoring_platform", 0.60, 0.50, 0.70, 0.45, 0.70),
    ("community_led_resilience", 0.75, 0.70, 0.80, 0.85, 0.55),
    ("baseline_policy_continuation", 0.40, 0.90, 0.35, 0.30, 0.85)
]

score_rows = []

for stakeholder in stakeholders
    stakeholder_group, w_access, w_cost, w_resilience, w_equity, w_feasibility = stakeholder

    for scenario in scenarios
        scenario_name, access, cost, resilience, equity, feasibility = scenario

        score = w_access * access +
                w_cost * cost +
                w_resilience * resilience +
                w_equity * equity +
                w_feasibility * feasibility

        push!(score_rows, (stakeholder_group, scenario_name, score))
    end
end

score_path = joinpath(tables_dir, "julia_participatory_stakeholder_scenario_scores.csv")
writedlm(score_path, ["stakeholder_group" "scenario" "score"], ',')

score_matrix = hcat(
    [row[1] for row in score_rows],
    [row[2] for row in score_rows],
    [row[3] for row in score_rows]
)

open(score_path, "a") do io
    writedlm(io, score_matrix, ',')
end

summary_rows = []

for scenario in scenarios
    scenario_name = scenario[1]
    scores = [row[3] for row in score_rows if row[2] == scenario_name]
    mean_score = mean(scores)
    disagreement_sd = std(scores; corrected=false)
    minimum_score = minimum(scores)
    maximum_score = maximum(scores)
    legitimacy_adjusted_score = mean_score - 0.50 * disagreement_sd

    consensus_label = if disagreement_sd >= 0.08
        "high disagreement"
    elseif disagreement_sd >= 0.04
        "moderate disagreement"
    else
        "low disagreement"
    end

    push!(summary_rows, (
        scenario_name,
        mean_score,
        disagreement_sd,
        minimum_score,
        maximum_score,
        maximum_score - minimum_score,
        legitimacy_adjusted_score,
        consensus_label
    ))
end

summary_path = joinpath(tables_dir, "julia_participatory_scenario_summary.csv")
writedlm(summary_path, ["scenario" "mean_score" "disagreement_sd" "minimum_score" "maximum_score" "score_range" "legitimacy_adjusted_score" "consensus_label"], ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows],
    [row[8] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia participatory scenario ensemble complete.")
println(summary_path)
