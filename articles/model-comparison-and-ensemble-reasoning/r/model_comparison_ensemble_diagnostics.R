# model_comparison_ensemble_diagnostics.R
# Base R workflow:
# comparing structural models and ensemble forecasts.

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

n_steps <- 90
train_cutoff <- 60
time <- seq_len(n_steps)

true_growth <- 0.085
true_capacity <- 130
true_extraction <- 0.012

observed <- numeric(n_steps)
observed[1] <- 12

for (t in 2:n_steps) {
  observed[t] <- observed[t - 1] +
    true_growth * observed[t - 1] * (1 - observed[t - 1] / true_capacity) -
    true_extraction * observed[t - 1] +
    rnorm(1, 0, 1.1)

  observed[t] <- max(observed[t], 0)
}

observed_df <- data.frame(
  time = time,
  observed = observed,
  dataset = ifelse(time <= train_cutoff, "calibration", "validation")
)

train_df <- observed_df[observed_df$dataset == "calibration", ]

simulate_exponential <- function(growth_rate, n, initial_state) {
  state <- numeric(n)
  state[1] <- initial_state

  for (t in 2:n) {
    state[t] <- max(0, state[t - 1] + growth_rate * state[t - 1])
  }

  state
}

simulate_logistic <- function(growth_rate, capacity, n, initial_state) {
  state <- numeric(n)
  state[1] <- initial_state

  for (t in 2:n) {
    state[t] <- max(0, state[t - 1] + growth_rate * state[t - 1] * (1 - state[t - 1] / capacity))
  }

  state
}

simulate_managed <- function(growth_rate, capacity, extraction, n, initial_state) {
  state <- numeric(n)
  state[1] <- initial_state

  for (t in 2:n) {
    state[t] <- max(
      0,
      state[t - 1] +
        growth_rate * state[t - 1] * (1 - state[t - 1] / capacity) -
        extraction * state[t - 1]
    )
  }

  state
}

rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}

mae <- function(actual, predicted) {
  mean(abs(actual - predicted))
}

best_exp <- list(growth = NA, error = Inf)

for (growth in seq(0.005, 0.080, length.out = 80)) {
  prediction <- simulate_exponential(growth, nrow(train_df), train_df$observed[1])
  error <- sum((train_df$observed - prediction)^2)

  if (error < best_exp$error) {
    best_exp <- list(growth = growth, error = error)
  }
}

best_log <- list(growth = NA, capacity = NA, error = Inf)

for (growth in seq(0.025, 0.140, length.out = 60)) {
  for (capacity in seq(80, 180, length.out = 60)) {
    prediction <- simulate_logistic(growth, capacity, nrow(train_df), train_df$observed[1])
    error <- sum((train_df$observed - prediction)^2)

    if (error < best_log$error) {
      best_log <- list(growth = growth, capacity = capacity, error = error)
    }
  }
}

best_managed <- list(growth = NA, capacity = NA, extraction = NA, error = Inf)

for (growth in seq(0.025, 0.150, length.out = 45)) {
  for (capacity in seq(80, 190, length.out = 45)) {
    for (extraction in seq(0.000, 0.035, length.out = 20)) {
      prediction <- simulate_managed(growth, capacity, extraction, nrow(train_df), train_df$observed[1])
      error <- sum((train_df$observed - prediction)^2)

      if (error < best_managed$error) {
        best_managed <- list(
          growth = growth,
          capacity = capacity,
          extraction = extraction,
          error = error
        )
      }
    }
  }
}

make_predictions <- function(model_name, n_total, initial_state) {
  if (model_name == "exponential") {
    simulate_exponential(best_exp$growth, n_total, initial_state)
  } else if (model_name == "logistic") {
    simulate_logistic(best_log$growth, best_log$capacity, n_total, initial_state)
  } else {
    simulate_managed(best_managed$growth, best_managed$capacity, best_managed$extraction, n_total, initial_state)
  }
}

model_names <- c("exponential", "logistic", "managed_logistic")
prediction_rows <- data.frame()

for (model_name in model_names) {
  prediction <- make_predictions(model_name, n_steps, observed_df$observed[1])

  prediction_rows <- rbind(
    prediction_rows,
    data.frame(
      time = observed_df$time,
      dataset = observed_df$dataset,
      model = model_name,
      observed = observed_df$observed,
      predicted = prediction,
      residual = observed_df$observed - prediction
    )
  )
}

ensemble_by_time <- aggregate(
  predicted ~ time + dataset + observed,
  data = prediction_rows,
  FUN = mean
)

ensemble_rows <- data.frame(
  time = ensemble_by_time$time,
  dataset = ensemble_by_time$dataset,
  model = "equal_weight_ensemble",
  observed = ensemble_by_time$observed,
  predicted = ensemble_by_time$predicted,
  residual = ensemble_by_time$observed - ensemble_by_time$predicted
)

all_predictions <- rbind(prediction_rows, ensemble_rows)

metric_rows <- data.frame()

for (model_name in unique(all_predictions$model)) {
  for (dataset_name in c("calibration", "validation")) {
    subset_data <- all_predictions[
      all_predictions$model == model_name & all_predictions$dataset == dataset_name,
    ]

    metric_rows <- rbind(
      metric_rows,
      data.frame(
        model = model_name,
        dataset = dataset_name,
        rmse = rmse(subset_data$observed, subset_data$predicted),
        mae = mae(subset_data$observed, subset_data$predicted),
        bias = mean(subset_data$residual)
      )
    )
  }
}

validation_base <- metric_rows[
  metric_rows$dataset == "validation" & !(metric_rows$model %in% c("equal_weight_ensemble")),
]

inverse_rmse <- 1 / pmax(validation_base$rmse, 1e-9)
weights <- inverse_rmse / sum(inverse_rmse)

weight_df <- data.frame(
  model = validation_base$model,
  weight_type = "validation_inverse_rmse",
  weight = weights
)

weighted_predictions <- data.frame()

for (time_value in unique(observed_df$time)) {
  subset_data <- prediction_rows[prediction_rows$time == time_value, ]
  weighted_value <- sum(subset_data$predicted * weight_df$weight[match(subset_data$model, weight_df$model)])

  weighted_predictions <- rbind(
    weighted_predictions,
    data.frame(
      time = time_value,
      dataset = observed_df$dataset[observed_df$time == time_value],
      model = "performance_weighted_ensemble",
      observed = observed_df$observed[observed_df$time == time_value],
      predicted = weighted_value,
      residual = observed_df$observed[observed_df$time == time_value] - weighted_value
    )
  )
}

all_predictions <- rbind(all_predictions, weighted_predictions)

for (dataset_name in c("calibration", "validation")) {
  subset_data <- weighted_predictions[weighted_predictions$dataset == dataset_name, ]

  metric_rows <- rbind(
    metric_rows,
    data.frame(
      model = "performance_weighted_ensemble",
      dataset = dataset_name,
      rmse = rmse(subset_data$observed, subset_data$predicted),
      mae = mae(subset_data$observed, subset_data$predicted),
      bias = mean(subset_data$residual)
    )
  )
}

validation_metrics <- metric_rows[metric_rows$dataset == "validation", ]
validation_metrics <- validation_metrics[order(validation_metrics$rmse), ]
validation_metrics$model_rank <- seq_len(nrow(validation_metrics))

parameter_rows <- data.frame(
  model = c("exponential", "logistic", "managed_logistic"),
  growth = c(best_exp$growth, best_log$growth, best_managed$growth),
  capacity = c(NA, best_log$capacity, best_managed$capacity),
  extraction = c(NA, NA, best_managed$extraction),
  calibration_sse = c(best_exp$error, best_log$error, best_managed$error),
  dependence_note = "synthetic comparison; models share data and calibration target"
)

write.csv(observed_df, file.path(tables_dir, "r_observed_model_comparison_data.csv"), row.names = FALSE)
write.csv(all_predictions, file.path(tables_dir, "r_model_predictions.csv"), row.names = FALSE)
write.csv(metric_rows, file.path(tables_dir, "r_model_comparison_metrics.csv"), row.names = FALSE)
write.csv(validation_metrics, file.path(tables_dir, "r_validation_model_ranking.csv"), row.names = FALSE)
write.csv(parameter_rows, file.path(tables_dir, "r_model_parameter_estimates.csv"), row.names = FALSE)
write.csv(weight_df, file.path(tables_dir, "r_model_weights.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_model_comparison_validation.png"), width = 1200, height = 700)
plot(
  observed_df$time,
  observed_df$observed,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "System State",
  main = "Model Comparison and Ensemble Forecasts"
)

for (model_name in unique(all_predictions$model)) {
  subset_data <- all_predictions[all_predictions$model == model_name, ]
  lines(subset_data$time, subset_data$predicted, lty = ifelse(grepl("ensemble", model_name), 1, 2))
}

abline(v = train_cutoff + 0.5, lty = 3)
grid()
dev.off()

print(validation_metrics)
cat("R model comparison and ensemble diagnostics complete.\n")
