# nonlinearity_threshold_regime_diagnostics.R
# Base R workflow:
# simulating nonlinear response, threshold crossing, hysteresis, and regime change.

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

rolling_stat <- function(values, window, fn) {
  result <- rep(NA_real_, length(values))

  for (i in seq_along(values)) {
    if (i >= window) {
      result[i] <- fn(values[(i - window + 1):i])
    }
  }

  result
}

lag1_autocorrelation <- function(values) {
  if (length(values) < 3 || sd(values) == 0) {
    return(NA_real_)
  }

  suppressWarnings(cor(values[-length(values)], values[-1]))
}

simulate_regime_system <- function(
  scenario,
  collapse_threshold,
  recovery_threshold,
  intervention_time,
  pressure_growth,
  recovery_effort,
  n_steps = 140
) {
  system_state <- numeric(n_steps)
  pressure <- numeric(n_steps)
  regime <- character(n_steps)
  damage_flow <- numeric(n_steps)
  recovery_flow <- numeric(n_steps)

  system_state[1] <- 82
  pressure[1] <- 20
  regime[1] <- "stable"

  for (t in 2:n_steps) {
    pressure[t] <- pressure[t - 1] + pressure_growth

    if (t >= intervention_time) {
      pressure[t] <- max(0, pressure[t] - recovery_effort)
    }

    previous_regime <- regime[t - 1]

    if (previous_regime == "stable" && pressure[t] >= collapse_threshold) {
      regime[t] <- "degraded"
    } else if (previous_regime == "degraded" && pressure[t] <= recovery_threshold) {
      regime[t] <- "stable"
    } else {
      regime[t] <- previous_regime
    }

    if (regime[t] == "stable") {
      damage_flow[t] <- 0.05 * pressure[t] + 0.002 * pressure[t]^2
      recovery_flow[t] <- 2.6
    } else {
      damage_flow[t] <- 0.09 * pressure[t] + 0.006 * pressure[t]^2 + 1.8
      recovery_flow[t] <- 0.8 + 0.03 * system_state[t - 1]
    }

    system_state[t] <- max(
      0,
      min(
        100,
        system_state[t - 1] +
          recovery_flow[t] -
          damage_flow[t]
      )
    )
  }

  variance_12 <- rolling_stat(system_state, 12, var)
  autocorrelation_12 <- rolling_stat(system_state, 12, lag1_autocorrelation)

  data.frame(
    scenario = scenario,
    time = seq_len(n_steps),
    system_state = system_state,
    pressure = pressure,
    regime = regime,
    collapse_threshold = collapse_threshold,
    recovery_threshold = recovery_threshold,
    hysteresis_gap = collapse_threshold - recovery_threshold,
    damage_flow = damage_flow,
    recovery_flow = recovery_flow,
    net_flow = recovery_flow - damage_flow,
    rolling_variance_12 = variance_12,
    rolling_autocorrelation_12 = autocorrelation_12
  )
}

runs <- rbind(
  simulate_regime_system("early_intervention", 70, 45, 55, 0.85, 1.20),
  simulate_regime_system("late_intervention", 70, 45, 85, 0.85, 1.20),
  simulate_regime_system("strong_recovery", 70, 45, 85, 0.85, 2.00),
  simulate_regime_system("lower_threshold_stress", 58, 38, 70, 0.95, 1.20),
  simulate_regime_system("high_resilience_buffer", 82, 52, 80, 0.80, 1.30),
  simulate_regime_system("hysteresis_trap", 66, 30, 88, 0.90, 1.30),
  simulate_regime_system("rapid_prevention", 70, 45, 40, 0.85, 1.80)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  degraded_times <- subset_data$time[subset_data$regime == "degraded"]
  first_degraded <- ifelse(length(degraded_times) == 0, NA, min(degraded_times))
  final_regime <- subset_data$regime[nrow(subset_data)]

  rolling_variance_values <- subset_data$rolling_variance_12[!is.na(subset_data$rolling_variance_12)]
  rolling_autocorr_values <- subset_data$rolling_autocorrelation_12[!is.na(subset_data$rolling_autocorrelation_12)]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      initial_state = subset_data$system_state[1],
      final_state = subset_data$system_state[nrow(subset_data)],
      minimum_state = min(subset_data$system_state),
      maximum_pressure = max(subset_data$pressure),
      collapse_threshold = subset_data$collapse_threshold[1],
      recovery_threshold = subset_data$recovery_threshold[1],
      hysteresis_gap = subset_data$hysteresis_gap[1],
      first_degraded_time = first_degraded,
      degraded_periods = sum(subset_data$regime == "degraded"),
      final_regime = final_regime,
      mean_net_flow = mean(subset_data$net_flow),
      maximum_rolling_variance_12 = ifelse(length(rolling_variance_values) == 0, NA, max(rolling_variance_values)),
      maximum_rolling_autocorrelation_12 = ifelse(length(rolling_autocorr_values) == 0, NA, max(rolling_autocorr_values))
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_nonlinear_regime_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_nonlinear_regime_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_nonlinear_regime_trajectories.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(runs$system_state),
  xlab = "Time",
  ylab = "System State",
  main = "Nonlinear Thresholds and Regime Change"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$system_state, lwd = 2)
}

legend(
  "topright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.65
)
grid()
dev.off()

print(summary_rows)
cat("R nonlinearity, threshold, and regime-change diagnostics complete.\n")
