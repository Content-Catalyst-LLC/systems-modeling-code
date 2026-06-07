# health_systems_capacity_backlog_diagnostics.R
# Base R workflow:
# simulating care demand, capacity, backlog, burnout, attrition, and prevention.

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

simulate_health_system <- function(
  scenario,
  n_steps = 120,
  initial_capacity = 100,
  initial_demand = 92,
  demand_growth = 0.35,
  prevention_effect = 0.015,
  workforce_recovery = 0.035,
  burnout_sensitivity = 0.085,
  attrition_sensitivity = 0.030,
  hiring_rate = 0.50,
  access_barrier = 0.18,
  surge_start = 45,
  surge_end = 65,
  surge_intensity = 18
) {
  time <- seq_len(n_steps)

  demand <- numeric(n_steps)
  effective_capacity <- numeric(n_steps)
  backlog <- numeric(n_steps)
  pressure <- numeric(n_steps)
  burnout <- numeric(n_steps)
  attrition <- numeric(n_steps)
  served <- numeric(n_steps)
  unmet_need <- numeric(n_steps)
  access_gap <- numeric(n_steps)

  effective_capacity[1] <- initial_capacity
  demand[1] <- initial_demand
  backlog[1] <- 0
  burnout[1] <- 0.12

  for (t in 2:n_steps) {
    surge <- ifelse(t >= surge_start && t <= surge_end, surge_intensity, 0)
    prevention_reduction <- prevention_effect * t

    demand[t] <- max(
      0,
      initial_demand +
        demand_growth * t +
        surge -
        prevention_reduction +
        0.08 * backlog[t - 1]
    )

    pressure[t - 1] <- demand[t - 1] / max(effective_capacity[t - 1], 1)

    burnout[t] <- max(
      0,
      burnout[t - 1] +
        burnout_sensitivity * max(pressure[t - 1] - 1, 0) -
        workforce_recovery * max(1 - pressure[t - 1], 0)
    )

    attrition[t - 1] <- attrition_sensitivity * burnout[t] * effective_capacity[t - 1]

    capacity_next <- max(
      0,
      effective_capacity[t - 1] +
        hiring_rate -
        attrition[t - 1] -
        0.10 * max(pressure[t - 1] - 1, 0) * effective_capacity[t - 1]
    )

    served[t - 1] <- min(demand[t - 1], capacity_next)
    unmet_need[t - 1] <- max(demand[t - 1] - served[t - 1], 0)
    access_gap[t - 1] <- access_barrier * demand[t - 1] + unmet_need[t - 1]

    backlog[t] <- max(0, backlog[t - 1] + demand[t - 1] - served[t - 1])
    effective_capacity[t] <- capacity_next
  }

  pressure[n_steps] <- demand[n_steps] / max(effective_capacity[n_steps], 1)
  attrition[n_steps] <- attrition_sensitivity * burnout[n_steps] * effective_capacity[n_steps]
  served[n_steps] <- min(demand[n_steps], effective_capacity[n_steps])
  unmet_need[n_steps] <- max(demand[n_steps] - served[n_steps], 0)
  access_gap[n_steps] <- access_barrier * demand[n_steps] + unmet_need[n_steps]

  data.frame(
    scenario = scenario,
    time = time,
    demand = demand,
    effective_capacity = effective_capacity,
    backlog = backlog,
    pressure = pressure,
    burnout = burnout,
    attrition = attrition,
    served = served,
    unmet_need = unmet_need,
    access_gap = access_gap
  )
}

runs <- rbind(
  simulate_health_system("baseline_health_system"),
  simulate_health_system("higher_demand_growth", demand_growth = 0.65),
  simulate_health_system("stronger_prevention", prevention_effect = 0.060),
  simulate_health_system("larger_surge", surge_intensity = 32),
  simulate_health_system("faster_hiring", hiring_rate = 1.20),
  simulate_health_system("higher_access_barrier", access_barrier = 0.32),
  simulate_health_system("resilient_prepared_system", initial_capacity = 108, initial_demand = 88, demand_growth = 0.28, prevention_effect = 0.055, workforce_recovery = 0.060, burnout_sensitivity = 0.060, attrition_sensitivity = 0.020, hiring_rate = 0.95, access_barrier = 0.12, surge_intensity = 14)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_capacity = subset_data$effective_capacity[nrow(subset_data)],
      final_backlog = subset_data$backlog[nrow(subset_data)],
      maximum_pressure = max(subset_data$pressure),
      maximum_burnout = max(subset_data$burnout),
      total_unmet_need = sum(subset_data$unmet_need),
      average_access_gap = mean(subset_data$access_gap),
      diagnostic_label = ifelse(
        max(subset_data$pressure) > 1.25 | sum(subset_data$unmet_need) > 1000,
        "high strain health system pathway",
        "manageable health system pathway"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_health_system_capacity_backlog_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_health_system_capacity_backlog_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_health_system_capacity_backlog.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(c(runs$demand, runs$effective_capacity)),
  xlab = "Time",
  ylab = "Health System Value",
  main = "Health System Demand and Capacity Scenarios"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$demand, lwd = 2)
}

legend(
  "topleft",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.75
)
grid()
dev.off()

print(summary_rows)
cat("R health systems capacity-backlog diagnostics complete.\n")
