# model_assumptions_boundary_judgment_workflow.R
# Base R workflow:
# assumption risk scoring and boundary scenario comparison.

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

assumptions <- read.csv(file.path(data_dir, "assumption_register.csv"), stringsAsFactors = FALSE)
boundary_scenarios <- read.csv(file.path(data_dir, "boundary_scenarios.csv"), stringsAsFactors = FALSE)
exclusion_log <- read.csv(file.path(data_dir, "exclusion_log.csv"), stringsAsFactors = FALSE)
boundary_critique <- read.csv(file.path(data_dir, "boundary_critique_questions.csv"), stringsAsFactors = FALSE)
evidence_strength <- read.csv(file.path(data_dir, "evidence_strength.csv"), stringsAsFactors = FALSE)

assumptions$risk_score <- assumptions$uncertainty * assumptions$sensitivity * assumptions$consequence

assumptions$risk_label <- ifelse(
  assumptions$risk_score >= 0.45,
  "high",
  ifelse(assumptions$risk_score >= 0.25, "moderate", "lower")
)

category_summary <- aggregate(
  risk_score ~ category,
  data = assumptions,
  FUN = mean
)

names(category_summary) <- c("category", "average_risk_score")

category_counts <- aggregate(
  assumption_id ~ category,
  data = assumptions,
  FUN = length
)

names(category_counts) <- c("category", "assumption_count")

high_risk_counts <- aggregate(
  high_risk_flag ~ category,
  data = transform(assumptions, high_risk_flag = ifelse(risk_label == "high", 1, 0)),
  FUN = sum
)

category_summary <- merge(category_summary, category_counts, by = "category")
category_summary <- merge(category_summary, high_risk_counts, by = "category")
names(category_summary)[names(category_summary) == "high_risk_flag"] <- "high_risk_count"

boundary_scenarios$composite_score <-
  0.20 * boundary_scenarios$capital_cost +
  0.30 * boundary_scenarios$service_reliability +
  0.25 * boundary_scenarios$equity_performance +
  0.25 * boundary_scenarios$long_term_resilience

boundary_scenarios <- boundary_scenarios[order(-boundary_scenarios$composite_score), ]

validation_checks <- data.frame(
  check = c(
    "assumption_register_created",
    "risk_scores_between_zero_and_one",
    "boundary_scenarios_created",
    "composite_scores_between_zero_and_one",
    "exclusion_log_created"
  ),
  passed = c(
    nrow(assumptions) > 0,
    all(assumptions$risk_score >= 0 & assumptions$risk_score <= 1),
    nrow(boundary_scenarios) > 0,
    all(boundary_scenarios$composite_score >= 0 & boundary_scenarios$composite_score <= 1),
    nrow(exclusion_log) > 0
  )
)

write.csv(
  assumptions,
  file.path(tables_dir, "r_assumption_register.csv"),
  row.names = FALSE
)

write.csv(
  category_summary,
  file.path(tables_dir, "r_assumption_category_summary.csv"),
  row.names = FALSE
)

write.csv(
  boundary_scenarios,
  file.path(tables_dir, "r_boundary_scenario_comparison.csv"),
  row.names = FALSE
)

write.csv(
  exclusion_log,
  file.path(tables_dir, "r_exclusion_log.csv"),
  row.names = FALSE
)

write.csv(
  boundary_critique,
  file.path(tables_dir, "r_boundary_critique_questions.csv"),
  row.names = FALSE
)

write.csv(
  evidence_strength,
  file.path(tables_dir, "r_evidence_strength.csv"),
  row.names = FALSE
)

write.csv(
  validation_checks,
  file.path(tables_dir, "r_assumption_boundary_validation_checks.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_assumption_risk_scores.png"), width = 1000, height = 700)
barplot(
  assumptions$risk_score,
  names.arg = assumptions$assumption_id,
  ylab = "Assumption Risk Score",
  xlab = "Assumption ID",
  main = "Assumption Risk: Uncertainty × Sensitivity × Consequence"
)
grid()
dev.off()

print(assumptions)
print(boundary_scenarios)
print(validation_checks)
cat("R assumption and boundary judgment workflow complete.\n")
