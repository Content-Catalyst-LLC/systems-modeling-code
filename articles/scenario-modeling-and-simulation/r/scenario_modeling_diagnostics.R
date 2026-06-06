# scenario_modeling_diagnostics.R
# Base R workflow:
# comparing alternative futures in a dynamic system.

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

scenario_definitions <- read.csv(file.path(data_dir, "scenario_definitions.csv"), stringsAsFactors = FALSE)

simulate_scenario <- function(
  scenario,
  growth,
  policy_drag,
  shock_time = 0,
  shock_size = 0,
  resilience_investment = 0,
  steps = 80,
  x0 = 20
) {
  state <- numeric(steps)
  capacity_buffer <- numeric(steps)
  stress_index <- numeric(steps)

  state[1] <- x0
  capacity_buffer[1] <- 5 + resilience_investment
  stress_index[1] <- state[1] / capacity_buffer[1]

  for (t in 2:steps) {
    shock_effect <- 0

    if (shock_time > 0 && t == shock_time) {
      shock_effect <- shock_size / max(1, capacity_buffer[t - 1])
    }

    state[t] <- state[t - 1] +
      growth * state[t - 1] -
      policy_drag * state[t - 1] -
      shock_effect

    capacity_buffer[t] <- capacity_buffer[t - 1] +
      0.04 * resilience_investment -
      0.01 * max(state[t] - 40, 0)

    capacity_buffer[t] <- max(capacity_buffer[t], 1)
    state[t] <- max(state[t], 0)
    stress_index[t] <- state[t] / capacity_buffer[t]
  }

  data.frame(
    scenario = scenario,
    time = seq_len(steps),
    state = state,
    capacity_buffer = capacity_buffer,
    stress_index = stress_index,
    growth = growth,
    policy_drag = policy_drag,
    shock_time = shock_time,
    shock_size = shock_size,
    resilience_investment = resilience_investment
  )
}

all_data <- data.frame()

for (i in seq_len(nrow(scenario_definitions))) {
  row <- scenario_definitions[i, ]
  all_data <- rbind(
    all_data,
    simulate_scenario(
      scenario = row$scenario,
      growth = row$growth,
      policy_drag = row$policy_drag,
      shock_time = row$shock_time,
      shock_size = row$shock_size,
      resilience_investment = row$resilience_investment
    )
  )
}

scenario_names <- unique(all_data$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]

  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    final_state = tail(subset_data$state, 1),
    maximum_state = max(subset_data$state),
    minimum_state = min(subset_data$state),
    final_capacity_buffer = tail(subset_data$capacity_buffer, 1),
    maximum_stress_index = max(subset_data$stress_index),
    final_stress_index = tail(subset_data$stress_index, 1),
    diagnostic = ifelse(
      max(subset_data$stress_index) > 10,
      "high stress under scenario assumptions",
      "stress contained under scenario assumptions"
    )
  ))
}

write.csv(all_data, file.path(tables_dir, "r_scenario_trajectories.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_scenario_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_scenario_state_trajectories.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$time),
  ylim = range(all_data$state),
  xlab = "Time",
  ylab = "System State",
  main = "Scenario Modeling Across Alternative Futures"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$state, lwd = 2)
}

legend("topleft", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

print(summary_rows)
cat("R scenario modeling diagnostics complete.\n")
