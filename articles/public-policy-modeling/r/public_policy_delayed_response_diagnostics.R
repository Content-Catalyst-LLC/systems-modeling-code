# public_policy_delayed_response_diagnostics.R
# Base R workflow:
# simulating delayed policy response, institutional capacity, uptake, trust, and side effects.

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

simulate_policy_system <- function(
  scenario,
  n_steps = 100,
  initial_state = 12,
  initial_capacity = 7,
  initial_trust = 0.55,
  initial_burden = 0.28,
  policy_start = 15,
  policy_end = 55,
  policy_intensity = 1.25,
  policy_effect = 0.55,
  capacity_learning_rate = 0.08,
  burden_growth = 0.05,
  burden_reduction = 0.03,
  trust_gain = 0.015,
  trust_loss = 0.020,
  side_effect_rate = 0.08
) {
  time <- seq_len(n_steps)

  policy <- numeric(n_steps)
  system_state <- numeric(n_steps)
  institutional_capacity <- numeric(n_steps)
  trust <- numeric(n_steps)
  administrative_burden <- numeric(n_steps)
  uptake <- numeric(n_steps)
  side_effect <- numeric(n_steps)

  system_state[1] <- initial_state
  institutional_capacity[1] <- initial_capacity
  trust[1] <- initial_trust
  administrative_burden[1] <- initial_burden
  side_effect[1] <- 0

  for (t in 2:n_steps) {
    policy[t - 1] <- ifelse(t >= policy_start && t <= policy_end, policy_intensity, 0)

    uptake[t - 1] <- max(
      0,
      min(
        1,
        0.45 +
          0.30 * trust[t - 1] +
          0.04 * institutional_capacity[t - 1] -
          0.50 * administrative_burden[t - 1]
      )
    )

    system_state[t] <- system_state[t - 1] +
      policy_effect * policy[t - 1] * uptake[t - 1] -
      0.10 * system_state[t - 1] +
      0.04 * institutional_capacity[t - 1]

    institutional_capacity[t] <- institutional_capacity[t - 1] +
      capacity_learning_rate * (system_state[t - 1] - institutional_capacity[t - 1])

    administrative_burden[t] <- max(
      0,
      administrative_burden[t - 1] +
        burden_growth * policy[t - 1] -
        burden_reduction * institutional_capacity[t - 1] / 10
    )

    side_effect[t] <- max(
      0,
      side_effect[t - 1] +
        side_effect_rate * policy[t - 1] -
        0.06 * side_effect[t - 1]
    )

    trust[t] <- max(
      0,
      min(
        1,
        trust[t - 1] +
          trust_gain * uptake[t - 1] -
          trust_loss * administrative_burden[t]
      )
    )
  }

  policy[n_steps] <- ifelse(n_steps >= policy_start && n_steps <= policy_end, policy_intensity, 0)
  uptake[n_steps] <- max(
    0,
    min(
      1,
      0.45 +
        0.30 * trust[n_steps] +
        0.04 * institutional_capacity[n_steps] -
        0.50 * administrative_burden[n_steps]
    )
  )

  data.frame(
    scenario = scenario,
    time = time,
    policy = policy,
    system_state = system_state,
    institutional_capacity = institutional_capacity,
    trust = trust,
    administrative_burden = administrative_burden,
    uptake = uptake,
    side_effect = side_effect
  )
}

runs <- rbind(
  simulate_policy_system("baseline_policy"),
  simulate_policy_system("stronger_policy", policy_intensity = 1.75),
  simulate_policy_system("low_capacity_learning", capacity_learning_rate = 0.035),
  simulate_policy_system("high_burden_design", burden_growth = 0.10),
  simulate_policy_system("trust_centered_design", initial_trust = 0.70, burden_growth = 0.025, trust_gain = 0.025),
  simulate_policy_system("short_policy_window", policy_end = 35),
  simulate_policy_system("capacity_first_policy", initial_capacity = 9, initial_trust = 0.64, initial_burden = 0.20, capacity_learning_rate = 0.13, burden_growth = 0.030)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_system_state = subset_data$system_state[nrow(subset_data)],
      final_capacity = subset_data$institutional_capacity[nrow(subset_data)],
      final_trust = subset_data$trust[nrow(subset_data)],
      maximum_burden = max(subset_data$administrative_burden),
      average_uptake = mean(subset_data$uptake),
      maximum_side_effect = max(subset_data$side_effect),
      diagnostic_label = ifelse(
        max(subset_data$administrative_burden) > 1,
        "high burden policy pathway",
        "manageable policy pathway"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_public_policy_delayed_response_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_public_policy_delayed_response_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_public_policy_delayed_response.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(c(runs$system_state, runs$institutional_capacity, runs$side_effect)),
  xlab = "Time",
  ylab = "Policy System Value",
  main = "Delayed Policy Response and Institutional Capacity"
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
  cex = 0.75
)
grid()
dev.off()

print(summary_rows)
cat("R public policy delayed response diagnostics complete.\n")
