# climate_resilience_scenario_workflow.R
# Base R workflow: climate stress, service performance, recovery, degradation, adaptation, threshold risk.

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

scenarios <- read.csv(file.path(data_dir, "climate_resilience_scenarios.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(data_dir, "model_assumptions.csv"), stringsAsFactors = FALSE)
diagnostics <- read.csv(file.path(data_dir, "diagnostic_definitions.csv"), stringsAsFactors = FALSE)

threshold <- 0.55

clamp <- function(value) {
  max(0, min(1, value))
}

stress_value <- function(scenario_name, t) {
  base <- 0.28 + 0.004 * t

  if (scenario_name == "moderate_climate_stress") {
    return(base + ifelse(t %% 18 == 0, 0.16, 0))
  }

  if (scenario_name == "repeated_shocks") {
    return(base + ifelse(t %in% c(10, 15, 21, 33, 42), 0.34, 0))
  }

  if (scenario_name == "delayed_adaptation") {
    return(base + ifelse(t %in% c(12, 24, 36, 48), 0.30, 0))
  }

  if (scenario_name == "targeted_resilience_investment") {
    return(base + ifelse(t %in% c(14, 28, 44), 0.28, 0))
  }

  if (scenario_name == "compound_climate_stress") {
    return(base + 0.10 + ifelse(t %in% c(9, 17, 26, 34, 43, 52), 0.42, 0))
  }

  if (scenario_name == "transformation_pathway") {
    return(base + 0.08 + ifelse(t %in% c(13, 22, 31, 41, 50), 0.36, 0))
  }

  base
}

simulate_resilience <- function(row, periods = 60) {
  service <- 0.92
  adaptive_capacity <- row$initial_capacity
  degradation <- 0
  transformed <- 0
  rows <- data.frame()

  for (t in 0:periods) {
    stress <- stress_value(row$scenario, t)
    investment <- ifelse(t >= row$investment_start, row$investment_rate, 0)

    if (row$transformation_trigger == 1 && service < threshold && degradation > 0.18 && transformed == 0) {
      transformed <- 1
      adaptive_capacity <- clamp(adaptive_capacity + 0.10)
      service <- max(service, 0.62)
    }

    vulnerability_pressure <- row$exposure * row$sensitivity * stress * (1 - adaptive_capacity)
    recovery <- row$recovery_rate * (1 - service)
    service_next <- clamp(service - vulnerability_pressure + recovery)

    excess_stress <- max(0, stress - adaptive_capacity)
    degradation_next <- clamp(degradation + row$degradation_rate * excess_stress)
    capacity_next <- clamp(adaptive_capacity + investment - 0.018 * degradation_next)

    rows <- rbind(
      rows,
      data.frame(
        scenario = row$scenario,
        time = t,
        climate_stress = stress,
        service_level = service,
        adaptive_capacity = adaptive_capacity,
        degradation = degradation,
        vulnerability_pressure = vulnerability_pressure,
        recovery = recovery,
        adaptation_investment = investment,
        below_threshold = service < threshold,
        transformed = transformed,
        stringsAsFactors = FALSE
      )
    )

    service <- service_next
    degradation <- degradation_next
    adaptive_capacity <- capacity_next
  }

  rows
}

all_runs <- data.frame()

for (i in seq_len(nrow(scenarios))) {
  all_runs <- rbind(all_runs, simulate_resilience(scenarios[i, ]))
}

scenario_names <- unique(all_runs$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]

  average_service <- mean(subset_rows$service_level)
  minimum_service <- min(subset_rows$service_level)
  time_below_threshold <- sum(subset_rows$below_threshold)
  final_degradation <- subset_rows$degradation[nrow(subset_rows)]
  final_capacity <- subset_rows$adaptive_capacity[nrow(subset_rows)]
  threshold_crossings <- sum(diff(as.integer(subset_rows$below_threshold)) == 1)
  resilience_score <- average_service - 0.015 * time_below_threshold - 0.35 * final_degradation

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      average_service = average_service,
      minimum_service = minimum_service,
      time_below_threshold = time_below_threshold,
      threshold_crossings = threshold_crossings,
      final_adaptive_capacity = final_capacity,
      final_degradation = final_degradation,
      transformed = max(subset_rows$transformed),
      resilience_score = resilience_score,
      stringsAsFactors = FALSE
    )
  )
}

validation_checks <- data.frame(
  check = c(
    "scenario_runs_created",
    "service_level_normalized",
    "adaptive_capacity_normalized",
    "degradation_normalized",
    "climate_stress_nonnegative",
    "summary_created"
  ),
  passed = c(
    nrow(all_runs) > 0,
    all(all_runs$service_level >= 0 & all_runs$service_level <= 1),
    all(all_runs$adaptive_capacity >= 0 & all_runs$adaptive_capacity <= 1),
    all(all_runs$degradation >= 0 & all_runs$degradation <= 1),
    all(all_runs$climate_stress >= 0),
    nrow(summary_rows) > 0
  )
)

write.csv(scenarios, file.path(tables_dir, "r_climate_resilience_scenarios.csv"), row.names = FALSE)
write.csv(all_runs, file.path(tables_dir, "r_climate_resilience_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_climate_resilience_summary.csv"), row.names = FALSE)
write.csv(assumptions, file.path(tables_dir, "r_model_assumptions.csv"), row.names = FALSE)
write.csv(diagnostics, file.path(tables_dir, "r_diagnostic_definitions.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_climate_resilience_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_climate_resilience_service_curves.png"), width = 1000, height = 700)
plot(
  NULL,
  xlim = range(all_runs$time),
  ylim = c(0, 1),
  xlab = "Time",
  ylab = "Service Level",
  main = "Resilience Modeling Under Climate Stress"
)

for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]
  lines(subset_rows$time, subset_rows$service_level, lwd = 2)
}

abline(h = threshold, lty = 2)
legend("topright", legend = scenario_names, lwd = 2, cex = 0.70)
grid()
dev.off()

print(summary_rows)
print(validation_checks)
cat("R climate resilience scenario workflow complete.\n")
