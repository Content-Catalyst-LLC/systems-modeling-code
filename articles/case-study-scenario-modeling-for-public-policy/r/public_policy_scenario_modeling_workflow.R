# public_policy_scenario_modeling_workflow.R
# Base R workflow: public policy options, future scenarios, composite scores, robustness, regret, validation.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) > 0) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE)
  article_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  article_root <- normalizePath(getwd(), mustWork = TRUE)
}

data_dir <- file.path(article_root, "data")
tables_dir <- file.path(article_root, "outputs", "tables")
figures_dir <- file.path(article_root, "outputs", "figures")

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

policies <- read.csv(file.path(data_dir, "policy_options.csv"), stringsAsFactors = FALSE)
scenarios <- read.csv(file.path(data_dir, "future_scenarios.csv"), stringsAsFactors = FALSE)
weights <- read.csv(file.path(data_dir, "metric_weights.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(data_dir, "model_assumptions.csv"), stringsAsFactors = FALSE)
diagnostics <- read.csv(file.path(data_dir, "diagnostic_definitions.csv"), stringsAsFactors = FALSE)

get_weight <- function(metric) {
  weights$weight[weights$metric == metric][1]
}

clamp <- function(value) {
  max(0, min(1, value))
}

score_policy_scenario <- function(policy_row, scenario_row) {
  benefit <- clamp(policy_row$base_benefit * scenario_row$benefit_multiplier)
  cost <- clamp(policy_row$base_cost * scenario_row$cost_multiplier)
  equity <- clamp(policy_row$base_equity * scenario_row$equity_multiplier)
  resilience <- clamp(policy_row$base_resilience * scenario_row$resilience_multiplier)
  feasibility <- clamp(policy_row$base_feasibility * scenario_row$feasibility_multiplier)
  legitimacy <- clamp(policy_row$base_legitimacy * scenario_row$legitimacy_multiplier)

  composite_score <-
    get_weight("benefit") * benefit -
    get_weight("cost") * cost +
    get_weight("equity") * equity +
    get_weight("resilience") * resilience +
    get_weight("feasibility") * feasibility +
    get_weight("legitimacy") * legitimacy

  data.frame(
    policy = policy_row$policy,
    scenario = scenario_row$scenario,
    benefit = benefit,
    cost = cost,
    equity = equity,
    resilience = resilience,
    feasibility = feasibility,
    legitimacy = legitimacy,
    composite_score = composite_score,
    acceptable = composite_score >= 0.50,
    stringsAsFactors = FALSE
  )
}

scenario_results <- data.frame()

for (i in seq_len(nrow(policies))) {
  for (j in seq_len(nrow(scenarios))) {
    scenario_results <- rbind(
      scenario_results,
      score_policy_scenario(policies[i, ], scenarios[j, ])
    )
  }
}

scenario_results$best_score_in_scenario <- ave(
  scenario_results$composite_score,
  scenario_results$scenario,
  FUN = max
)

scenario_results$regret <- scenario_results$best_score_in_scenario - scenario_results$composite_score

policy_names <- unique(scenario_results$policy)
summary_rows <- data.frame()

for (policy_name in policy_names) {
  subset_rows <- scenario_results[scenario_results$policy == policy_name, ]

  average_score <- mean(subset_rows$composite_score)
  worst_case_score <- min(subset_rows$composite_score)
  best_case_score <- max(subset_rows$composite_score)
  maximum_regret <- max(subset_rows$regret)
  acceptable_scenario_share <- mean(subset_rows$acceptable)
  scenario_failure_count <- sum(!subset_rows$acceptable)
  robustness_score <- 0.55 * average_score + 0.45 * worst_case_score - 0.25 * maximum_regret

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      policy = policy_name,
      average_score = average_score,
      worst_case_score = worst_case_score,
      best_case_score = best_case_score,
      maximum_regret = maximum_regret,
      acceptable_scenario_share = acceptable_scenario_share,
      scenario_failure_count = scenario_failure_count,
      robustness_score = robustness_score,
      stringsAsFactors = FALSE
    )
  )
}

summary_rows <- summary_rows[order(-summary_rows$robustness_score), ]

validation_checks <- data.frame(
  check = c(
    "policies_created",
    "scenarios_created",
    "scenario_results_created",
    "scores_are_finite",
    "regret_nonnegative",
    "summary_created",
    "weights_sum_reasonable"
  ),
  passed = c(
    nrow(policies) > 0,
    nrow(scenarios) > 0,
    nrow(scenario_results) == nrow(policies) * nrow(scenarios),
    all(is.finite(scenario_results$composite_score)),
    all(scenario_results$regret >= 0),
    nrow(summary_rows) == nrow(policies),
    abs(sum(weights$weight) - 1) < 0.000001
  )
)

write.csv(policies, file.path(tables_dir, "r_policy_options.csv"), row.names = FALSE)
write.csv(scenarios, file.path(tables_dir, "r_future_scenarios.csv"), row.names = FALSE)
write.csv(weights, file.path(tables_dir, "r_metric_weights.csv"), row.names = FALSE)
write.csv(scenario_results, file.path(tables_dir, "r_policy_scenario_results.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_policy_robustness_summary.csv"), row.names = FALSE)
write.csv(assumptions, file.path(tables_dir, "r_model_assumptions.csv"), row.names = FALSE)
write.csv(diagnostics, file.path(tables_dir, "r_diagnostic_definitions.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_policy_scenario_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_policy_robustness_scores.png"), width = 1000, height = 700)
barplot(
  summary_rows$robustness_score,
  names.arg = summary_rows$policy,
  las = 2,
  ylab = "Robustness Score",
  main = "Scenario Modeling for Public Policy: Robustness Comparison"
)
grid()
dev.off()

print(summary_rows)
print(validation_checks)
cat("R public policy scenario modeling workflow complete.\n")
