# communicating_model_results_responsibly_workflow.R
# Base R workflow: model communication risk and uncertainty disclosure.

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

model_results <- read.csv(file.path(data_dir, "model_results.csv"), stringsAsFactors = FALSE)
communication_controls <- read.csv(file.path(data_dir, "communication_controls.csv"), stringsAsFactors = FALSE)
valid_use_register <- read.csv(file.path(data_dir, "valid_use_register.csv"), stringsAsFactors = FALSE)
audience_briefing_needs <- read.csv(file.path(data_dir, "audience_briefing_needs.csv"), stringsAsFactors = FALSE)
visualization_safeguards <- read.csv(file.path(data_dir, "visualization_safeguards.csv"), stringsAsFactors = FALSE)

model_results$uncertainty_width <- model_results$upper_bound - model_results$lower_bound

model_results$communication_quality_score <-
  0.30 * model_results$assumption_disclosure +
  0.30 * model_results$uncertainty_disclosure +
  0.20 * model_results$boundary_disclosure +
  0.20 * model_results$misuse_warning

model_results$false_precision_risk <- ifelse(
  model_results$uncertainty_disclosure < 0.60 & model_results$uncertainty_width > 0.20,
  "high_false_precision_risk",
  ifelse(model_results$uncertainty_disclosure < 0.70, "moderate_false_precision_risk", "lower_false_precision_risk")
)

control_summary <- data.frame(
  metric = c("communication_controls", "present_controls", "missing_controls"),
  value = c(
    nrow(communication_controls),
    sum(tolower(communication_controls$present) == "true"),
    sum(tolower(communication_controls$present) != "true")
  )
)

validation_checks <- data.frame(
  check = c(
    "model_results_created",
    "communication_scores_between_zero_and_one",
    "uncertainty_widths_nonnegative",
    "communication_controls_created",
    "valid_use_register_created",
    "visualization_safeguards_created"
  ),
  passed = c(
    nrow(model_results) > 0,
    all(model_results$communication_quality_score >= 0 & model_results$communication_quality_score <= 1),
    all(model_results$uncertainty_width >= 0),
    nrow(communication_controls) > 0,
    nrow(valid_use_register) > 0,
    nrow(visualization_safeguards) > 0
  )
)

write.csv(model_results, file.path(tables_dir, "r_model_result_communication_diagnostics.csv"), row.names = FALSE)
write.csv(communication_controls, file.path(tables_dir, "r_model_communication_controls.csv"), row.names = FALSE)
write.csv(control_summary, file.path(tables_dir, "r_model_communication_control_summary.csv"), row.names = FALSE)
write.csv(valid_use_register, file.path(tables_dir, "r_model_valid_use_register.csv"), row.names = FALSE)
write.csv(audience_briefing_needs, file.path(tables_dir, "r_audience_briefing_needs.csv"), row.names = FALSE)
write.csv(visualization_safeguards, file.path(tables_dir, "r_visualization_safeguards.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_model_communication_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_communication_quality_scores.png"), width = 1000, height = 700)
barplot(
  model_results$communication_quality_score,
  names.arg = model_results$result_id,
  ylab = "Communication Quality Score",
  xlab = "Result ID",
  main = "Model Result Communication Quality"
)
grid()
dev.off()

print(model_results)
print(communication_controls)
print(validation_checks)
cat("R communicating model results responsibly workflow complete.\n")
