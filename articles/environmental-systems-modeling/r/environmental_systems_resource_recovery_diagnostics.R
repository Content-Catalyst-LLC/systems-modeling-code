# environmental_systems_resource_recovery_diagnostics.R
# Base R workflow:
# simulating environmental resource pressure, disturbance, and recovery.

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

simulate_environmental_stock <- function(
  scenario,
  n_steps = 120,
  initial_stock = 70,
  carrying_capacity = 100,
  growth_rate = 0.065,
  extraction_rate = 0.040,
  restoration_rate = 0.010,
  disturbance_step = 65,
  disturbance_size = 12
) {
  time <- seq_len(n_steps)

  stock <- numeric(n_steps)
  regeneration <- numeric(n_steps)
  extraction <- numeric(n_steps)
  restoration <- numeric(n_steps)
  disturbance <- numeric(n_steps)
  resilience_index <- numeric(n_steps)

  stock[1] <- initial_stock
  resilience_index[1] <- stock[1] / carrying_capacity

  for (t in 2:n_steps) {
    regeneration[t - 1] <- growth_rate * stock[t - 1] * (1 - stock[t - 1] / carrying_capacity)
    extraction[t - 1] <- extraction_rate * stock[t - 1]
    restoration[t - 1] <- restoration_rate * (carrying_capacity - stock[t - 1])
    disturbance[t - 1] <- ifelse(t == disturbance_step, disturbance_size, 0)

    stock[t] <- max(
      0,
      min(
        carrying_capacity,
        stock[t - 1] + regeneration[t - 1] - extraction[t - 1] + restoration[t - 1] - disturbance[t - 1]
      )
    )

    resilience_index[t] <- stock[t] / carrying_capacity
  }

  regeneration[n_steps] <- growth_rate * stock[n_steps] * (1 - stock[n_steps] / carrying_capacity)
  extraction[n_steps] <- extraction_rate * stock[n_steps]
  restoration[n_steps] <- restoration_rate * (carrying_capacity - stock[n_steps])
  disturbance[n_steps] <- 0
  resilience_index[n_steps] <- stock[n_steps] / carrying_capacity

  data.frame(
    scenario = scenario,
    time = time,
    stock = stock,
    regeneration = regeneration,
    extraction = extraction,
    restoration = restoration,
    disturbance = disturbance,
    resilience_index = resilience_index
  )
}

runs <- rbind(
  simulate_environmental_stock("baseline_pressure"),
  simulate_environmental_stock("high_extraction", extraction_rate = 0.065),
  simulate_environmental_stock("restoration_investment", restoration_rate = 0.035),
  simulate_environmental_stock("larger_disturbance", disturbance_size = 24),
  simulate_environmental_stock("lower_growth", growth_rate = 0.040),
  simulate_environmental_stock("strong_intervention", restoration_rate = 0.020),
  simulate_environmental_stock("high_exposure_weight"),
  simulate_environmental_stock("low_flow_persistence")
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_stock = subset_data$stock[nrow(subset_data)],
      minimum_stock = min(subset_data$stock),
      maximum_stock = max(subset_data$stock),
      final_resilience_index = subset_data$resilience_index[nrow(subset_data)],
      average_extraction = mean(subset_data$extraction),
      average_restoration = mean(subset_data$restoration),
      diagnostic_label = ifelse(
        subset_data$resilience_index[nrow(subset_data)] >= 0.70,
        "recovering pathway",
        "degraded pathway"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_environmental_stock_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_environmental_stock_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_environmental_stock_trajectories.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = c(0, 100),
  xlab = "Time",
  ylab = "Environmental Stock",
  main = "Environmental Resource Pressure and Recovery"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$stock, lwd = 2)
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
cat("R environmental systems resource recovery diagnostics complete.\n")
