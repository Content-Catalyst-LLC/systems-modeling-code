# ethics_power_systems_modeling_workflow.R
# Base R workflow: distributional burden and model governance diagnostics.

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

stakeholders <- read.csv(file.path(data_dir, "stakeholders.csv"), stringsAsFactors = FALSE)
governance_register <- read.csv(file.path(data_dir, "governance_register.csv"), stringsAsFactors = FALSE)
model_use_risks <- read.csv(file.path(data_dir, "model_use_risks.csv"), stringsAsFactors = FALSE)
boundary_power_questions <- read.csv(file.path(data_dir, "boundary_power_questions.csv"), stringsAsFactors = FALSE)
model_safeguards <- read.csv(file.path(data_dir, "model_safeguards.csv"), stringsAsFactors = FALSE)
misuse_patterns <- read.csv(file.path(data_dir, "misuse_patterns.csv"), stringsAsFactors = FALSE)

stakeholders$net_benefit <- stakeholders$expected_benefit - stakeholders$expected_burden
stakeholders$burden_gap <- stakeholders$expected_burden - stakeholders$expected_benefit
stakeholders$power_burden_gap <- stakeholders$affected * stakeholders$expected_burden * (1 - stakeholders$influence)

stakeholders$risk_label <- ifelse(
  stakeholders$power_burden_gap >= 0.45,
  "high_power_burden_gap",
  ifelse(stakeholders$power_burden_gap >= 0.20, "moderate_power_burden_gap", "lower_power_burden_gap")
)

model_use_risks$ethical_risk_score <-
  model_use_risks$uncertainty *
  model_use_risks$consequence *
  (1 + 0.50 * model_use_risks$representation_gap) *
  (1 + 0.50 * model_use_risks$misuse_potential)

model_use_risks <- model_use_risks[order(-model_use_risks$ethical_risk_score), ]

coverage_summary <- data.frame(
  metric = c("stakeholder_groups", "affected_groups", "represented_groups", "missing_or_unrepresented_groups", "high_power_burden_gap_groups"),
  value = c(
    nrow(stakeholders),
    sum(stakeholders$affected >= 0.50),
    sum(stakeholders$represented == 1),
    sum(stakeholders$represented == 0),
    sum(stakeholders$risk_label == "high_power_burden_gap")
  )
)

governance_summary <- aggregate(item_id ~ status, data = governance_register, FUN = length)
names(governance_summary) <- c("status", "governance_item_count")

validation_checks <- data.frame(
  check = c("stakeholder_table_created", "power_burden_gaps_nonnegative", "governance_register_created", "model_use_risks_created", "ethical_risk_scores_nonnegative", "safeguards_created"),
  passed = c(
    nrow(stakeholders) > 0,
    all(stakeholders$power_burden_gap >= 0),
    nrow(governance_register) > 0,
    nrow(model_use_risks) > 0,
    all(model_use_risks$ethical_risk_score >= 0),
    nrow(model_safeguards) > 0
  )
)

write.csv(stakeholders, file.path(tables_dir, "r_ethics_stakeholder_distributional_diagnostics.csv"), row.names = FALSE)
write.csv(coverage_summary, file.path(tables_dir, "r_ethics_stakeholder_coverage_summary.csv"), row.names = FALSE)
write.csv(governance_register, file.path(tables_dir, "r_ethics_governance_register.csv"), row.names = FALSE)
write.csv(governance_summary, file.path(tables_dir, "r_ethics_governance_status_summary.csv"), row.names = FALSE)
write.csv(model_use_risks, file.path(tables_dir, "r_ethics_model_use_risk_register.csv"), row.names = FALSE)
write.csv(boundary_power_questions, file.path(tables_dir, "r_boundary_power_questions.csv"), row.names = FALSE)
write.csv(model_safeguards, file.path(tables_dir, "r_model_safeguards.csv"), row.names = FALSE)
write.csv(misuse_patterns, file.path(tables_dir, "r_misuse_patterns.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_ethics_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_power_burden_gap.png"), width = 1000, height = 700)
barplot(
  stakeholders$power_burden_gap,
  names.arg = stakeholders$group,
  las = 2,
  ylab = "Power-Burden Gap",
  main = "Ethical Review: Burden Concentrated Where Influence Is Low"
)
grid()
dev.off()

print(stakeholders)
print(governance_register)
print(validation_checks)
cat("R ethics, power, and systems modeling workflow complete.\n")
