# critical_transitions_tipping_diagnostics.R
# Base R workflow:
# simulating tipping thresholds, hysteresis, and early-warning indicators.

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

update_state <- function(x, r, dt = 0.05) {
  x + dt * (r + x - x^3)
}

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

simulate_path <- function(path_name, scenario, r_values, initial_x, dt = 0.05, jump_threshold = 0.15) {
  x_values <- numeric(length(r_values))
  jump_size <- numeric(length(r_values))
  transition_flag <- numeric(length(r_values))

  x_values[1] <- initial_x

  for (i in 2:length(r_values)) {
    x_values[i] <- update_state(x_values[i - 1], r_values[i], dt = dt)
    jump_size[i] <- abs(x_values[i] - x_values[i - 1])
    transition_flag[i] <- ifelse(jump_size[i] > jump_threshold, 1, 0)
  }

  rolling_variance <- rolling_stat(x_values, 20, var)
  rolling_autocorrelation <- rolling_stat(x_values, 20, lag1_autocorrelation)

  data.frame(
    scenario = scenario,
    path = path_name,
    step = seq_along(r_values),
    control_parameter = r_values,
    system_state = x_values,
    jump_size = jump_size,
    transition_flag = transition_flag,
    rolling_variance_20 = rolling_variance,
    rolling_autocorrelation_20 = rolling_autocorrelation
  )
}

run_scenario <- function(
  scenario,
  forward_start,
  forward_end,
  steps,
  initial_state,
  dt,
  jump_threshold
) {
  r_forward <- seq(forward_start, forward_end, length.out = steps)
  forward_path <- simulate_path(
    "forward_forcing",
    scenario,
    r_forward,
    initial_x = initial_state,
    dt = dt,
    jump_threshold = jump_threshold
  )

  r_backward <- seq(forward_end, forward_start, length.out = steps)
  backward_path <- simulate_path(
    "backward_forcing",
    scenario,
    r_backward,
    initial_x = forward_path$system_state[nrow(forward_path)],
    dt = dt,
    jump_threshold = jump_threshold
  )

  rbind(forward_path, backward_path)
}

runs <- rbind(
  run_scenario("baseline_hysteresis", -1.20, 1.20, 300, -1.00, 0.050, 0.150),
  run_scenario("slow_forcing", -1.20, 1.20, 500, -1.00, 0.035, 0.120),
  run_scenario("fast_forcing", -1.20, 1.20, 150, -1.00, 0.075, 0.220),
  run_scenario("wide_forcing", -1.45, 1.45, 360, -1.10, 0.050, 0.150),
  run_scenario("near_threshold_start", -0.80, 1.20, 260, -0.60, 0.050, 0.130)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  scenario_data <- runs[runs$scenario == scenario_name, ]

  for (path_name in unique(scenario_data$path)) {
    subset_data <- scenario_data[scenario_data$path == path_name, ]
    transition_rows <- subset_data[subset_data$transition_flag == 1, ]

    transition_step <- ifelse(nrow(transition_rows) == 0, NA, transition_rows$step[1])
    transition_parameter <- ifelse(nrow(transition_rows) == 0, NA, transition_rows$control_parameter[1])

    summary_rows <- rbind(
      summary_rows,
      data.frame(
        scenario = scenario_name,
        path = path_name,
        initial_state = subset_data$system_state[1],
        final_state = subset_data$system_state[nrow(subset_data)],
        minimum_state = min(subset_data$system_state),
        maximum_state = max(subset_data$system_state),
        approximate_transition_step = transition_step,
        approximate_transition_parameter = transition_parameter,
        maximum_jump_size = max(subset_data$jump_size),
        maximum_rolling_variance_20 = max(subset_data$rolling_variance_20, na.rm = TRUE),
        maximum_rolling_autocorrelation_20 = max(subset_data$rolling_autocorrelation_20, na.rm = TRUE)
      )
    )
  }
}

write.csv(
  runs,
  file.path(tables_dir, "r_critical_transition_hysteresis_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_critical_transition_hysteresis_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_critical_transition_hysteresis.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$control_parameter),
  ylim = range(runs$system_state),
  xlab = "Control Parameter",
  ylab = "System State",
  main = "Critical Transition and Hysteresis"
)

for (path_name in unique(runs$path)) {
  subset_data <- runs[runs$path == path_name & runs$scenario == "baseline_hysteresis", ]
  lines(subset_data$control_parameter, subset_data$system_state, lwd = 2)
}

legend(
  "topleft",
  legend = unique(runs$path),
  lwd = 2,
  bty = "n",
  cex = 0.8
)
grid()
dev.off()

print(summary_rows)
cat("R critical-transition tipping diagnostics complete.\n")
