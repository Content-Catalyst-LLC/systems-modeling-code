# stock_flow_uncertainty_workflow.R
# Base R systems modeling workflow:
# stock-flow recurrence, Monte Carlo uncertainty, sensitivity diagnostics,
# and reproducible CSV/PNG outputs.

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

parameter_table <- read.csv(file.path(data_dir, "stock_flow_parameters.csv"), stringsAsFactors = FALSE)

range_for <- function(name, field) {
  parameter_table[parameter_table$parameter == name, field]
}

simulate_system <- function(seed, params, n_steps = 180) {
  set.seed(seed)

  stock_a <- numeric(n_steps)
  stock_b <- numeric(n_steps)
  pressure <- numeric(n_steps)

  stock_a[1] <- 24
  stock_b[1] <- 18
  pressure[1] <- 30

  for (t in 2:n_steps) {
    shock <- ifelse(t == 75, params$shock_size, 0)

    reinforcing_a <- params$growth_a * stock_a[t - 1]
    pressure_from_b <- -params$coupling_ab * stock_b[t - 1]

    reinforcing_b <- params$growth_b * stock_b[t - 1]
    support_from_a <- params$coupling_ba * stock_a[t - 1]
    correction_b <- params$balancing_b * max(stock_b[t - 1] - params$target_b, 0)

    pressure_feedback <- 0.018 * max(stock_b[t - 1] - params$target_b, 0) +
      0.012 * max(stock_a[t - 1] - 70, 0)

    stock_a[t] <- max(0, stock_a[t - 1] + reinforcing_a + pressure_from_b + shock - 0.018 * pressure[t - 1] + rnorm(1, 0, params$noise_sd))
    stock_b[t] <- max(0, stock_b[t - 1] + reinforcing_b + support_from_a - correction_b - 0.010 * pressure[t - 1] + rnorm(1, 0, params$noise_sd))
    pressure[t] <- max(0, pressure[t - 1] + pressure_feedback - 0.045 * pressure[t - 1] + rnorm(1, 0, params$noise_sd * 0.25))
  }

  data.frame(
    time = seq_len(n_steps),
    stock_a = stock_a,
    stock_b = stock_b,
    pressure = pressure,
    total_state = stock_a + stock_b,
    run_id = seed
  )
}

set.seed(60606)
n_runs <- 300

parameter_names <- parameter_table$parameter
parameter_runs <- data.frame(run_id = 7001:(7000 + n_runs))
for (p in parameter_names) {
  parameter_runs[[p]] <- runif(n_runs, range_for(p, "low"), range_for(p, "high"))
}

all_results <- data.frame()

for (i in seq_len(n_runs)) {
  params <- as.list(parameter_runs[i, parameter_names])
  run_id <- parameter_runs$run_id[i]
  run_data <- simulate_system(run_id, params)
  all_results <- rbind(all_results, run_data)
}

metrics <- data.frame()

for (run_id in unique(all_results$run_id)) {
  subset_data <- all_results[all_results$run_id == run_id, ]
  pre_shock_total <- subset_data$total_state[subset_data$time == 74][1]
  min_total_after_shock <- min(subset_data$total_state[subset_data$time >= 75])
  final_total <- subset_data$total_state[nrow(subset_data)]

  metrics <- rbind(metrics, data.frame(
    run_id = run_id,
    pre_shock_total = pre_shock_total,
    min_total_after_shock = min_total_after_shock,
    final_total = final_total,
    recovery_ratio = final_total / pre_shock_total,
    max_drawdown = pre_shock_total - min_total_after_shock,
    average_pressure = mean(subset_data$pressure),
    volatility = sd(subset_data$total_state)
  ))
}

metrics <- merge(metrics, parameter_runs, by = "run_id")

sensitivity <- data.frame()
for (p in parameter_names) {
  sensitivity <- rbind(sensitivity, data.frame(
    parameter = p,
    correlation_with_recovery = cor(metrics[[p]], metrics$recovery_ratio),
    correlation_with_drawdown = cor(metrics[[p]], metrics$max_drawdown),
    correlation_with_pressure = cor(metrics[[p]], metrics$average_pressure)
  ))
}
sensitivity$absolute_recovery_correlation <- abs(sensitivity$correlation_with_recovery)
sensitivity <- sensitivity[order(-sensitivity$absolute_recovery_correlation), ]

# Robust uncertainty-band calculation.
# aggregate() can return the quantile column as either a matrix-like column
# or as a list depending on the local R version. tapply() gives a stable
# list-like structure that can be safely row-bound.
uncertainty_list <- tapply(
  all_results$total_state,
  all_results$time,
  quantile,
  probs = c(0.05, 0.25, 0.50, 0.75, 0.95)
)

band_matrix <- do.call(rbind, uncertainty_list)

bands <- data.frame(
  time = as.integer(names(uncertainty_list)),
  p05 = band_matrix[, 1],
  p25 = band_matrix[, 2],
  median = band_matrix[, 3],
  p75 = band_matrix[, 4],
  p95 = band_matrix[, 5]
)

write.csv(all_results, file.path(tables_dir, "r_stock_flow_ensemble.csv"), row.names = FALSE)
write.csv(metrics, file.path(tables_dir, "r_stock_flow_metrics.csv"), row.names = FALSE)
write.csv(sensitivity, file.path(tables_dir, "r_sensitivity_summary.csv"), row.names = FALSE)
write.csv(bands, file.path(tables_dir, "r_uncertainty_bands.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_uncertainty_bands.png"), width = 1200, height = 700)
plot(
  bands$time,
  bands$median,
  type = "l",
  lwd = 2,
  ylim = range(c(bands$p05, bands$p95)),
  xlab = "Time",
  ylab = "Total system state",
  main = "Stock-flow Monte Carlo uncertainty bands"
)
lines(bands$time, bands$p05, lty = 2)
lines(bands$time, bands$p95, lty = 2)
lines(bands$time, bands$p25, lty = 3)
lines(bands$time, bands$p75, lty = 3)
abline(v = 75, lty = 2)
legend("topleft", legend = c("Median", "5th/95th", "25th/75th", "Shock"), lty = c(1, 2, 3, 2), lwd = c(2, 1, 1, 1), bty = "n")
dev.off()

print(head(metrics))
print(sensitivity)
cat("R stock-flow uncertainty workflow complete.\n")
