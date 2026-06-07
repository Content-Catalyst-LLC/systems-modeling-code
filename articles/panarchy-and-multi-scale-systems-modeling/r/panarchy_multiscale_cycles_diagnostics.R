# panarchy_multiscale_cycles_diagnostics.R
# Base R workflow:
# simulating linked fast and slow adaptive cycles.

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

simulate_panarchy <- function(
  scenario,
  n_steps = 160,
  fast_growth = 0.16,
  fast_capacity = 3.2,
  slow_constraint = 0.08,
  release_threshold = 2.5,
  release_magnitude = 1.35,
  revolt_strength = 0.14,
  remember_strength = 0.035,
  slow_adjustment = 0.01,
  slow_target = 1.6
) {
  time <- seq_len(n_steps)
  fast_cycle <- numeric(n_steps)
  slow_memory <- numeric(n_steps)
  release_event <- numeric(n_steps)
  phase <- character(n_steps)

  fast_cycle[1] <- 0.5
  slow_memory[1] <- 1.0
  phase[1] <- "reorganization"

  for (t in 2:n_steps) {
    fast_cycle[t] <- fast_cycle[t - 1] +
      fast_growth * fast_cycle[t - 1] * (1 - fast_cycle[t - 1] / fast_capacity) -
      slow_constraint * slow_memory[t - 1]

    if (fast_cycle[t] > release_threshold) {
      fast_cycle[t] <- max(0, fast_cycle[t] - release_magnitude)
      slow_memory[t] <- slow_memory[t - 1] + revolt_strength
      release_event[t] <- 1
      phase[t] <- "release"
    } else {
      slow_memory[t] <- slow_memory[t - 1] +
        slow_adjustment * (slow_target - slow_memory[t - 1])

      if (fast_cycle[t] < 0.8) {
        phase[t] <- "reorganization"
      } else if (fast_cycle[t] < 2.0) {
        phase[t] <- "growth"
      } else {
        phase[t] <- "conservation"
      }
    }

    fast_cycle[t] <- max(0, fast_cycle[t] + remember_strength * slow_memory[t])
  }

  data.frame(
    scenario = scenario,
    time = time,
    fast_cycle = fast_cycle,
    slow_memory = slow_memory,
    release_event = release_event,
    phase = phase,
    cross_scale_coupling = fast_cycle * slow_memory
  )
}

runs <- rbind(
  simulate_panarchy(
    scenario = "baseline_panarchy"
  ),
  simulate_panarchy(
    scenario = "strong_revolt",
    revolt_strength = 0.24,
    release_threshold = 2.35
  ),
  simulate_panarchy(
    scenario = "strong_remember",
    remember_strength = 0.065,
    slow_adjustment = 0.014
  ),
  simulate_panarchy(
    scenario = "rigid_slow_structure",
    slow_constraint = 0.13,
    slow_adjustment = 0.004,
    remember_strength = 0.02
  ),
  simulate_panarchy(
    scenario = "weak_memory_high_volatility",
    remember_strength = 0.015,
    revolt_strength = 0.20,
    release_threshold = 2.30
  ),
  simulate_panarchy(
    scenario = "recurrent_release",
    fast_growth = 0.20,
    fast_capacity = 3.0,
    slow_constraint = 0.05,
    release_threshold = 2.20,
    release_magnitude = 1.15,
    revolt_strength = 0.16,
    remember_strength = 0.025
  )
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_fast_cycle = subset_data$fast_cycle[nrow(subset_data)],
      final_slow_memory = subset_data$slow_memory[nrow(subset_data)],
      release_events = sum(subset_data$release_event),
      maximum_fast_cycle = max(subset_data$fast_cycle),
      maximum_slow_memory = max(subset_data$slow_memory),
      mean_cross_scale_coupling = mean(subset_data$cross_scale_coupling),
      growth_periods = sum(subset_data$phase == "growth"),
      conservation_periods = sum(subset_data$phase == "conservation"),
      release_periods = sum(subset_data$phase == "release"),
      reorganization_periods = sum(subset_data$phase == "reorganization")
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_panarchy_multiscale_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_panarchy_multiscale_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_panarchy_multiscale_cycles.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(c(runs$fast_cycle, runs$slow_memory)),
  xlab = "Time",
  ylab = "State",
  main = "Linked Fast and Slow Adaptive Cycles"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$fast_cycle, lwd = 2)
}

legend(
  "topright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.7
)
grid()
dev.off()

print(summary_rows)
cat("R panarchy and multi-scale systems diagnostics complete.\n")
