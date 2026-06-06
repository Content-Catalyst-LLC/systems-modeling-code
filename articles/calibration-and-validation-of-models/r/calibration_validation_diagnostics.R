# calibration_validation_diagnostics.R
# Base R workflow:
# parameter calibration and out-of-sample validation.

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

settings_df <- read.csv(file.path(data_dir, "calibration_settings.csv"), stringsAsFactors = FALSE)

setting <- function(name) {
  as.numeric(settings_df$value[settings_df$setting == name][1])
}

set.seed(42)

n_steps <- as.integer(setting("n_steps"))
train_cutoff <- as.integer(setting("train_cutoff"))
time <- seq_len(n_steps)

true_growth_rate <- setting("true_growth_rate")
true_capacity <- setting("true_carrying_capacity")
noise_sd <- setting("noise_sd")

simulate_model <- function(growth_rate, capacity, n, initial_state) {
  state <- numeric(n)
  state[1] <- initial_state

  for (t in 2:n) {
    state[t] <- state[t - 1] +
      growth_rate * state[t - 1] * (1 - state[t - 1] / capacity)

    state[t] <- max(state[t], 0)
  }

  state
}

true_state <- simulate_model(
  growth_rate = true_growth_rate,
  capacity = true_capacity,
  n = n_steps,
  initial_state = setting("initial_state")
)

observed <- pmax(0, true_state + rnorm(n_steps, 0, noise_sd))

observed_df <- data.frame(
  time = time,
  true_synthetic_state = true_state,
  observed = observed
)

train_df <- observed_df[observed_df$time <= train_cutoff, ]
valid_df <- observed_df[observed_df$time > train_cutoff, ]

objective_fn <- function(parameters) {
  growth_rate <- parameters[1]
  capacity <- parameters[2]

  predicted <- simulate_model(
    growth_rate = growth_rate,
    capacity = capacity,
    n = nrow(train_df),
    initial_state = train_df$observed[1]
  )

  sum((train_df$observed - predicted)^2)
}

fit <- optim(
  par = c(0.07, 100),
  fn = objective_fn,
  method = "L-BFGS-B",
  lower = c(setting("grid_growth_min"), setting("grid_capacity_min")),
  upper = c(setting("grid_growth_max"), setting("grid_capacity_max"))
)

growth_hat <- fit$par[1]
capacity_hat <- fit$par[2]

train_prediction <- simulate_model(
  growth_rate = growth_hat,
  capacity = capacity_hat,
  n = nrow(train_df),
  initial_state = train_df$observed[1]
)

validation_start <- train_df$observed[nrow(train_df)]

validation_prediction <- simulate_model(
  growth_rate = growth_hat,
  capacity = capacity_hat,
  n = nrow(valid_df) + 1,
  initial_state = validation_start
)[-1]

train_results <- data.frame(
  time = train_df$time,
  dataset = "calibration",
  observed = train_df$observed,
  predicted = train_prediction,
  residual = train_df$observed - train_prediction
)

valid_results <- data.frame(
  time = valid_df$time,
  dataset = "validation",
  observed = valid_df$observed,
  predicted = validation_prediction,
  residual = valid_df$observed - validation_prediction
)

combined_results <- rbind(train_results, valid_results)

rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}

mae <- function(actual, predicted) {
  mean(abs(actual - predicted))
}

metrics <- data.frame(
  dataset = c("calibration", "validation"),
  rmse = c(
    rmse(train_results$observed, train_results$predicted),
    rmse(valid_results$observed, valid_results$predicted)
  ),
  mae = c(
    mae(train_results$observed, train_results$predicted),
    mae(valid_results$observed, valid_results$predicted)
  ),
  bias = c(
    mean(train_results$residual),
    mean(valid_results$residual)
  ),
  observation_count = c(nrow(train_results), nrow(valid_results))
)

parameter_estimates <- data.frame(
  parameter = c("growth_rate", "carrying_capacity"),
  estimated_value = c(growth_hat, capacity_hat),
  true_synthetic_value = c(true_growth_rate, true_capacity),
  lower_bound = c(setting("grid_growth_min"), setting("grid_capacity_min")),
  upper_bound = c(setting("grid_growth_max"), setting("grid_capacity_max")),
  calibration_method = "optim_L_BFGS_B"
)

persistence_prediction <- rep(train_df$observed[nrow(train_df)], nrow(valid_df))

slope <- (train_df$observed[nrow(train_df)] - train_df$observed[1]) /
  (train_df$time[nrow(train_df)] - train_df$time[1])

linear_prediction <- pmax(
  0,
  train_df$observed[nrow(train_df)] + slope * (valid_df$time - train_df$time[nrow(train_df)])
)

benchmark_metrics <- data.frame(
  benchmark = c("calibrated_logistic", "persistence", "linear_trend"),
  validation_rmse = c(
    rmse(valid_df$observed, validation_prediction),
    rmse(valid_df$observed, persistence_prediction),
    rmse(valid_df$observed, linear_prediction)
  ),
  validation_mae = c(
    mae(valid_df$observed, validation_prediction),
    mae(valid_df$observed, persistence_prediction),
    mae(valid_df$observed, linear_prediction)
  ),
  validation_bias = c(
    mean(valid_df$observed - validation_prediction),
    mean(valid_df$observed - persistence_prediction),
    mean(valid_df$observed - linear_prediction)
  )
)

benchmark_metrics <- benchmark_metrics[order(benchmark_metrics$validation_rmse), ]

validation_summary <- data.frame(
  check = c(
    "calibration_rmse_nonnegative",
    "validation_rmse_nonnegative",
    "generalization_gap_reported",
    "growth_rate_within_bounds",
    "capacity_within_bounds",
    "benchmark_comparison_completed"
  ),
  value = c(
    metrics$rmse[metrics$dataset == "calibration"],
    metrics$rmse[metrics$dataset == "validation"],
    metrics$rmse[metrics$dataset == "validation"] - metrics$rmse[metrics$dataset == "calibration"],
    growth_hat,
    capacity_hat,
    1
  ),
  passed = c(
    metrics$rmse[metrics$dataset == "calibration"] >= 0,
    metrics$rmse[metrics$dataset == "validation"] >= 0,
    TRUE,
    growth_hat >= setting("grid_growth_min") && growth_hat <= setting("grid_growth_max"),
    capacity_hat >= setting("grid_capacity_min") && capacity_hat <= setting("grid_capacity_max"),
    TRUE
  )
)

write.csv(observed_df, file.path(tables_dir, "r_observed_synthetic_data.csv"), row.names = FALSE)
write.csv(combined_results, file.path(tables_dir, "r_calibration_validation_results.csv"), row.names = FALSE)
write.csv(metrics, file.path(tables_dir, "r_calibration_validation_metrics.csv"), row.names = FALSE)
write.csv(parameter_estimates, file.path(tables_dir, "r_parameter_estimates.csv"), row.names = FALSE)
write.csv(benchmark_metrics, file.path(tables_dir, "r_benchmark_validation_metrics.csv"), row.names = FALSE)
write.csv(validation_summary, file.path(tables_dir, "r_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_calibration_validation_fit.png"), width = 1200, height = 700)
plot(
  combined_results$time,
  combined_results$observed,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "System State",
  main = "Calibration Fit and Out-of-Sample Validation"
)
lines(combined_results$time, combined_results$predicted, lwd = 2, lty = 2)
abline(v = train_cutoff + 0.5, lty = 3)
legend(
  "bottomright",
  legend = c("Observed", "Predicted", "Calibration / validation split"),
  lwd = c(2, 2, 1),
  lty = c(1, 2, 3),
  bty = "n"
)
grid()
dev.off()

png(file.path(figures_dir, "r_validation_residuals.png"), width = 1200, height = 700)
plot(
  combined_results$time,
  combined_results$residual,
  type = "h",
  lwd = 2,
  xlab = "Time",
  ylab = "Residual",
  main = "Calibration and Validation Residuals"
)
abline(h = 0, lty = 2)
abline(v = train_cutoff + 0.5, lty = 3)
grid()
dev.off()

print(metrics)
print(parameter_estimates)
print(benchmark_metrics)
cat("R calibration and validation diagnostics complete.\n")
