# leverage_points_intervention_diagnostics.R
# Base R workflow:
# comparing parameter, buffer, delay, feedback, rule, and goal interventions.

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

simulate_system <- function(
  scenario,
  feedback_gain,
  external_correction,
  information_delay,
  information_quality,
  buffer_capacity,
  rule_threshold,
  rule_feedback_gain,
  self_organization_rate,
  goal_weight_resilience,
  implementation_delay,
  n_steps = 96
) {
  state <- numeric(n_steps)
  pressure <- numeric(n_steps)
  resilience <- numeric(n_steps)
  learning_capacity <- numeric(n_steps)
  intervention <- numeric(n_steps)
  buffer_remaining <- numeric(n_steps)

  state[1] <- 70
  pressure[1] <- 50
  resilience[1] <- 30
  learning_capacity[1] <- 0
  intervention[1] <- 0
  buffer_remaining[1] <- buffer_capacity

  for (t in 2:n_steps) {
    observed_index <- max(1, t - information_delay)
    delayed_signal <- state[observed_index]
    current_signal <- state[t - 1]
    observed_state <- information_quality * current_signal + (1 - information_quality) * delayed_signal

    current_gain <- feedback_gain
    if (!is.na(rule_threshold) && observed_state > rule_threshold) {
      current_gain <- rule_feedback_gain
    }

    learning_capacity[t] <- min(
      100,
      learning_capacity[t - 1] +
        self_organization_rate * (100 - learning_capacity[t - 1]) / 8
    )

    resilience_gap <- max(0, 100 - resilience[t - 1])
    resilience_investment <- goal_weight_resilience * resilience_gap

    buffer_absorption <- min(buffer_remaining[t - 1], 0.10 * pressure[t - 1])
    buffer_remaining[t] <- max(0, buffer_remaining[t - 1] - buffer_absorption + 0.02 * buffer_capacity)

    correction <- 0

    if (t >= implementation_delay) {
      correction <- external_correction +
        0.05 * max(0, observed_state - 40) +
        resilience_investment +
        0.04 * learning_capacity[t]
    }

    intervention[t] <- correction

    pressure[t] <- max(
      0,
      0.91 * pressure[t - 1] +
        0.07 * state[t - 1] -
        0.30 * correction -
        0.08 * buffer_absorption -
        0.04 * resilience[t - 1]
    )

    resilience[t] <- min(
      100,
      max(
        0,
        resilience[t - 1] +
          0.18 * resilience_investment +
          0.05 * learning_capacity[t] -
          0.025 * pressure[t - 1]
      )
    )

    state[t] <- max(
      0,
      current_gain * state[t - 1] +
        0.24 * pressure[t] -
        0.34 * correction -
        0.08 * buffer_absorption -
        0.045 * resilience[t]
    )
  }

  data.frame(
    scenario = scenario,
    time = seq_len(n_steps),
    state = state,
    pressure = pressure,
    resilience = resilience,
    learning_capacity = learning_capacity,
    intervention = intervention,
    buffer_remaining = buffer_remaining
  )
}

runs <- rbind(
  simulate_system("baseline", 0.96, 2.0, 6, 0.70, 0, NA, 0.96, 0.00, 0.00, 1),
  simulate_system("parameter_intervention", 0.96, 5.0, 6, 0.70, 0, NA, 0.96, 0.00, 0.00, 1),
  simulate_system("buffer_intervention", 0.96, 2.0, 6, 0.70, 18, NA, 0.96, 0.00, 0.00, 1),
  simulate_system("delay_intervention", 0.96, 2.0, 1, 0.85, 0, NA, 0.96, 0.00, 0.00, 1),
  simulate_system("feedback_intervention", 0.78, 2.0, 6, 0.70, 0, NA, 0.78, 0.00, 0.00, 1),
  simulate_system("information_flow_intervention", 0.92, 2.0, 1, 0.95, 0, NA, 0.92, 0.00, 0.00, 1),
  simulate_system("rule_intervention", 0.96, 2.0, 2, 0.85, 0, 45, 0.70, 0.00, 0.00, 1),
  simulate_system("self_organization_intervention", 0.92, 2.0, 2, 0.85, 8, 45, 0.72, 0.18, 0.04, 1),
  simulate_system("goal_intervention", 0.90, 2.0, 2, 0.90, 10, 45, 0.72, 0.12, 0.10, 1)
)

summary_rows <- data.frame()

baseline_final <- runs$state[runs$scenario == "baseline" & runs$time == max(runs$time)]

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  cumulative_intervention <- sum(subset_data$intervention)
  final_state <- subset_data$state[nrow(subset_data)]
  behavior_change <- baseline_final - final_state
  leverage_ratio <- ifelse(cumulative_intervention > 0, behavior_change / cumulative_intervention, 0)

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      initial_state = subset_data$state[1],
      final_state = final_state,
      maximum_state = max(subset_data$state),
      minimum_state = min(subset_data$state),
      mean_pressure = mean(subset_data$pressure),
      final_resilience = subset_data$resilience[nrow(subset_data)],
      final_learning_capacity = subset_data$learning_capacity[nrow(subset_data)],
      cumulative_intervention = cumulative_intervention,
      behavior_change_from_baseline = behavior_change,
      leverage_ratio = leverage_ratio
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_leverage_intervention_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_leverage_intervention_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_leverage_intervention_state.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(runs$state),
  xlab = "Time",
  ylab = "System State",
  main = "Shallow and Deep Leverage Interventions"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$state, lwd = 2)
}

legend(
  "topright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.65
)
grid()
dev.off()

print(summary_rows)
cat("R leverage points intervention diagnostics complete.\n")
