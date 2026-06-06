# sensitivity_analysis_diagnostics.R
# Base R workflow:
# local and global sensitivity in a nonlinear systems model.

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

parameter_ranges <- read.csv(file.path(data_dir, "parameter_ranges.csv"), stringsAsFactors = FALSE)

range_value <- function(parameter, column) {
  parameter_ranges[parameter_ranges$parameter == parameter, column][1]
}

simulate_system <- function(
  growth_rate,
  carrying_capacity,
  extraction_pressure,
  recovery_delay,
  feedback_strength,
  shock_intensity,
  initial_state = 10,
  steps = 80
) {
  state <- numeric(steps)
  state[1] <- initial_state
  shock_time <- floor(steps / 2)

  for (t in 2:steps) {
    delay_index <- max(1, t - recovery_delay)
    delayed_recovery <- feedback_strength * state[delay_index]
    shock_effect <- ifelse(t == shock_time, shock_intensity, 0)

    state[t] <- state[t - 1] +
      growth_rate * state[t - 1] * (1 - state[t - 1] / carrying_capacity) -
      extraction_pressure * state[t - 1] +
      delayed_recovery -
      shock_effect

    state[t] <- max(state[t], 0)
  }

  data.frame(
    time = seq_len(steps),
    state = state,
    final_state = tail(state, 1),
    maximum_state = max(state),
    minimum_state = min(state),
    mean_state = mean(state)
  )
}

baseline <- list(
  growth_rate = range_value("growth_rate", "baseline"),
  carrying_capacity = range_value("carrying_capacity", "baseline"),
  extraction_pressure = range_value("extraction_pressure", "baseline"),
  recovery_delay = as.integer(range_value("recovery_delay", "baseline")),
  feedback_strength = range_value("feedback_strength", "baseline"),
  shock_intensity = range_value("shock_intensity", "baseline")
)

local_results <- data.frame()

for (i in seq_len(nrow(parameter_ranges))) {
  parameter <- parameter_ranges$parameter[i]
  minimum_value <- parameter_ranges$minimum[i]
  maximum_value <- parameter_ranges$maximum[i]

  if (parameter == "recovery_delay") {
    sampled_values <- seq(minimum_value, maximum_value, by = 1)
  } else {
    sampled_values <- seq(minimum_value, maximum_value, length.out = 41)
  }

  for (value in sampled_values) {
    settings <- baseline
    settings[[parameter]] <- ifelse(parameter == "recovery_delay", as.integer(value), value)

    result <- simulate_system(
      growth_rate = settings$growth_rate,
      carrying_capacity = settings$carrying_capacity,
      extraction_pressure = settings$extraction_pressure,
      recovery_delay = settings$recovery_delay,
      feedback_strength = settings$feedback_strength,
      shock_intensity = settings$shock_intensity
    )

    local_results <- rbind(local_results, data.frame(
      analysis_type = "local_one_at_a_time",
      parameter = parameter,
      value = value,
      final_state = tail(result$state, 1),
      maximum_state = max(result$state),
      minimum_state = min(result$state),
      mean_state = mean(result$state)
    ))
  }
}

set.seed(42)
n_runs <- 800

global_results <- data.frame(
  run_id = seq_len(n_runs),
  growth_rate = runif(n_runs, range_value("growth_rate", "minimum"), range_value("growth_rate", "maximum")),
  carrying_capacity = runif(n_runs, range_value("carrying_capacity", "minimum"), range_value("carrying_capacity", "maximum")),
  extraction_pressure = runif(n_runs, range_value("extraction_pressure", "minimum"), range_value("extraction_pressure", "maximum")),
  recovery_delay = sample(
    seq(range_value("recovery_delay", "minimum"), range_value("recovery_delay", "maximum")),
    n_runs,
    replace = TRUE
  ),
  feedback_strength = runif(n_runs, range_value("feedback_strength", "minimum"), range_value("feedback_strength", "maximum")),
  shock_intensity = runif(n_runs, range_value("shock_intensity", "minimum"), range_value("shock_intensity", "maximum"))
)

global_results$final_state <- NA
global_results$maximum_state <- NA
global_results$minimum_state <- NA
global_results$mean_state <- NA

for (i in seq_len(nrow(global_results))) {
  result <- simulate_system(
    growth_rate = global_results$growth_rate[i],
    carrying_capacity = global_results$carrying_capacity[i],
    extraction_pressure = global_results$extraction_pressure[i],
    recovery_delay = global_results$recovery_delay[i],
    feedback_strength = global_results$feedback_strength[i],
    shock_intensity = global_results$shock_intensity[i]
  )

  global_results$final_state[i] <- tail(result$state, 1)
  global_results$maximum_state[i] <- max(result$state)
  global_results$minimum_state[i] <- min(result$state)
  global_results$mean_state[i] <- mean(result$state)
}

parameter_names <- c(
  "growth_rate",
  "carrying_capacity",
  "extraction_pressure",
  "recovery_delay",
  "feedback_strength",
  "shock_intensity"
)

rank_summary <- data.frame()

for (parameter in parameter_names) {
  coefficient <- suppressWarnings(cor(global_results[[parameter]], global_results$final_state, method = "spearman"))
  if (is.na(coefficient)) coefficient <- 0

  rank_summary <- rbind(rank_summary, data.frame(
    parameter = parameter,
    spearman_correlation = coefficient,
    absolute_correlation = abs(coefficient),
    direction = ifelse(coefficient >= 0, "positive", "negative")
  ))
}

rank_summary <- rank_summary[order(-rank_summary$absolute_correlation), ]
rank_summary$sensitivity_rank <- seq_len(nrow(rank_summary))

write.csv(local_results, file.path(tables_dir, "r_local_sensitivity.csv"), row.names = FALSE)
write.csv(global_results, file.path(tables_dir, "r_global_sensitivity_runs.csv"), row.names = FALSE)
write.csv(rank_summary, file.path(tables_dir, "r_sensitivity_rank_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_local_growth_sensitivity.png"), width = 1000, height = 700)
growth_subset <- local_results[local_results$parameter == "growth_rate", ]
plot(
  growth_subset$value,
  growth_subset$final_state,
  type = "l",
  lwd = 2,
  xlab = "Growth Rate",
  ylab = "Final State",
  main = "Local Sensitivity to Growth Rate"
)
grid()
dev.off()

png(file.path(figures_dir, "r_global_sensitivity_scatter.png"), width = 1000, height = 700)
plot(
  global_results$growth_rate,
  global_results$final_state,
  pch = 16,
  cex = 0.6,
  xlab = "Growth Rate",
  ylab = "Final State",
  main = "Global Sensitivity: Growth Rate and Final State"
)
grid()
dev.off()

print(rank_summary)
cat("R sensitivity analysis diagnostics complete.\n")
