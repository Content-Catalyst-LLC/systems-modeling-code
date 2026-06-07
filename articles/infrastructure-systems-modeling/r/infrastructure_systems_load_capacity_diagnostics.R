# infrastructure_systems_load_capacity_diagnostics.R
# Base R workflow:
# simulating load, capacity, interdependence, and service disruption.

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

simulate_infrastructure_system <- function(
  scenario,
  n_steps = 80,
  initial_power_capacity = 100,
  initial_water_capacity = 90,
  power_demand_base = 78,
  water_demand_base = 58,
  demand_growth = 0.35,
  shock_start = 25,
  shock_end = 42,
  power_capacity_loss = 30,
  recovery_rate = 2.0,
  dependency_strength = 0.85
) {
  time <- seq_len(n_steps)

  power_capacity <- numeric(n_steps)
  water_capacity <- numeric(n_steps)
  power_demand <- numeric(n_steps)
  water_demand <- numeric(n_steps)
  power_availability <- numeric(n_steps)
  water_dependency_factor <- numeric(n_steps)
  unmet_power <- numeric(n_steps)
  unmet_water <- numeric(n_steps)
  total_unmet <- numeric(n_steps)

  power_capacity[1] <- initial_power_capacity

  for (t in seq_len(n_steps)) {
    if (t == 1) {
      power_capacity[t] <- initial_power_capacity
    } else {
      power_capacity[t] <- power_capacity[t - 1]
    }

    if (t >= shock_start && t <= shock_end) {
      power_capacity[t] <- max(0, initial_power_capacity - power_capacity_loss)
    }

    if (t > shock_end) {
      power_capacity[t] <- min(initial_power_capacity, power_capacity[t] + recovery_rate)
    }

    power_demand[t] <- power_demand_base + demand_growth * t
    water_demand[t] <- water_demand_base + 0.25 * demand_growth * t

    power_availability[t] <- min(1, power_capacity[t] / max(power_demand[t], 1))
    water_dependency_factor[t] <- (1 - dependency_strength) + dependency_strength * power_availability[t]
    water_capacity[t] <- initial_water_capacity * water_dependency_factor[t]

    unmet_power[t] <- max(power_demand[t] - power_capacity[t], 0)
    unmet_water[t] <- max(water_demand[t] - water_capacity[t], 0)
    total_unmet[t] <- unmet_power[t] + unmet_water[t]
  }

  data.frame(
    scenario = scenario,
    time = time,
    power_capacity = power_capacity,
    water_capacity = water_capacity,
    power_demand = power_demand,
    water_demand = water_demand,
    power_availability = power_availability,
    water_dependency_factor = water_dependency_factor,
    unmet_power = unmet_power,
    unmet_water = unmet_water,
    total_unmet = total_unmet
  )
}

runs <- rbind(
  simulate_infrastructure_system("baseline_shock"),
  simulate_infrastructure_system("larger_power_loss", power_capacity_loss = 45),
  simulate_infrastructure_system("faster_recovery", recovery_rate = 4.0),
  simulate_infrastructure_system("stronger_interdependence", dependency_strength = 1.0),
  simulate_infrastructure_system("lower_demand_growth", demand_growth = 0.18),
  simulate_infrastructure_system("resilient_backup", power_capacity_loss = 24, recovery_rate = 4.0, dependency_strength = 0.65)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      max_unmet_power = max(subset_data$unmet_power),
      max_unmet_water = max(subset_data$unmet_water),
      max_total_unmet = max(subset_data$total_unmet),
      total_unmet_service = sum(subset_data$total_unmet),
      minimum_power_availability = min(subset_data$power_availability),
      minimum_water_capacity = min(subset_data$water_capacity),
      diagnostic_label = ifelse(
        max(subset_data$total_unmet) > 25,
        "severe disruption pathway",
        "managed disruption pathway"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_infrastructure_load_capacity_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_infrastructure_load_capacity_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_infrastructure_service_disruption.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(runs$total_unmet),
  xlab = "Time",
  ylab = "Total Unmet Service",
  main = "Infrastructure Service Disruption Scenarios"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$total_unmet, lwd = 2)
}

legend(
  "topright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.75
)
grid()
dev.off()

print(summary_rows)
cat("R infrastructure systems load-capacity diagnostics complete.\n")
