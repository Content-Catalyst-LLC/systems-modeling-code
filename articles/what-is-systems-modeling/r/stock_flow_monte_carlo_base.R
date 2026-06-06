# stock_flow_monte_carlo_base.R
# Base R systems modeling workflow:
# coupled stock-flow simulation, Monte Carlo uncertainty,
# resilience metrics, and sensitivity summaries.

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)

if (length(file_arg) > 0) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE)
  article_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  article_root <- normalizePath(getwd(), mustWork = TRUE)
}

tables_dir <- file.path(article_root, "outputs", "tables")
figures_dir <- file.path(article_root, "outputs", "figures")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

simulate_system <- function(
  n_steps = 180,
  seed = 1,
  growth_a = 0.045,
  coupling_ab = 0.018,
  growth_b = 0.032,
  coupling_ba = 0.041,
  balancing_b = 0.026,
  target_b = 55,
  shock_time = 75,
  shock_size = -12,
  noise_sd = 0.35
) {
  set.seed(seed)

  time <- seq_len(n_steps)
  stock_a <- numeric(n_steps)
  stock_b <- numeric(n_steps)
  pressure <- numeric(n_steps)

  stock_a[1] <- 24
  stock_b[1] <- 18
  pressure[1] <- 30

  for (t in 2:n_steps) {
    shock <- ifelse(t == shock_time, shock_size, 0)

    reinforcing_a <- growth_a * stock_a[t - 1]
    pressure_from_b <- -coupling_ab * stock_b[t - 1]

    reinforcing_b <- growth_b * stock_b[t - 1]
    support_from_a <- coupling_ba * stock_a[t - 1]
    correction_b <- balancing_b * max(stock_b[t - 1] - target_b, 0)

    pressure_feedback <- 0.018 * max(stock_b[t - 1] - target_b, 0) +
      0.012 * max(stock_a[t - 1] - 70, 0)

    stock_a[t] <- stock_a[t - 1] +
      reinforcing_a +
      pressure_from_b +
      shock -
      0.018 * pressure[t - 1] +
      rnorm(1, 0, noise_sd)

    stock_b[t] <- stock_b[t - 1] +
      reinforcing_b +
      support_from_a -
      correction_b -
      0.010 * pressure[t - 1] +
      rnorm(1, 0, noise_sd)

    pressure[t] <- pressure[t - 1] +
      pressure_feedback -
      0.045 * pressure[t - 1] +
      rnorm(1, 0, noise_sd * 0.25)

    stock_a[t] <- max(stock_a[t], 0)
    stock_b[t] <- max(stock_b[t], 0)
    pressure[t] <- max(pressure[t], 0)
  }

  data.frame(
    time = time,
    stock_a = stock_a,
    stock_b = stock_b,
    pressure = pressure,
    total_state = stock_a + stock_b,
    run_seed = seed
  )
}

set.seed(2026)
n_runs <- 250

parameter_grid <- data.frame(
  run_id = seq_len(n_runs),
  seed = 1000 + seq_len(n_runs),
  growth_a = runif(n_runs, 0.025, 0.065),
  coupling_ab = runif(n_runs, 0.010, 0.030),
  growth_b = runif(n_runs, 0.020, 0.050),
  coupling_ba = runif(n_runs, 0.025, 0.055),
  balancing_b = runif(n_runs, 0.015, 0.040),
  target_b = runif(n_runs, 48, 65),
  shock_size = runif(n_runs, -18, -6),
  noise_sd = runif(n_runs, 0.15, 0.60)
)

simulation_results <- data.frame()

for (i in seq_len(nrow(parameter_grid))) {
  params <- parameter_grid[i, ]

  run_data <- simulate_system(
    seed = params$seed,
    growth_a = params$growth_a,
    coupling_ab = params$coupling_ab,
    growth_b = params$growth_b,
    coupling_ba = params$coupling_ba,
    balancing_b = params$balancing_b,
    target_b = params$target_b,
    shock_size = params$shock_size,
    noise_sd = params$noise_sd
  )

  run_data$run_id <- params$run_id
  simulation_results <- rbind(simulation_results, run_data)
}

metrics <- data.frame()

for (run_id in unique(simulation_results$run_id)) {
  subset_data <- simulation_results[simulation_results$run_id == run_id, ]
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

resilience_metrics <- merge(metrics, parameter_grid, by = "run_id")

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

sensitivity_summary <- data.frame(
  parameter = parameters,
  correlation_with_recovery = sapply(parameters, function(p) {
    cor(resilience_metrics[[p]], resilience_metrics$recovery_ratio)
  })
)

sensitivity_summary$abs_correlation <- abs(sensitivity_summary$correlation_with_recovery)
sensitivity_summary <- sensitivity_summary[order(-sensitivity_summary$abs_correlation), ]

uncertainty_bands <- aggregate(
  total_state ~ time,
  data = simulation_results,
  FUN = function(x) {
    quantile(x, probs = c(0.05, 0.25, 0.50, 0.75, 0.95))
  }
)

band_matrix <- do.call(rbind, uncertainty_bands$total_state)
scenario_bands <- data.frame(
  time = uncertainty_bands$time,
  p05 = band_matrix[, 1],
  p25 = band_matrix[, 2],
  median = band_matrix[, 3],
  p75 = band_matrix[, 4],
  p95 = band_matrix[, 5]
)

write.csv(simulation_results, file.path(tables_dir, "r_stock_flow_monte_carlo_results.csv"), row.names = FALSE)
write.csv(resilience_metrics, file.path(tables_dir, "r_resilience_metrics.csv"), row.names = FALSE)
write.csv(sensitivity_summary, file.path(tables_dir, "r_sensitivity_summary.csv"), row.names = FALSE)
write.csv(scenario_bands, file.path(tables_dir, "r_uncertainty_bands.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_uncertainty_bands.png"), width = 1200, height = 700)
plot(
  scenario_bands$time,
  scenario_bands$median,
  type = "l",
  lwd = 2,
  ylim = range(c(scenario_bands$p05, scenario_bands$p95)),
  xlab = "Time",
  ylab = "Total system state",
  main = "Monte Carlo stock-flow uncertainty bands"
)
lines(scenario_bands$time, scenario_bands$p05, lty = 2)
lines(scenario_bands$time, scenario_bands$p95, lty = 2)
lines(scenario_bands$time, scenario_bands$p25, lty = 3)
lines(scenario_bands$time, scenario_bands$p75, lty = 3)
abline(v = 75, lty = 2)
legend("topleft", legend = c("Median", "5th/95th", "25th/75th", "Shock"), lty = c(1, 2, 3, 2), lwd = c(2, 1, 1, 1), bty = "n")
dev.off()

print(head(simulation_results))
print(sensitivity_summary)
cat("R stock-flow Monte Carlo workflow complete.\n")
cat(file.path(tables_dir, "r_sensitivity_summary.csv"), "\n")
