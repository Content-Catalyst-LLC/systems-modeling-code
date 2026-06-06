# history_of_systems_modeling_diagnostics.R
# Base R workflow:
# comparing exponential growth, logistic growth, and delayed feedback regulation.

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

simulate_history <- function(row, n_steps = 160) {
  time <- 0:n_steps

  exponential <- numeric(length(time))
  logistic <- numeric(length(time))
  delayed_feedback <- numeric(length(time))
  delayed_state <- numeric(length(time))
  inflow <- numeric(length(time))
  outflow <- numeric(length(time))
  shock <- numeric(length(time))

  exponential[1] <- 10
  logistic[1] <- 10
  delayed_feedback[1] <- 10

  for (t in 2:length(time)) {
    exponential[t] <- min(250, exponential[t - 1] + row$growth_rate * exponential[t - 1])

    logistic[t] <- min(
      250,
      logistic[t - 1] + row$growth_rate * logistic[t - 1] * (1 - logistic[t - 1] / row$carrying_capacity)
    )

    delayed_index <- max(1, t - row$delay)
    delayed_state[t] <- delayed_feedback[delayed_index]

    inflow[t] <- row$growth_rate * delayed_feedback[t - 1]
    outflow[t] <- row$balancing_strength * max(delayed_state[t] - row$target, 0)

    if ((t - 1) == row$shock_time) {
      shock[t] <- row$shock_size
    }

    delayed_feedback[t] <- max(
      0,
      min(250, delayed_feedback[t - 1] + inflow[t] - outflow[t] + shock[t])
    )
  }

  data.frame(
    scenario = row$scenario,
    time = time,
    exponential = exponential,
    logistic = logistic,
    delayed_feedback = delayed_feedback,
    delayed_state = delayed_state,
    inflow = inflow,
    outflow = outflow,
    shock = shock
  )
}

all_data <- data.frame()

for (i in seq_len(nrow(scenario_params))) {
  all_data <- rbind(all_data, simulate_history(scenario_params[i, ]))
}

scenario_names <- unique(all_data$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]

  max_delayed <- max(subset_data$delayed_feedback)
  max_logistic <- max(subset_data$logistic)
  final_delayed <- tail(subset_data$delayed_feedback, 1)
  time_to_peak <- subset_data$time[which.max(subset_data$delayed_feedback)]
  maximum_outflow <- max(subset_data$outflow)

  diagnostic <- ifelse(
    max_delayed > max_logistic * 1.25,
    "delayed feedback produces overshoot relative to logistic constraint",
    ifelse(
      maximum_outflow > 5,
      "balancing feedback becomes active after delay",
      "delayed feedback remains weak under current assumptions"
    )
  )

  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    final_exponential = tail(subset_data$exponential, 1),
    final_logistic = tail(subset_data$logistic, 1),
    final_delayed_feedback = final_delayed,
    maximum_delayed_feedback = max_delayed,
    average_delayed_feedback = mean(subset_data$delayed_feedback),
    time_to_delayed_feedback_peak = time_to_peak,
    maximum_delayed_feedback_outflow = maximum_outflow,
    diagnostic = diagnostic
  ))
}

write.csv(all_data, file.path(tables_dir, "r_historical_dynamics_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_historical_dynamics_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_historical_dynamics_comparison.png"), width = 1200, height = 700)
baseline <- all_data[all_data$scenario == "baseline_historical_dynamics", ]

plot(
  baseline$time,
  baseline$exponential,
  type = "l",
  lwd = 2,
  ylim = range(c(baseline$exponential, baseline$logistic, baseline$delayed_feedback)),
  xlab = "Time",
  ylab = "System State",
  main = "Historical Modeling Structures: Growth, Constraint, and Delayed Feedback"
)
lines(baseline$time, baseline$logistic, lwd = 2, lty = 2)
lines(baseline$time, baseline$delayed_feedback, lwd = 2, lty = 3)
abline(h = 55, lty = 4)
legend(
  "topleft",
  legend = c("Exponential", "Logistic", "Delayed feedback", "Target"),
  lwd = c(2, 2, 2, 1),
  lty = c(1, 2, 3, 4),
  bty = "n"
)
grid()
dev.off()

png(file.path(figures_dir, "r_delay_scenario_comparison.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$time),
  ylim = range(all_data$delayed_feedback),
  xlab = "Time",
  ylab = "Delayed Feedback State",
  main = "Delay Scenarios in Historical Dynamic Modeling"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$delayed_feedback, lwd = 2)
}

legend("topright", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

print(summary_rows)
cat("R historical systems modeling diagnostics complete.\n")
