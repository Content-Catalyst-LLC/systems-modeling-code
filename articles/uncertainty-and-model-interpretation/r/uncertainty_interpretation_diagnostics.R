# uncertainty_interpretation_diagnostics.R
# Base R workflow:
# Monte Carlo uncertainty propagation in a dynamic systems model.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

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

set.seed(42)

simulate_system <- function(
  growth_rate,
  carrying_capacity,
  extraction_pressure,
  shock_intensity,
  shock_time,
  n_steps = 80,
  initial_state = 10
) {
  state <- numeric(n_steps)
  state[1] <- initial_state

  for (t in 2:n_steps) {
    shock_effect <- ifelse(t == shock_time, shock_intensity, 0)

    state[t] <- state[t - 1] +
      growth_rate * state[t - 1] * (1 - state[t - 1] / carrying_capacity) -
      extraction_pressure * state[t - 1] -
      shock_effect

    state[t] <- max(state[t], 0)
  }

  data.frame(
    time = seq_len(n_steps),
    state = state
  )
}

n_runs <- 600
n_steps <- 80

run_results <- data.frame()
parameter_records <- data.frame()

for (run_id in seq_len(n_runs)) {
  growth_rate <- runif(1, 0.045, 0.120)
  carrying_capacity <- runif(1, 70, 145)
  extraction_pressure <- runif(1, 0.005, 0.050)
  shock_intensity <- runif(1, 0, 20)
  shock_time <- sample(30:55, 1)

  trajectory <- simulate_system(
    growth_rate = growth_rate,
    carrying_capacity = carrying_capacity,
    extraction_pressure = extraction_pressure,
    shock_intensity = shock_intensity,
    shock_time = shock_time,
    n_steps = n_steps
  )

  trajectory$run_id <- run_id
  trajectory$growth_rate <- growth_rate
  trajectory$carrying_capacity <- carrying_capacity
  trajectory$extraction_pressure <- extraction_pressure
  trajectory$shock_intensity <- shock_intensity
  trajectory$shock_time <- shock_time

  run_results <- rbind(run_results, trajectory)

  parameter_records <- rbind(parameter_records, data.frame(
    run_id = run_id,
    growth_rate = growth_rate,
    carrying_capacity = carrying_capacity,
    extraction_pressure = extraction_pressure,
    shock_intensity = shock_intensity,
    shock_time = shock_time
  ))
}

summary_rows <- data.frame()

for (time_value in sort(unique(run_results$time))) {
  subset_data <- run_results[run_results$time == time_value, ]

  summary_rows <- rbind(summary_rows, data.frame(
    time = time_value,
    mean_state = mean(subset_data$state),
    median_state = median(subset_data$state),
    p05 = as.numeric(quantile(subset_data$state, 0.05)),
    p10 = as.numeric(quantile(subset_data$state, 0.10)),
    p90 = as.numeric(quantile(subset_data$state, 0.90)),
    p95 = as.numeric(quantile(subset_data$state, 0.95)),
    minimum_state = min(subset_data$state),
    maximum_state = max(subset_data$state)
  ))
}

final_states <- run_results[run_results$time == n_steps, ]

uncertainty_summary <- data.frame(
  metric = c(
    "final_state_mean",
    "final_state_median",
    "final_state_p10",
    "final_state_p90",
    "final_state_range",
    "share_below_50",
    "share_above_100"
  ),
  value = c(
    mean(final_states$state),
    median(final_states$state),
    as.numeric(quantile(final_states$state, 0.10)),
    as.numeric(quantile(final_states$state, 0.90)),
    max(final_states$state) - min(final_states$state),
    mean(final_states$state < 50),
    mean(final_states$state > 100)
  )
)

write.csv(parameter_records, file.path(tables_dir, "r_uncertainty_parameter_draws.csv"), row.names = FALSE)
write.csv(run_results, file.path(tables_dir, "r_uncertainty_ensemble_runs.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_uncertainty_ensemble_summary.csv"), row.names = FALSE)
write.csv(uncertainty_summary, file.path(tables_dir, "r_uncertainty_interpretation_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_uncertainty_ensemble_bands.png"), width = 1200, height = 700)
plot(
  summary_rows$time,
  summary_rows$mean_state,
  type = "l",
  lwd = 2,
  ylim = range(summary_rows$p05, summary_rows$p95),
  xlab = "Time",
  ylab = "System State",
  main = "Uncertainty Propagation Across Ensemble Trajectories"
)
lines(summary_rows$time, summary_rows$p10, lty = 2)
lines(summary_rows$time, summary_rows$p90, lty = 2)
lines(summary_rows$time, summary_rows$p05, lty = 3)
lines(summary_rows$time, summary_rows$p95, lty = 3)
legend(
  "topleft",
  legend = c("Mean", "P10 / P90", "P05 / P95"),
  lwd = c(2, 1, 1),
  lty = c(1, 2, 3),
  bty = "n"
)
grid()
dev.off()

print(uncertainty_summary)
cat("R uncertainty interpretation diagnostics complete.\n")
