# digital_twin_state_tracking_workflow.R
# Base R workflow:
# simulating a digital twin state-tracking loop with noisy observations.

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

simulate_twin <- function(
  scenario,
  n_steps = 120,
  initial_state = 50,
  state_persistence = 0.95,
  drift_amplitude = 0.15,
  process_noise = 0.60,
  observation_noise = 1.80,
  update_gain = 0.35,
  anomaly_threshold = 3.50,
  intervention_effect = 1.00,
  shock_times = c(35, 80, 105),
  shock_magnitude = 4.0,
  seed = 42
) {
  set.seed(seed)

  time <- seq_len(n_steps)

  true_state <- numeric(n_steps)
  observed_state <- numeric(n_steps)
  twin_state <- numeric(n_steps)
  prediction_before_update <- numeric(n_steps)
  residual <- numeric(n_steps)
  anomaly_flag <- numeric(n_steps)
  intervention_flag <- numeric(n_steps)

  true_state[1] <- initial_state
  observed_state[1] <- true_state[1] + rnorm(1, 0, observation_noise)
  twin_state[1] <- observed_state[1]
  prediction_before_update[1] <- twin_state[1]

  for (t in 2:n_steps) {
    drift <- drift_amplitude * sin(t / 12)
    shock <- ifelse(t %in% shock_times, shock_magnitude, 0)

    true_state[t] <- state_persistence * true_state[t - 1] +
      drift +
      shock +
      rnorm(1, 0, process_noise)

    observed_state[t] <- true_state[t] + rnorm(1, 0, observation_noise)

    prediction <- state_persistence * twin_state[t - 1] + drift
    residual[t] <- observed_state[t] - prediction

    if (abs(residual[t]) > anomaly_threshold) {
      anomaly_flag[t] <- 1
    }

    if (residual[t] > anomaly_threshold) {
      intervention_flag[t] <- 1
      prediction <- prediction - intervention_effect
    }

    prediction_before_update[t] <- prediction
    twin_state[t] <- prediction + update_gain * residual[t]
  }

  data.frame(
    scenario = scenario,
    time = time,
    true_state = true_state,
    observed_state = observed_state,
    prediction_before_update = prediction_before_update,
    twin_state = twin_state,
    residual = residual,
    anomaly_flag = anomaly_flag,
    intervention_flag = intervention_flag
  )
}

runs <- rbind(
  simulate_twin("baseline_twin", seed = 42),
  simulate_twin("high_noise_twin", observation_noise = 3.20, update_gain = 0.30, anomaly_threshold = 4.80, seed = 43),
  simulate_twin("shock_heavy_twin", process_noise = 0.75, shock_times = c(25, 45, 65, 85, 105), shock_magnitude = 5.5, seed = 44),
  simulate_twin("slow_update_twin", update_gain = 0.18, seed = 45),
  simulate_twin("resilient_twin", process_noise = 0.45, observation_noise = 1.25, update_gain = 0.45, anomaly_threshold = 3.25, intervention_effect = 1.25, shock_magnitude = 3.5, seed = 46)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  observed_mae <- mean(abs(subset_data$observed_state - subset_data$true_state))
  twin_mae <- mean(abs(subset_data$twin_state - subset_data$true_state))
  observed_rmse <- sqrt(mean((subset_data$observed_state - subset_data$true_state)^2))
  twin_rmse <- sqrt(mean((subset_data$twin_state - subset_data$true_state)^2))
  improvement_ratio <- (observed_rmse - twin_rmse) / max(observed_rmse, 1e-12)

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      MAE_observed = observed_mae,
      MAE_twin = twin_mae,
      RMSE_observed = observed_rmse,
      RMSE_twin = twin_rmse,
      anomaly_count = sum(subset_data$anomaly_flag),
      intervention_count = sum(subset_data$intervention_flag),
      tracking_improvement_ratio = improvement_ratio,
      diagnostic_label = ifelse(
        twin_rmse < observed_rmse,
        "twin improved noisy observation",
        "twin did not improve noisy observation"
      )
    )
  )
}

validation_checks <- data.frame(
  check = c(
    "at_least_one_scenario_generated",
    "all_twin_rmse_nonnegative",
    "all_anomaly_counts_nonnegative"
  ),
  passed = c(
    nrow(summary_rows) > 0,
    all(summary_rows$RMSE_twin >= 0),
    all(summary_rows$anomaly_count >= 0)
  )
)

write.csv(
  runs,
  file.path(tables_dir, "r_digital_twin_state_tracking.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_digital_twin_tracking_summary.csv"),
  row.names = FALSE
)

write.csv(
  validation_checks,
  file.path(tables_dir, "r_digital_twin_validation_checks.csv"),
  row.names = FALSE
)

baseline <- runs[runs$scenario == "baseline_twin", ]

png(file.path(figures_dir, "r_digital_twin_state_tracking.png"), width = 1200, height = 700)
plot(
  baseline$time,
  baseline$true_state,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "System State",
  main = "Digital Twin State Tracking"
)
lines(baseline$time, baseline$observed_state, lty = 2)
lines(baseline$time, baseline$twin_state, lwd = 2)
legend(
  "topright",
  legend = c("True State", "Observed State", "Twin Estimate"),
  lwd = c(2, 1, 2),
  lty = c(1, 2, 1),
  bty = "n"
)
grid()
dev.off()

print(summary_rows)
print(validation_checks)
cat("R digital twin state-tracking workflow complete.\n")
