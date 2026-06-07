# delay_oscillation_policy_resistance_diagnostics.R
# Base R workflow:
# simulating delayed feedback, oscillation, and policy resistance.

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

target_crossings <- function(values, target) {
  centered <- values - target
  crossings <- 0

  for (i in 2:length(centered)) {
    if (centered[i - 1] == 0 || centered[i] == 0) {
      next
    }

    if ((centered[i - 1] < 0 && centered[i] > 0) ||
        (centered[i - 1] > 0 && centered[i] < 0)) {
      crossings <- crossings + 1
    }
  }

  crossings
}

simulate_delay_system <- function(
  scenario,
  delay,
  correction_strength,
  counterresponse_strength,
  perception_smoothing,
  natural_pressure_base,
  natural_pressure_slope,
  n_steps = 100
) {
  target <- 50
  state <- numeric(n_steps)
  perceived_state <- numeric(n_steps)
  intervention <- numeric(n_steps)
  counterresponse <- numeric(n_steps)

  state[1] <- 80
  perceived_state[1] <- 80

  for (t in 2:n_steps) {
    perceived_state[t] <- perception_smoothing * state[t - 1] +
      (1 - perception_smoothing) * perceived_state[t - 1]

    observed_index <- max(1, t - delay)
    observed_gap <- perceived_state[observed_index] - target

    intervention[t] <- correction_strength * max(0, observed_gap)
    counterresponse[t] <- counterresponse_strength * intervention[t]

    natural_pressure <- natural_pressure_base + natural_pressure_slope * state[t - 1]

    state[t] <- max(
      0,
      state[t - 1] +
        natural_pressure +
        counterresponse[t] -
        intervention[t]
    )
  }

  data.frame(
    scenario = scenario,
    time = seq_len(n_steps),
    state = state,
    perceived_state = perceived_state,
    target = target,
    intervention = intervention,
    counterresponse = counterresponse,
    target_gap = state - target
  )
}

runs <- rbind(
  simulate_delay_system("timely_moderate_response", 1, 0.18, 0.00, 0.75, 2.0, 0.025),
  simulate_delay_system("delayed_response", 6, 0.18, 0.00, 0.55, 2.0, 0.025),
  simulate_delay_system("overcorrection", 6, 0.34, 0.00, 0.55, 2.0, 0.025),
  simulate_delay_system("undercorrection", 6, 0.09, 0.00, 0.55, 2.0, 0.025),
  simulate_delay_system("policy_resistance", 6, 0.24, 0.42, 0.55, 2.0, 0.025),
  simulate_delay_system("slow_recognition_high_resistance", 10, 0.24, 0.55, 0.35, 2.0, 0.025),
  simulate_delay_system("adaptive_moderated_response", 3, 0.20, 0.12, 0.70, 1.6, 0.018)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  cumulative_intervention <- sum(subset_data$intervention)
  cumulative_counterresponse <- sum(subset_data$counterresponse)

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      initial_state = subset_data$state[1],
      final_state = subset_data$state[nrow(subset_data)],
      minimum_state = min(subset_data$state),
      maximum_state = max(subset_data$state),
      final_target_gap = subset_data$state[nrow(subset_data)] - subset_data$target[1],
      target_crossings = target_crossings(subset_data$state, subset_data$target[1]),
      maximum_overshoot_above_target = max(0, max(subset_data$state - subset_data$target)),
      maximum_undershoot_below_target = max(0, subset_data$target[1] - min(subset_data$state)),
      mean_absolute_target_gap = mean(abs(subset_data$target_gap)),
      cumulative_intervention = cumulative_intervention,
      cumulative_counterresponse = cumulative_counterresponse,
      resistance_ratio = ifelse(cumulative_intervention > 0, cumulative_counterresponse / cumulative_intervention, 0)
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_delay_oscillation_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_delay_oscillation_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_delay_oscillation_trajectories.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(runs$state),
  xlab = "Time",
  ylab = "System State",
  main = "Delayed Feedback, Oscillation, and Policy Resistance"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$state, lwd = 2)
}

abline(h = 50, lty = 2)

legend(
  "topright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.60
)
grid()
dev.off()

print(summary_rows)
cat("R delay, oscillation, and policy resistance diagnostics complete.\n")
