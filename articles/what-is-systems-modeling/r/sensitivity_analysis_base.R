# sensitivity_analysis_base.R
# Reads R resilience metrics and writes ranked sensitivity diagnostics.

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)

if (length(file_arg) > 0) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE)
  article_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  article_root <- normalizePath(getwd(), mustWork = TRUE)
}

tables_dir <- file.path(article_root, "outputs", "tables")
input_path <- file.path(tables_dir, "r_resilience_metrics.csv")

if (!file.exists(input_path)) {
  stop("Missing r_resilience_metrics.csv. Run stock_flow_monte_carlo_base.R first.")
}

data <- read.csv(input_path)

parameters <- c(
  "growth_a",
  "coupling_ab",
  "growth_b",
  "coupling_ba",
  "balancing_b",
  "target_b",
  "shock_size",
  "noise_sd"
)

rows <- data.frame()

for (parameter in parameters) {
  rows <- rbind(rows, data.frame(
    parameter = parameter,
    correlation_with_recovery = cor(data[[parameter]], data$recovery_ratio),
    correlation_with_drawdown = cor(data[[parameter]], data$max_drawdown),
    correlation_with_pressure = cor(data[[parameter]], data$average_pressure)
  ))
}

rows$absolute_recovery_correlation <- abs(rows$correlation_with_recovery)
rows <- rows[order(-rows$absolute_recovery_correlation), ]

write.csv(rows, file.path(tables_dir, "r_ranked_sensitivity_diagnostics.csv"), row.names = FALSE)

print(rows)
cat("Sensitivity diagnostics complete.\n")
