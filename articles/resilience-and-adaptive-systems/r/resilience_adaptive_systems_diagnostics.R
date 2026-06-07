# resilience_adaptive_systems_diagnostics.R
# Base R workflow for repeated shocks, adaptive capacity, recovery time, and resilience loss.

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

simulate_resilience <- function(scenario, n_steps = 180, initial_recovery_strength = 0.22,
                                recovery_erosion = 0.0009, learning_gain = 0.0007,
                                shock_multiplier = 1.0, adaptation_floor = 0.03) {
  time <- seq_len(n_steps)
  state <- numeric(n_steps)
  adaptive_capacity <- numeric(n_steps)
  shock <- numeric(n_steps)
  performance <- numeric(n_steps)
  adaptive_capacity[1] <- initial_recovery_strength
  performance[1] <- 1
  shock_times <- c(25, 55, 90, 125, 155)
  shock_values <- c(1.5, 1.7, 2.0, 2.2, 2.5) * shock_multiplier
  shock[shock_times] <- shock_values
  for (t in 2:n_steps) {
    adaptive_capacity[t] <- max(adaptation_floor,
      adaptive_capacity[t - 1] - recovery_erosion + learning_gain * max(0, 1 - abs(state[t - 1])))
    state[t] <- state[t - 1] - adaptive_capacity[t] * state[t - 1] + shock[t] + rnorm(1, 0, 0.025)
    performance[t] <- max(0, 1 - abs(state[t]) / 4)
  }
  data.frame(scenario, time, state, absolute_state = abs(state), adaptive_capacity, shock, performance, performance_loss = 1 - performance)
}

recovery_time_after_shock <- function(df, shock_time, tolerance = 0.25) {
  after <- df[df$time >= shock_time, ]
  recovered <- after$time[abs(after$state) <= tolerance]
  if (length(recovered) == 0) return(NA_real_)
  min(recovered) - shock_time
}

runs <- rbind(
  simulate_resilience("baseline_adaptation", initial_recovery_strength = 0.22, recovery_erosion = 0.0009, learning_gain = 0.0007, shock_multiplier = 1.0),
  simulate_resilience("weakened_capacity", initial_recovery_strength = 0.16, recovery_erosion = 0.0014, learning_gain = 0.0003, shock_multiplier = 1.0),
  simulate_resilience("compound_stress", initial_recovery_strength = 0.18, recovery_erosion = 0.0012, learning_gain = 0.0004, shock_multiplier = 1.35),
  simulate_resilience("learning_investment", initial_recovery_strength = 0.24, recovery_erosion = 0.0006, learning_gain = 0.0012, shock_multiplier = 1.0),
  simulate_resilience("high_redundancy", initial_recovery_strength = 0.27, recovery_erosion = 0.0008, learning_gain = 0.0008, shock_multiplier = 0.85, adaptation_floor = 0.05),
  simulate_resilience("fragile_efficiency", initial_recovery_strength = 0.14, recovery_erosion = 0.0018, learning_gain = 0.0002, shock_multiplier = 1.20, adaptation_floor = 0.02)
)

shock_times <- c(25, 55, 90, 125, 155)
summary_rows <- data.frame()
for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  recovery_times <- sapply(shock_times, function(shock_time) recovery_time_after_shock(subset_data, shock_time))
  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    final_state = subset_data$state[nrow(subset_data)],
    maximum_abs_state = max(abs(subset_data$state)),
    minimum_performance = min(subset_data$performance),
    mean_performance = mean(subset_data$performance),
    initial_adaptive_capacity = subset_data$adaptive_capacity[1],
    final_adaptive_capacity = subset_data$adaptive_capacity[nrow(subset_data)],
    adaptive_capacity_change = subset_data$adaptive_capacity[nrow(subset_data)] - subset_data$adaptive_capacity[1],
    average_recovery_time = mean(recovery_times, na.rm = TRUE),
    unrecovered_shocks = sum(is.na(recovery_times)),
    cumulative_performance_loss = sum(subset_data$performance_loss)
  ))
}

write.csv(runs, file.path(tables_dir, "r_resilience_adaptive_system_trajectories.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_resilience_adaptive_system_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_resilience_adaptive_systems.png"), width = 1200, height = 700)
plot(NULL, xlim = range(runs$time), ylim = range(runs$performance), xlab = "Time", ylab = "Performance", main = "Resilience Performance Under Repeated Shocks")
for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$performance, lwd = 2)
}
legend("bottomright", legend = unique(runs$scenario), lwd = 2, bty = "n", cex = 0.7)
grid()
dev.off()

print(summary_rows)
cat("R resilience and adaptive systems diagnostics complete.\n")
