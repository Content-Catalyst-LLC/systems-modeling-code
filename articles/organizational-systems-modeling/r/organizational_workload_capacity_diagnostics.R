# organizational_workload_capacity_diagnostics.R
# Base R workflow:
# simulating workload, capacity, learning, burnout, attrition, and delivery pressure.

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

simulate_organization <- function(
  scenario,
  n_steps = 100,
  initial_capacity = 100,
  initial_workload = 95,
  demand_growth = 0.45,
  hiring_rate = 0.60,
  onboarding_delay = 6,
  learning_rate = 0.030,
  burnout_sensitivity = 0.090,
  recovery_rate = 0.040,
  attrition_sensitivity = 0.035,
  coordination_burden = 0.10
) {
  time <- seq_len(n_steps)

  capacity <- numeric(n_steps)
  workload <- numeric(n_steps)
  backlog <- numeric(n_steps)
  pressure <- numeric(n_steps)
  burnout <- numeric(n_steps)
  learning <- numeric(n_steps)
  attrition <- numeric(n_steps)
  delivery <- numeric(n_steps)

  capacity[1] <- initial_capacity
  workload[1] <- initial_workload
  backlog[1] <- 0
  burnout[1] <- 0.10

  hiring_pipeline <- rep(0, onboarding_delay + 1)

  for (t in 2:n_steps) {
    hiring_pipeline <- c(hiring_pipeline[-1], hiring_rate)
    onboarded_capacity <- hiring_pipeline[1]

    pressure[t - 1] <- workload[t - 1] / max(capacity[t - 1], 1)
    slack <- max(1 - pressure[t - 1], 0)

    learning[t - 1] <- learning_rate * capacity[t - 1] * slack
    burnout[t] <- max(
      0,
      burnout[t - 1] +
        burnout_sensitivity * max(pressure[t - 1] - 1, 0) -
        recovery_rate * slack
    )

    attrition[t - 1] <- attrition_sensitivity * burnout[t] * capacity[t - 1]

    effective_capacity <- max(
      0,
      capacity[t - 1] +
        onboarded_capacity +
        learning[t - 1] -
        attrition[t - 1] -
        coordination_burden * max(pressure[t - 1] - 1, 0) * capacity[t - 1]
    )

    delivery[t - 1] <- min(workload[t - 1], effective_capacity)
    backlog[t] <- max(0, backlog[t - 1] + workload[t - 1] - delivery[t - 1])

    workload[t] <- initial_workload + demand_growth * t + 0.10 * backlog[t]
    capacity[t] <- effective_capacity
  }

  pressure[n_steps] <- workload[n_steps] / max(capacity[n_steps], 1)
  learning[n_steps] <- learning_rate * capacity[n_steps] * max(1 - pressure[n_steps], 0)
  attrition[n_steps] <- attrition_sensitivity * burnout[n_steps] * capacity[n_steps]
  delivery[n_steps] <- min(workload[n_steps], capacity[n_steps])

  data.frame(
    scenario = scenario,
    time = time,
    capacity = capacity,
    workload = workload,
    backlog = backlog,
    pressure = pressure,
    burnout = burnout,
    learning = learning,
    attrition = attrition,
    delivery = delivery
  )
}

runs <- rbind(
  simulate_organization("baseline_organization"),
  simulate_organization("high_demand_growth", demand_growth = 0.85),
  simulate_organization("faster_hiring", hiring_rate = 1.20),
  simulate_organization("slow_onboarding", onboarding_delay = 14),
  simulate_organization("learning_investment", learning_rate = 0.065),
  simulate_organization("high_coordination_burden", coordination_burden = 0.22),
  simulate_organization("resilient_learning_system", initial_capacity = 105, initial_workload = 92, demand_growth = 0.38, hiring_rate = 0.85, learning_rate = 0.075, burnout_sensitivity = 0.060, recovery_rate = 0.065, attrition_sensitivity = 0.025, coordination_burden = 0.07)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_capacity = subset_data$capacity[nrow(subset_data)],
      final_workload = subset_data$workload[nrow(subset_data)],
      final_backlog = subset_data$backlog[nrow(subset_data)],
      maximum_pressure = max(subset_data$pressure),
      maximum_burnout = max(subset_data$burnout),
      total_attrition = sum(subset_data$attrition),
      average_delivery = mean(subset_data$delivery),
      diagnostic_label = ifelse(
        max(subset_data$pressure) > 1.25 | max(subset_data$burnout) > 0.60,
        "unsustainable operating pathway",
        "manageable operating pathway"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_organizational_workload_capacity_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_organizational_workload_capacity_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_organizational_workload_capacity.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(c(runs$capacity, runs$workload)),
  xlab = "Time",
  ylab = "Organizational System Value",
  main = "Organizational Workload and Capacity Scenarios"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$workload, lwd = 2)
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
cat("R organizational workload-capacity diagnostics complete.\n")
