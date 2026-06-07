# clarification_distortion_workflow.R
# Base R workflow:
# clarification value and distortion risk diagnostics.

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

model_cases <- read.csv(file.path(data_dir, "model_cases.csv"), stringsAsFactors = FALSE)
risk_register <- read.csv(file.path(data_dir, "risk_register.csv"), stringsAsFactors = FALSE)
communication_controls <- read.csv(file.path(data_dir, "communication_controls.csv"), stringsAsFactors = FALSE)
use_scope_register <- read.csv(file.path(data_dir, "use_scope_register.csv"), stringsAsFactors = FALSE)
distortion_patterns <- read.csv(file.path(data_dir, "distortion_patterns.csv"), stringsAsFactors = FALSE)

model_cases$clarification_score <-
  0.30 * model_cases$structural_clarity +
  0.25 * model_cases$dynamic_clarity +
  0.25 * model_cases$scenario_clarity +
  0.20 * model_cases$assumption_transparency

model_cases$distortion_risk_score <-
  0.25 * model_cases$false_precision_risk +
  0.30 * model_cases$boundary_risk +
  0.20 * model_cases$proxy_risk +
  0.25 * model_cases$misuse_risk

model_cases$net_interpretive_value <-
  model_cases$clarification_score - model_cases$distortion_risk_score

model_cases$use_label <- ifelse(
  model_cases$net_interpretive_value >= 0.20,
  "strong_clarification_with_managed_risk",
  ifelse(
    model_cases$net_interpretive_value >= 0,
    "useful_with_strong_caveats",
    "high_distortion_risk_without_revision"
  )
)

label_summary <- aggregate(
  cbind(clarification_score, distortion_risk_score, net_interpretive_value) ~ use_label,
  data = model_cases,
  FUN = mean
)

label_counts <- aggregate(
  model_case ~ use_label,
  data = model_cases,
  FUN = length
)
names(label_counts) <- c("use_label", "model_case_count")
label_summary <- merge(label_summary, label_counts, by = "use_label")

validation_checks <- data.frame(
  check = c(
    "model_cases_created",
    "clarification_scores_between_zero_and_one",
    "distortion_scores_between_zero_and_one",
    "risk_register_created",
    "communication_controls_created"
  ),
  passed = c(
    nrow(model_cases) > 0,
    all(model_cases$clarification_score >= 0 & model_cases$clarification_score <= 1),
    all(model_cases$distortion_risk_score >= 0 & model_cases$distortion_risk_score <= 1),
    nrow(risk_register) > 0,
    nrow(communication_controls) > 0
  )
)

write.csv(
  model_cases,
  file.path(tables_dir, "r_clarification_distortion_model_cases.csv"),
  row.names = FALSE
)

write.csv(
  label_summary,
  file.path(tables_dir, "r_clarification_distortion_label_summary.csv"),
  row.names = FALSE
)

write.csv(
  risk_register,
  file.path(tables_dir, "r_clarification_distortion_risk_register.csv"),
  row.names = FALSE
)

write.csv(
  communication_controls,
  file.path(tables_dir, "r_communication_controls.csv"),
  row.names = FALSE
)

write.csv(
  use_scope_register,
  file.path(tables_dir, "r_use_scope_register.csv"),
  row.names = FALSE
)

write.csv(
  distortion_patterns,
  file.path(tables_dir, "r_distortion_patterns.csv"),
  row.names = FALSE
)

write.csv(
  validation_checks,
  file.path(tables_dir, "r_clarification_distortion_validation_checks.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_clarification_vs_distortion.png"), width = 1000, height = 700)
plot(
  model_cases$distortion_risk_score,
  model_cases$clarification_score,
  xlab = "Distortion Risk Score",
  ylab = "Clarification Score",
  main = "Clarification vs Distortion Risk",
  pch = 19
)
text(
  model_cases$distortion_risk_score,
  model_cases$clarification_score,
  labels = model_cases$model_case,
  pos = 4,
  cex = 0.75
)
grid()
dev.off()

print(model_cases)
print(validation_checks)
cat("R clarification and distortion diagnostic workflow complete.\n")
