# early_warning_signals_diagnostics.R
# Base R workflow:
# detecting rising variance and lag-1 autocorrelation in a destabilizing system.

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

set.seed(42)

lag1_autocorrelation <- function(values) {
  if (length(values) < 3 || sd(values) == 0) {
    return(NA_real_)
  }

  suppressWarnings(cor(values[-length(values)], values[-1]))
}

rolling_stat <- function(values, window, fn) {
  result <- rep(NA_real_, length(values))

  for (i in seq_along(values)) {
    if (i >= window) {
      result[i] <- fn(values[(i - window + 1):i])
    }
  }

  result
}

simulate_warning_series <- function(
  scenario,
  n_steps = 320,
  stability_start = 0.55,
  stability_end = 0.985,
  noise_sd = 1.0,
  window = 25
) {
  state <- numeric(n_steps)
  stability <- seq(stability_start, stability_end, length.out = n_steps)

  for (t in 2:n_steps) {
    state[t] <- stability[t] * state[t - 1] + rnorm(1, 0, noise_sd)
  }

  rolling_variance <- rolling_stat(state, window, var)
  rolling_ac1 <- rolling_stat(state, window, lag1_autocorrelation)

  data.frame(
    scenario = scenario,
    time = seq_len(n_steps),
    state = state,
    absolute_state = abs(state),
    stability = stability,
    noise_sd = noise_sd,
    window = window,
    rolling_variance = rolling_variance,
    rolling_autocorrelation = rolling_ac1
  )
}

runs <- rbind(
  simulate_warning_series("baseline_destabilization", stability_start = 0.55, stability_end = 0.985, noise_sd = 1.0, window = 25),
  simulate_warning_series("moderate_destabilization", stability_start = 0.45, stability_end = 0.90, noise_sd = 1.0, window = 25),
  simulate_warning_series("high_noise_destabilization", stability_start = 0.55, stability_end = 0.985, noise_sd = 1.4, window = 25),
  simulate_warning_series("low_noise_destabilization", stability_start = 0.55, stability_end = 0.985, noise_sd = 0.65, window = 25),
  simulate_warning_series("short_window", stability_start = 0.55, stability_end = 0.985, noise_sd = 1.0, window = 15),
  simulate_warning_series("long_window", stability_start = 0.55, stability_end = 0.985, noise_sd = 1.0, window = 45)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  valid_variance <- subset_data[!is.na(subset_data$rolling_variance), ]
  valid_ac1 <- subset_data[!is.na(subset_data$rolling_autocorrelation), ]

  variance_slope <- coef(lm(rolling_variance ~ time, data = valid_variance))[2]
  ac1_slope <- coef(lm(rolling_autocorrelation ~ time, data = valid_ac1))[2]

  warning_label <- ifelse(
    variance_slope > 0 && ac1_slope > 0,
    "strengthening warning pattern",
    ifelse(variance_slope > 0 || ac1_slope > 0, "partial warning pattern", "mixed or weak warning pattern")
  )

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_stability = subset_data$stability[nrow(subset_data)],
      final_state = subset_data$state[nrow(subset_data)],
      maximum_abs_state = max(abs(subset_data$state)),
      final_rolling_variance = tail(na.omit(subset_data$rolling_variance), 1),
      final_rolling_autocorrelation = tail(na.omit(subset_data$rolling_autocorrelation), 1),
      variance_slope = variance_slope,
      autocorrelation_slope = ac1_slope,
      warning_label = warning_label
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_early_warning_indicator_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_early_warning_indicator_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_early_warning_indicators.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(runs$rolling_variance, na.rm = TRUE),
  xlab = "Time",
  ylab = "Rolling Variance",
  main = "Rolling Variance as an Early Warning Indicator"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$rolling_variance, lwd = 2)
}

legend(
  "topleft",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.7
)
grid()
dev.off()

print(summary_rows)
cat("R early warning signal diagnostics complete.\n")
