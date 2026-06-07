# participatory_modeling_workflow.R
# Base R workflow:
# stakeholder scenario scoring and consensus diagnostics.

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

stakeholders <- read.csv(file.path(data_dir, "stakeholder_weights.csv"), stringsAsFactors = FALSE)
scenarios <- read.csv(file.path(data_dir, "scenarios.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(data_dir, "assumption_register.csv"), stringsAsFactors = FALSE)

outcomes <- c("access", "cost", "resilience", "equity", "feasibility")

score_rows <- data.frame()

for (i in seq_len(nrow(stakeholders))) {
  for (j in seq_len(nrow(scenarios))) {
    score <- sum(as.numeric(stakeholders[i, outcomes]) * as.numeric(scenarios[j, outcomes]))

    score_rows <- rbind(
      score_rows,
      data.frame(
        stakeholder_group = stakeholders$stakeholder_group[i],
        scenario = scenarios$scenario[j],
        score = score
      )
    )
  }
}

scenario_summary <- aggregate(
  score ~ scenario,
  data = score_rows,
  FUN = function(x) c(mean = mean(x), sd = sd(x), min = min(x), max = max(x))
)

scenario_summary <- do.call(data.frame, scenario_summary)
names(scenario_summary) <- c(
  "scenario",
  "mean_score",
  "disagreement_sd",
  "minimum_score",
  "maximum_score"
)

scenario_summary$score_range <- scenario_summary$maximum_score - scenario_summary$minimum_score

lambda <- 0.50
scenario_summary$legitimacy_adjusted_score <-
  scenario_summary$mean_score - lambda * scenario_summary$disagreement_sd

scenario_summary$consensus_label <- ifelse(
  scenario_summary$disagreement_sd >= 0.08,
  "high disagreement",
  ifelse(scenario_summary$disagreement_sd >= 0.04, "moderate disagreement", "low disagreement")
)

scenario_summary <- scenario_summary[order(-scenario_summary$legitimacy_adjusted_score), ]

assumption_summary <- aggregate(
  assumption_id ~ status,
  data = assumptions,
  FUN = length
)

names(assumption_summary) <- c("status", "assumption_count")

validation_checks <- data.frame(
  check = c(
    "stakeholder_weights_sum_to_one",
    "scenario_scores_between_zero_and_one",
    "scenario_summary_created",
    "assumption_register_created"
  ),
  passed = c(
    all(abs(rowSums(stakeholders[, outcomes]) - 1) < 1e-9),
    all(score_rows$score >= 0 & score_rows$score <= 1),
    nrow(scenario_summary) > 0,
    nrow(assumptions) > 0
  )
)

write.csv(
  stakeholders,
  file.path(tables_dir, "r_participatory_stakeholder_weights.csv"),
  row.names = FALSE
)

write.csv(
  scenarios,
  file.path(tables_dir, "r_participatory_scenarios.csv"),
  row.names = FALSE
)

write.csv(
  score_rows,
  file.path(tables_dir, "r_participatory_stakeholder_scenario_scores.csv"),
  row.names = FALSE
)

write.csv(
  scenario_summary,
  file.path(tables_dir, "r_participatory_scenario_summary.csv"),
  row.names = FALSE
)

write.csv(
  assumptions,
  file.path(tables_dir, "r_participatory_assumption_register.csv"),
  row.names = FALSE
)

write.csv(
  assumption_summary,
  file.path(tables_dir, "r_participatory_assumption_status_summary.csv"),
  row.names = FALSE
)

write.csv(
  validation_checks,
  file.path(tables_dir, "r_participatory_validation_checks.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_participatory_scenario_scores.png"), width = 1000, height = 700)
barplot(
  scenario_summary$legitimacy_adjusted_score,
  names.arg = scenario_summary$scenario,
  las = 2,
  ylab = "Legitimacy-Adjusted Score",
  main = "Participatory Scenario Comparison"
)
grid()
dev.off()

print(scenario_summary)
print(validation_checks)
cat("R participatory modeling workflow complete.\n")
