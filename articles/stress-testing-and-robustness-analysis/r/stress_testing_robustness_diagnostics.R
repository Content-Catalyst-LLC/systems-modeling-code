# stress_testing_robustness_diagnostics.R
# Base R workflow:
# stress testing a dynamic capacity system.

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

simulate_capacity_system <- function(
  scenario_name,
  demand_growth,
  initial_capacity,
  capacity_loss,
  recovery_rate,
  shock_time,
  stress_duration,
  n_steps = 80
) {
  demand <- numeric(n_steps)
  capacity <- numeric(n_steps)
  unmet_demand <- numeric(n_steps)
  service_ratio <- numeric(n_steps)

  demand[1] <- 55
  capacity[1] <- initial_capacity
  unmet_demand[1] <- max(demand[1] - capacity[1], 0)
  service_ratio[1] <- ifelse(demand[1] == 0, 1, min(capacity[1] / demand[1], 1))

  for (t in 2:n_steps) {
    stress_active <- t >= shock_time && t < shock_time + stress_duration

    demand[t] <- demand[t - 1] * (1 + demand_growth)

    capacity_shock <- ifelse(t == shock_time, capacity_loss, 0)
    capacity[t] <- capacity[t - 1] - capacity_shock

    if (!stress_active && capacity[t] < initial_capacity) {
      capacity[t] <- capacity[t] + recovery_rate * (initial_capacity - capacity[t])
    }

    capacity[t] <- max(capacity[t], 0)
    unmet_demand[t] <- max(demand[t] - capacity[t], 0)
    service_ratio[t] <- ifelse(demand[t] == 0, 1, min(capacity[t] / demand[t], 1))
  }

  data.frame(
    scenario = scenario_name,
    time = seq_len(n_steps),
    demand = demand,
    capacity = capacity,
    unmet_demand = unmet_demand,
    service_ratio = service_ratio,
    failed = service_ratio < 0.85
  )
}

scenarios <- data.frame(
  scenario_name = c(
    "baseline",
    "moderate_capacity_loss",
    "severe_capacity_loss",
    "compound_high_demand_capacity_loss",
    "delayed_recovery"
  ),
  demand_growth = c(0.010, 0.012, 0.014, 0.025, 0.018),
  initial_capacity = c(100, 100, 100, 100, 100),
  capacity_loss = c(0, 18, 35, 35, 30),
  recovery_rate = c(0.18, 0.16, 0.14, 0.12, 0.04),
  shock_time = c(40, 35, 35, 32, 32),
  stress_duration = c(1, 8, 10, 14, 18),
  stringsAsFactors = FALSE
)

all_runs <- data.frame()

for (i in seq_len(nrow(scenarios))) {
  scenario <- scenarios[i, ]

  all_runs <- rbind(
    all_runs,
    simulate_capacity_system(
      scenario_name = scenario$scenario_name,
      demand_growth = scenario$demand_growth,
      initial_capacity = scenario$initial_capacity,
      capacity_loss = scenario$capacity_loss,
      recovery_rate = scenario$recovery_rate,
      shock_time = scenario$shock_time,
      stress_duration = scenario$stress_duration
    )
  )
}

summary_rows <- data.frame()

for (scenario_name in unique(all_runs$scenario)) {
  subset_data <- all_runs[all_runs$scenario == scenario_name, ]

  failure_times <- subset_data$time[subset_data$failed]
  first_failure_time <- ifelse(length(failure_times) == 0, NA, min(failure_times))

  if (is.na(first_failure_time)) {
    recovery_time <- NA
  } else {
    recovery_candidates <- subset_data$time[
      subset_data$time > first_failure_time &
        subset_data$service_ratio >= 0.95
    ]
    recovery_time <- ifelse(length(recovery_candidates) == 0, NA, min(recovery_candidates))
  }

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      minimum_service_ratio = min(subset_data$service_ratio),
      mean_service_ratio = mean(subset_data$service_ratio),
      maximum_unmet_demand = max(subset_data$unmet_demand),
      cumulative_unmet_demand = sum(subset_data$unmet_demand),
      failure_frequency = mean(subset_data$failed),
      first_failure_time = first_failure_time,
      recovery_time = recovery_time,
      robustness_status = ifelse(
        min(subset_data$service_ratio) >= 0.85,
        "passes service threshold",
        "fails service threshold"
      )
    )
  )
}

write.csv(scenarios, file.path(tables_dir, "r_stress_scenarios.csv"), row.names = FALSE)
write.csv(all_runs, file.path(tables_dir, "r_stress_test_trajectories.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_stress_test_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_stress_test_service_ratio.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(all_runs$time),
  ylim = c(0, 1),
  xlab = "Time",
  ylab = "Service Ratio",
  main = "Stress Testing Dynamic Service Capacity"
)

for (scenario_name in unique(all_runs$scenario)) {
  subset_data <- all_runs[all_runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$service_ratio, lwd = 2)
}

abline(h = 0.85, lty = 2)
legend(
  "bottomleft",
  legend = unique(all_runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.75
)
grid()
dev.off()

print(summary_rows)
cat("R stress testing and robustness diagnostics complete.\n")
