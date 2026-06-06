# mathematics_complex_systems_diagnostics.R
# Base R workflow:
# nonlinear trajectories and sensitivity to initial conditions.

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

simulate_logistic_map <- function(r, initial_state, n_steps) {
  x <- numeric(n_steps)
  x[1] <- initial_state

  for (t in 2:n_steps) {
    x[t] <- r * x[t - 1] * (1 - x[t - 1])
  }

  x
}

n_steps <- 120
r_value <- 3.9

trajectory_1 <- simulate_logistic_map(r_value, 0.4000, n_steps)
trajectory_2 <- simulate_logistic_map(r_value, 0.4001, n_steps)

trajectory_df <- data.frame(
  time = seq_len(n_steps),
  r = r_value,
  trajectory_1 = trajectory_1,
  trajectory_2 = trajectory_2,
  abs_difference = abs(trajectory_1 - trajectory_2)
)

divergence_threshold <- 0.10
divergence_times <- trajectory_df$time[trajectory_df$abs_difference >= divergence_threshold]
first_divergence_time <- ifelse(length(divergence_times) == 0, NA, min(divergence_times))

entropy_numeric <- function(values, bins = 10) {
  breaks <- seq(min(values), max(values), length.out = bins + 1)
  counts <- hist(values, breaks = breaks, plot = FALSE, include.lowest = TRUE)$counts
  probabilities <- counts / sum(counts)
  probabilities <- probabilities[probabilities > 0]
  -sum(probabilities * log(probabilities))
}

summary_df <- data.frame(
  metric = c(
    "r_parameter",
    "initial_condition_1",
    "initial_condition_2",
    "initial_difference",
    "maximum_absolute_difference",
    "mean_absolute_difference",
    "trajectory_entropy",
    "divergence_threshold",
    "first_divergence_time"
  ),
  value = c(
    r_value,
    0.4000,
    0.4001,
    abs(0.4000 - 0.4001),
    max(trajectory_df$abs_difference),
    mean(trajectory_df$abs_difference),
    entropy_numeric(trajectory_1),
    divergence_threshold,
    first_divergence_time
  )
)

r_values <- seq(2.8, 4.0, length.out = 80)
bifurcation_rows <- data.frame()

for (r_test in r_values) {
  trajectory <- simulate_logistic_map(r_test, 0.41, 300)
  tail_values <- trajectory[201:300]

  bifurcation_rows <- rbind(
    bifurcation_rows,
    data.frame(
      r = r_test,
      state_value = tail_values
    )
  )
}

write.csv(trajectory_df, file.path(tables_dir, "r_logistic_map_trajectories.csv"), row.names = FALSE)
write.csv(summary_df, file.path(tables_dir, "r_sensitivity_summary.csv"), row.names = FALSE)
write.csv(bifurcation_rows, file.path(tables_dir, "r_bifurcation_sample.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_logistic_map_sensitivity.png"), width = 1200, height = 700)
plot(
  trajectory_df$time,
  trajectory_df$trajectory_1,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "State",
  main = "Sensitivity to Initial Conditions in the Logistic Map"
)
lines(trajectory_df$time, trajectory_df$trajectory_2, lty = 2, lwd = 2)
legend(
  "topright",
  legend = c("Initial state 0.4000", "Initial state 0.4001"),
  lwd = 2,
  lty = c(1, 2),
  bty = "n"
)
grid()
dev.off()

png(file.path(figures_dir, "r_logistic_map_difference.png"), width = 1200, height = 700)
plot(
  trajectory_df$time,
  trajectory_df$abs_difference,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "Absolute Difference",
  main = "Divergence Between Nearly Identical Initial Conditions"
)
abline(h = divergence_threshold, lty = 2)
grid()
dev.off()

print(summary_df)
cat("R mathematics of complex systems diagnostics complete.\n")
