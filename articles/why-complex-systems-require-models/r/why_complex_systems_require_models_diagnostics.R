# why_complex_systems_require_models_diagnostics.R
# Base R workflow:
# delayed feedback, overshoot, threshold response, scenario comparison,
# and reproducible diagnostics.

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

scenario_params <- read.csv(file.path(data_dir, "scenario_parameters.csv"), stringsAsFactors = FALSE)

simulate_system <- function(row, periods = 160) {
  state <- numeric(periods + 1)
  delayed_state <- numeric(periods + 1)
  inflow <- numeric(periods + 1)
  balancing_outflow <- numeric(periods + 1)
  threshold_penalty <- numeric(periods + 1)
  shock <- numeric(periods + 1)

  state[1] <- 12

  for (t in 2:(periods + 1)) {
    delayed_index <- max(1, t - row$delay)
    delayed_state[t] <- state[delayed_index]

    inflow[t] <- row$growth_rate * state[t - 1]
    balancing_outflow[t] <- row$balancing_strength * max(delayed_state[t] - row$target, 0)

    if (state[t - 1] >= row$threshold) {
      threshold_penalty[t] <- row$threshold_correction * (state[t - 1] - row$threshold)
    }

    if ((t - 1) == row$shock_time) {
      shock[t] <- row$shock_size
    }

    state[t] <- max(0, min(250, state[t - 1] + inflow[t] - balancing_outflow[t] - threshold_penalty[t] + shock[t]))
  }

  data.frame(
    scenario = row$scenario,
    time = 0:periods,
    state = state,
    delayed_state = delayed_state,
    inflow = inflow,
    balancing_outflow = balancing_outflow,
    threshold_penalty = threshold_penalty,
    shock = shock
  )
}

all_data <- data.frame()

for (i in seq_len(nrow(scenario_params))) {
  all_data <- rbind(all_data, simulate_system(scenario_params[i, ]))
}

scenario_names <- unique(all_data$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]

  maximum_state <- max(subset_data$state)
  minimum_state <- min(subset_data$state)
  final_state <- tail(subset_data$state, 1)
  average_state <- mean(subset_data$state)
  time_to_peak <- subset_data$time[which.max(subset_data$state)]
  threshold_active_periods <- sum(subset_data$threshold_penalty > 0)
  maximum_balancing_outflow <- max(subset_data$balancing_outflow)

  diagnostic <- ifelse(
    maximum_state >= 125,
    "severe overshoot from reinforcing growth and delayed correction",
    ifelse(
      threshold_active_periods > 50,
      "persistent threshold pressure",
      ifelse(
        maximum_balancing_outflow > 10,
        "balancing feedback eventually dominates growth",
        "contained trajectory under current assumptions"
      )
    )
  )

  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    minimum_state = minimum_state,
    maximum_state = maximum_state,
    final_state = final_state,
    average_state = average_state,
    maximum_overshoot = max(maximum_state - subset_data$state[1], 0),
    time_to_peak = time_to_peak,
    threshold_active_periods = threshold_active_periods,
    maximum_balancing_outflow = maximum_balancing_outflow,
    diagnostic = diagnostic
  ))
}

write.csv(all_data, file.path(tables_dir, "r_dynamic_system_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_dynamic_system_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_dynamic_system_state_trajectories.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$time),
  ylim = range(all_data$state),
  xlab = "Time",
  ylab = "State",
  main = "Delayed Feedback and Nonlinear System Trajectories"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$state, lwd = 2)
}

legend("topright", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

png(file.path(figures_dir, "r_feedback_components.png"), width = 1200, height = 700)
baseline <- all_data[all_data$scenario == "baseline_delayed_feedback", ]
plot(
  baseline$time,
  baseline$state,
  type = "l",
  lwd = 2,
  ylim = range(c(baseline$state, baseline$inflow, baseline$balancing_outflow, baseline$threshold_penalty)),
  xlab = "Time",
  ylab = "Value",
  main = "Feedback Components in Baseline Scenario"
)
lines(baseline$time, baseline$inflow, lty = 2, lwd = 2)
lines(baseline$time, baseline$balancing_outflow, lty = 3, lwd = 2)
lines(baseline$time, baseline$threshold_penalty, lty = 4, lwd = 2)
legend(
  "topright",
  legend = c("State", "Inflow", "Balancing outflow", "Threshold penalty"),
  lty = c(1, 2, 3, 4),
  lwd = 2,
  bty = "n"
)
grid()
dev.off()

print(summary_rows)
cat("R delayed feedback diagnostics complete.\n")
