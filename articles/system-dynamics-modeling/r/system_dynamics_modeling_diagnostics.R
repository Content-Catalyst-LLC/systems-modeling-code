# system_dynamics_modeling_diagnostics.R
# Base R workflow:
# stock-flow dynamics, feedback, delay, thresholds, and scenario diagnostics.

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

simulate_sd <- function(row, periods = 160) {
  time <- 0:periods
  stock <- numeric(length(time))
  delayed_stock <- numeric(length(time))
  inflow <- numeric(length(time))
  outflow <- numeric(length(time))
  threshold_penalty <- numeric(length(time))
  shock <- numeric(length(time))

  stock[1] <- 20

  for (t in 2:length(time)) {
    delayed_index <- max(1, t - row$delay)
    delayed_stock[t] <- stock[delayed_index]

    inflow[t] <- row$growth_rate * stock[t - 1] * (1 - stock[t - 1] / row$capacity)
    outflow[t] <- row$balancing_strength * max(delayed_stock[t] - row$target, 0)

    if (stock[t - 1] >= row$threshold) {
      threshold_penalty[t] <- row$threshold_correction * (stock[t - 1] - row$threshold)
    }

    if ((t - 1) == row$shock_time) {
      shock[t] <- row$shock_size
    }

    stock[t] <- max(0, min(250, stock[t - 1] + inflow[t] - outflow[t] - threshold_penalty[t] + shock[t]))
  }

  data.frame(
    scenario = row$scenario,
    time = time,
    stock = stock,
    delayed_stock = delayed_stock,
    inflow = inflow,
    outflow = outflow,
    threshold_penalty = threshold_penalty,
    shock = shock
  )
}

all_data <- data.frame()

for (i in seq_len(nrow(scenario_params))) {
  all_data <- rbind(all_data, simulate_sd(scenario_params[i, ]))
}

scenario_names <- unique(all_data$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]

  maximum_stock <- max(subset_data$stock)
  minimum_stock <- min(subset_data$stock)
  final_stock <- tail(subset_data$stock, 1)
  average_stock <- mean(subset_data$stock)
  time_to_peak <- subset_data$time[which.max(subset_data$stock)]
  threshold_active_periods <- sum(subset_data$threshold_penalty > 0)
  maximum_inflow <- max(subset_data$inflow)
  maximum_outflow <- max(subset_data$outflow)

  diagnostic <- ifelse(
    maximum_stock > 125,
    "large overshoot from reinforcing growth and delayed correction",
    ifelse(
      threshold_active_periods > 45,
      "persistent nonlinear threshold pressure",
      ifelse(
        maximum_outflow > maximum_inflow,
        "balancing feedback eventually dominates reinforcing inflow",
        "contained trajectory under current assumptions"
      )
    )
  )

  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    minimum_stock = minimum_stock,
    maximum_stock = maximum_stock,
    final_stock = final_stock,
    average_stock = average_stock,
    time_to_peak = time_to_peak,
    maximum_inflow = maximum_inflow,
    maximum_outflow = maximum_outflow,
    threshold_active_periods = threshold_active_periods,
    diagnostic = diagnostic
  ))
}

write.csv(all_data, file.path(tables_dir, "r_system_dynamics_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_system_dynamics_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_system_dynamics_stock_trajectories.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$time),
  ylim = range(all_data$stock),
  xlab = "Time",
  ylab = "Stock",
  main = "System Dynamics Stock Trajectories Across Scenarios"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$stock, lwd = 2)
}

legend("topright", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

png(file.path(figures_dir, "r_system_dynamics_feedback_components.png"), width = 1200, height = 700)
baseline <- all_data[all_data$scenario == "baseline_system_dynamics", ]

plot(
  baseline$time,
  baseline$stock,
  type = "l",
  lwd = 2,
  ylim = range(c(baseline$stock, baseline$inflow, baseline$outflow, baseline$threshold_penalty)),
  xlab = "Time",
  ylab = "Value",
  main = "Feedback Components in Baseline System Dynamics Scenario"
)
lines(baseline$time, baseline$inflow, lty = 2, lwd = 2)
lines(baseline$time, baseline$outflow, lty = 3, lwd = 2)
lines(baseline$time, baseline$threshold_penalty, lty = 4, lwd = 2)
legend(
  "topright",
  legend = c("Stock", "Inflow", "Outflow", "Threshold penalty"),
  lty = c(1, 2, 3, 4),
  lwd = 2,
  bty = "n"
)
grid()
dev.off()

print(summary_rows)
cat("R system dynamics diagnostics complete.\n")
