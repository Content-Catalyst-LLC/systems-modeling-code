# future_directions_systems_modeling_workflow.R
# Base R workflow: streaming observations, rolling updates, and model-drift diagnostics.

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

set.seed(42)

n_steps <- 120
time <- 0:(n_steps - 1)

true_state <- numeric(n_steps)
observed_state <- numeric(n_steps)
estimated_state <- numeric(n_steps)
drift_indicator <- numeric(n_steps)
intervention_flag <- numeric(n_steps)
capacity <- rep(18, n_steps)

true_state[1] <- 12
observed_state[1] <- true_state[1] + rnorm(1, 0, 1.0)
estimated_state[1] <- observed_state[1]

for (t in 2:n_steps) {
  shock <- ifelse((t - 1) %in% c(35, 70, 95), 4.5, 0)

  true_state[t] <- 0.93 * true_state[t - 1] +
    0.3 * sin((t - 1) / 10) +
    shock +
    rnorm(1, 0, 0.5)

  observed_state[t] <- true_state[t] + rnorm(1, 0, 1.0)

  prediction <- 0.93 * estimated_state[t - 1] + 0.3 * sin((t - 1) / 10)
  residual <- observed_state[t] - prediction

  if (abs(residual) > 3.0) {
    intervention_flag[t] <- 1
    prediction <- prediction + 0.25 * residual
  }

  estimated_state[t] <- 0.70 * prediction + 0.30 * observed_state[t]

  start_index <- max(1, t - 9)
  drift_indicator[t] <- mean(abs(observed_state[start_index:t] - estimated_state[start_index:t]))
}

df <- data.frame(
  time = time,
  true_state = true_state,
  observed_state = observed_state,
  estimated_state = estimated_state,
  absolute_error_observed = abs(observed_state - true_state),
  absolute_error_estimated = abs(estimated_state - true_state),
  drift_indicator = drift_indicator,
  capacity_margin = capacity - estimated_state,
  intervention_flag = intervention_flag
)

summary_metrics <- data.frame(
  metric = c(
    "MAE_observed",
    "MAE_estimated",
    "Max_drift_indicator",
    "Intervention_count",
    "Minimum_capacity_margin"
  ),
  value = c(
    mean(df$absolute_error_observed),
    mean(df$absolute_error_estimated),
    max(df$drift_indicator),
    sum(df$intervention_flag),
    min(df$capacity_margin)
  )
)

governance_controls <- read.csv(file.path(data_dir, "model_governance_controls.csv"), stringsAsFactors = FALSE)
capability_register <- read.csv(file.path(data_dir, "future_capability_register.csv"), stringsAsFactors = FALSE)
adaptive_triggers <- read.csv(file.path(data_dir, "adaptive_triggers.csv"), stringsAsFactors = FALSE)

validation_checks <- data.frame(
  check = c(
    "time_steps_created",
    "estimated_state_created",
    "observed_errors_nonnegative",
    "estimated_errors_nonnegative",
    "drift_indicator_nonnegative",
    "intervention_flags_binary",
    "governance_controls_created",
    "adaptive_triggers_created"
  ),
  passed = c(
    nrow(df) > 0,
    all(!is.na(df$estimated_state)),
    all(df$absolute_error_observed >= 0),
    all(df$absolute_error_estimated >= 0),
    all(df$drift_indicator >= 0),
    all(df$intervention_flag %in% c(0, 1)),
    nrow(governance_controls) > 0,
    nrow(adaptive_triggers) > 0
  )
)

write.csv(df, file.path(tables_dir, "r_future_systems_modeling_streaming_updates.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(tables_dir, "r_future_systems_modeling_summary_metrics.csv"), row.names = FALSE)
write.csv(governance_controls, file.path(tables_dir, "r_model_governance_controls.csv"), row.names = FALSE)
write.csv(capability_register, file.path(tables_dir, "r_future_capability_register.csv"), row.names = FALSE)
write.csv(adaptive_triggers, file.path(tables_dir, "r_adaptive_triggers.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_future_systems_modeling_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_streaming_model_updates.png"), width = 1000, height = 700)
plot(
  df$time,
  df$true_state,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "System State",
  main = "Streaming Observations and Rolling Model Updates"
)
lines(df$time, df$observed_state, lty = 2)
lines(df$time, df$estimated_state, lwd = 2)
points(
  df$time[df$intervention_flag == 1],
  df$estimated_state[df$intervention_flag == 1],
  pch = 19
)
legend(
  "topright",
  legend = c("True State", "Observed State", "Estimated State", "Intervention Trigger"),
  lty = c(1, 2, 1, NA),
  pch = c(NA, NA, NA, 19),
  bty = "n"
)
grid()
dev.off()

print(head(df))
print(summary_metrics)
print(validation_checks)
cat("R future systems modeling workflow complete.\n")
