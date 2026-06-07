# ai_surrogate_systems_modeling_workflow.R
# Base R workflow:
# using a statistical surrogate to approximate a nonlinear systems response.

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

n <- 900

input_a <- runif(n, 0, 10)
input_b <- runif(n, -3, 3)
input_c <- runif(n, 1, 8)

structural_baseline <- 1.8 * sin(input_a) + 0.6 * input_b - 0.4 * input_c

true_response <- structural_baseline +
  0.7 * input_b^2 +
  0.25 * input_a * input_b +
  rnorm(n, 0, 0.5)

df <- data.frame(
  input_a = input_a,
  input_b = input_b,
  input_c = input_c,
  structural_baseline = structural_baseline,
  true_response = true_response,
  residual = true_response - structural_baseline
)

train_index <- sample(seq_len(n), size = floor(0.75 * n))
train_df <- df[train_index, ]
test_df <- df[-train_index, ]

surrogate_model <- lm(
  true_response ~ sin(input_a) + input_b + input_c + I(input_b^2) + input_a:input_b,
  data = train_df
)

residual_model <- lm(
  residual ~ input_a + input_b + input_c + I(input_b^2) + input_a:input_b + sin(input_a),
  data = train_df
)

test_df$surrogate_prediction <- predict(surrogate_model, newdata = test_df)
test_df$learned_residual <- predict(residual_model, newdata = test_df)
test_df$hybrid_prediction <- test_df$structural_baseline + test_df$learned_residual

baseline_rmse <- sqrt(mean((test_df$true_response - test_df$structural_baseline)^2))
surrogate_rmse <- sqrt(mean((test_df$true_response - test_df$surrogate_prediction)^2))
hybrid_rmse <- sqrt(mean((test_df$true_response - test_df$hybrid_prediction)^2))

baseline_mae <- mean(abs(test_df$true_response - test_df$structural_baseline))
surrogate_mae <- mean(abs(test_df$true_response - test_df$surrogate_prediction))
hybrid_mae <- mean(abs(test_df$true_response - test_df$hybrid_prediction))

metrics <- data.frame(
  model = c("structural_baseline", "surrogate_model", "hybrid_residual_learning"),
  rmse = c(baseline_rmse, surrogate_rmse, hybrid_rmse),
  mae = c(baseline_mae, surrogate_mae, hybrid_mae)
)

validation_checks <- data.frame(
  check = c(
    "surrogate_rmse_less_than_baseline_rmse",
    "hybrid_rmse_less_than_baseline_rmse",
    "hybrid_mae_less_than_baseline_mae"
  ),
  passed = c(
    surrogate_rmse < baseline_rmse,
    hybrid_rmse < baseline_rmse,
    hybrid_mae < baseline_mae
  )
)

write.csv(
  test_df,
  file.path(tables_dir, "r_ai_surrogate_predictions.csv"),
  row.names = FALSE
)

write.csv(
  metrics,
  file.path(tables_dir, "r_ai_surrogate_metrics.csv"),
  row.names = FALSE
)

write.csv(
  validation_checks,
  file.path(tables_dir, "r_ai_surrogate_validation_checks.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_ai_surrogate_observed_vs_predicted.png"), width = 1000, height = 700)
plot(
  test_df$true_response,
  test_df$hybrid_prediction,
  xlab = "Observed Systems Response",
  ylab = "Hybrid Prediction",
  main = "Hybrid Residual Learning for a Nonlinear Systems Response",
  pch = 19
)
abline(0, 1, lty = 2)
grid()
dev.off()

print(metrics)
print(validation_checks)
cat("R surrogate systems modeling workflow complete.\n")
