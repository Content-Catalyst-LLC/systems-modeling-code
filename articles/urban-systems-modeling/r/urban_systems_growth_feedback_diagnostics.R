# urban_systems_growth_feedback_diagnostics.R
# Base R workflow:
# simulating urban growth, accessibility, housing capacity, and congestion feedback.

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

simulate_urban_system <- function(
  scenario,
  n_steps = 100,
  initial_population = 100,
  initial_housing = 112,
  initial_transport = 90,
  initial_service_capacity = 120,
  accessibility_attraction = 1.25,
  congestion_penalty = 0.70,
  housing_constraint_penalty = 0.45,
  housing_build_rate = 0.65,
  transport_investment_rate = 0.45,
  service_investment_rate = 0.35,
  growth_pressure = 1.10
) {
  time <- seq_len(n_steps)

  population <- numeric(n_steps)
  housing <- numeric(n_steps)
  transport <- numeric(n_steps)
  service_capacity <- numeric(n_steps)
  accessibility <- numeric(n_steps)
  congestion <- numeric(n_steps)
  housing_gap <- numeric(n_steps)
  service_pressure <- numeric(n_steps)

  population[1] <- initial_population
  housing[1] <- initial_housing
  transport[1] <- initial_transport
  service_capacity[1] <- initial_service_capacity

  for (t in 2:n_steps) {
    accessibility[t - 1] <- transport[t - 1] / (1 + 0.010 * population[t - 1])
    congestion[t - 1] <- population[t - 1] / max(transport[t - 1], 1)
    housing_gap[t - 1] <- max(population[t - 1] - housing[t - 1], 0)
    service_pressure[t - 1] <- population[t - 1] / max(service_capacity[t - 1], 1)

    population[t] <- max(
      0,
      population[t - 1] +
        growth_pressure +
        accessibility_attraction * accessibility[t - 1] / 55 -
        congestion_penalty * max(congestion[t - 1] - 1, 0) -
        housing_constraint_penalty * housing_gap[t - 1] / 20 -
        0.70 * max(service_pressure[t - 1] - 1, 0)
    )

    housing[t] <- max(
      0,
      housing[t - 1] +
        housing_build_rate +
        0.020 * population[t] -
        0.004 * housing[t - 1]
    )

    transport[t] <- max(
      1,
      transport[t - 1] +
        transport_investment_rate +
        0.010 * housing[t] -
        0.030 * max(congestion[t - 1] - 1, 0)
    )

    service_capacity[t] <- max(
      1,
      service_capacity[t - 1] +
        service_investment_rate -
        0.003 * service_capacity[t - 1]
    )
  }

  accessibility[n_steps] <- transport[n_steps] / (1 + 0.010 * population[n_steps])
  congestion[n_steps] <- population[n_steps] / max(transport[n_steps], 1)
  housing_gap[n_steps] <- max(population[n_steps] - housing[n_steps], 0)
  service_pressure[n_steps] <- population[n_steps] / max(service_capacity[n_steps], 1)

  data.frame(
    scenario = scenario,
    time = time,
    population = population,
    housing = housing,
    transport = transport,
    service_capacity = service_capacity,
    accessibility = accessibility,
    congestion = congestion,
    housing_gap = housing_gap,
    service_pressure = service_pressure
  )
}

runs <- rbind(
  simulate_urban_system("baseline_growth"),
  simulate_urban_system("high_accessibility_attraction", accessibility_attraction = 1.75),
  simulate_urban_system("congestion_sensitive", congestion_penalty = 1.10),
  simulate_urban_system("housing_constraint", housing_build_rate = 0.25),
  simulate_urban_system("transport_investment", transport_investment_rate = 1.15, service_investment_rate = 0.85),
  simulate_urban_system("managed_growth", initial_housing = 118, initial_transport = 95, initial_service_capacity = 130, housing_build_rate = 1.05, transport_investment_rate = 0.90, service_investment_rate = 0.80, growth_pressure = 1.00)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_population = subset_data$population[nrow(subset_data)],
      final_housing = subset_data$housing[nrow(subset_data)],
      final_transport = subset_data$transport[nrow(subset_data)],
      final_service_capacity = subset_data$service_capacity[nrow(subset_data)],
      final_accessibility = subset_data$accessibility[nrow(subset_data)],
      final_congestion = subset_data$congestion[nrow(subset_data)],
      maximum_housing_gap = max(subset_data$housing_gap),
      maximum_service_pressure = max(subset_data$service_pressure),
      diagnostic_label = ifelse(
        max(subset_data$housing_gap) > 10 | max(subset_data$service_pressure) > 1,
        "capacity constrained pathway",
        "managed growth pathway"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_urban_growth_feedback_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_urban_growth_feedback_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_urban_growth_feedback_trajectories.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(c(runs$population, runs$housing, runs$transport)),
  xlab = "Time",
  ylab = "Urban System Value",
  main = "Urban Growth, Housing, and Transport Feedback"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$population, lwd = 2)
}

legend(
  "bottomright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.75
)
grid()
dev.off()

print(summary_rows)
cat("R urban systems growth feedback diagnostics complete.\n")
