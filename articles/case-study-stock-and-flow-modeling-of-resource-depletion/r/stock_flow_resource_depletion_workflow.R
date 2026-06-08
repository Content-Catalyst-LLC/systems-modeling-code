# stock_flow_resource_depletion_workflow.R
# Base R workflow: resource stock, regeneration, extraction, conservation, and depletion diagnostics.

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

simulate_resource <- function(row) {
  periods <- row$periods
  stock <- numeric(periods + 1)
  stock[1] <- row$initial_stock
  reference_stock <- row$reference_stock_fraction * row$carrying_capacity
  critical_threshold <- row$critical_threshold_fraction * row$carrying_capacity
  rows <- data.frame()

  for (t in 0:(periods - 1)) {
    current_stock <- stock[t + 1]
    demand <- row$initial_demand * (1 + row$demand_growth) ^ t
    scarcity <- max(0, 1 - current_stock / reference_stock)
    conservation <- min(row$max_conservation, row$conservation_sensitivity * scarcity)
    effective_demand <- demand * (1 - conservation)
    regeneration <- row$regeneration_rate * current_stock * (1 - current_stock / row$carrying_capacity)
    regeneration <- max(0, regeneration)
    extraction_capacity <- row$extraction_efficiency * current_stock
    extraction <- min(effective_demand, extraction_capacity, current_stock + regeneration)
    unmet_demand <- max(0, demand - extraction)
    next_stock <- max(0, current_stock + regeneration - extraction)
    stock[t + 2] <- next_stock

    rows <- rbind(
      rows,
      data.frame(
        scenario = row$scenario,
        time = t,
        resource_stock = current_stock,
        demand = demand,
        scarcity = scarcity,
        conservation = conservation,
        regeneration = regeneration,
        extraction = extraction,
        unmet_demand = unmet_demand,
        critical_threshold = critical_threshold,
        below_critical_threshold = current_stock < critical_threshold,
        overshoot = extraction > regeneration
      )
    )
  }

  rows
}

all_runs <- data.frame()

for (i in seq_len(nrow(scenario_params))) {
  all_runs <- rbind(all_runs, simulate_resource(scenario_params[i, ]))
}

scenario_names <- unique(all_runs$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]
  threshold_times <- subset_rows$time[subset_rows$below_critical_threshold]
  threshold_crossing_time <- ifelse(length(threshold_times) == 0, NA, min(threshold_times))
  initial_stock <- subset_rows$resource_stock[1]
  final_stock <- subset_rows$resource_stock[nrow(subset_rows)]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      initial_stock = initial_stock,
      final_stock = final_stock,
      minimum_stock = min(subset_rows$resource_stock),
      depletion_ratio = 1 - final_stock / initial_stock,
      cumulative_extraction = sum(subset_rows$extraction),
      cumulative_regeneration = sum(subset_rows$regeneration),
      cumulative_unmet_demand = sum(subset_rows$unmet_demand),
      overshoot_periods = sum(subset_rows$overshoot),
      threshold_crossing_time = threshold_crossing_time
    )
  )
}

validation_checks <- data.frame(
  check = c("scenario_runs_created", "resource_stock_nonnegative", "extraction_nonnegative", "regeneration_nonnegative", "summary_created"),
  passed = c(
    nrow(all_runs) > 0,
    all(all_runs$resource_stock >= 0),
    all(all_runs$extraction >= 0),
    all(all_runs$regeneration >= 0),
    nrow(summary_rows) > 0
  )
)

write.csv(all_runs, file.path(tables_dir, "r_resource_depletion_scenario_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_resource_depletion_scenario_summary.csv"), row.names = FALSE)
write.csv(scenario_params, file.path(tables_dir, "r_resource_depletion_scenario_parameters.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_resource_depletion_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_resource_stock_scenarios.png"), width = 1000, height = 700)
plot(
  NULL,
  xlim = range(all_runs$time),
  ylim = c(0, max(scenario_params$carrying_capacity)),
  xlab = "Time",
  ylab = "Resource Stock",
  main = "Stock-and-Flow Resource Depletion Scenarios"
)
for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]
  lines(subset_rows$time, subset_rows$resource_stock, lwd = 2)
}
legend("topright", legend = scenario_names, lwd = 2, cex = 0.75)
grid()
dev.off()

print(summary_rows)
print(validation_checks)
cat("R stock-and-flow resource depletion workflow complete.\n")
