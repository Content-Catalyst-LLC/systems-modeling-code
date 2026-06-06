# agent_based_modeling_diagnostics.R
# Base R workflow:
# threshold adoption with heterogeneous agents and local network influence.

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

scenario_params <- read.csv(file.path(data_dir, "abm_threshold_scenarios.csv"), stringsAsFactors = FALSE)

simulate_threshold_adoption <- function(row) {
  set.seed(row$seed)

  n_agents <- row$n_agents
  n_steps <- row$n_steps
  thresholds <- runif(n_agents, row$threshold_low, row$threshold_high)
  adopted <- rep(FALSE, n_agents)
  adopted[sample(seq_len(n_agents), row$initial_adopters)] <- TRUE

  trajectory <- data.frame()

  for (time in seq_len(n_steps)) {
    previous <- adopted

    for (i in seq_len(n_agents)) {
      if (!previous[i]) {
        neighbor_ids <- c()

        for (offset in seq(-row$neighbor_radius, row$neighbor_radius)) {
          if (offset != 0) {
            neighbor <- ((i - 1 + offset) %% n_agents) + 1
            neighbor_ids <- c(neighbor_ids, neighbor)
          }
        }

        local_adoption_share <- mean(previous[neighbor_ids])

        if (local_adoption_share >= thresholds[i]) {
          adopted[i] <- TRUE
        }
      }
    }

    trajectory <- rbind(trajectory, data.frame(
      scenario = row$scenario,
      time = time,
      adoption_rate = mean(adopted),
      new_adopters = sum(adopted) - sum(previous),
      mean_threshold = mean(thresholds),
      threshold_low = row$threshold_low,
      threshold_high = row$threshold_high,
      neighbor_radius = row$neighbor_radius
    ))
  }

  trajectory
}

all_data <- data.frame()

for (i in seq_len(nrow(scenario_params))) {
  all_data <- rbind(all_data, simulate_threshold_adoption(scenario_params[i, ]))
}

scenario_names <- unique(all_data$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]

  if (any(subset_data$adoption_rate >= 0.5)) {
    time_to_half <- min(subset_data$time[subset_data$adoption_rate >= 0.5])
  } else {
    time_to_half <- NA
  }

  final_rate <- tail(subset_data$adoption_rate, 1)

  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    initial_adoption_rate = subset_data$adoption_rate[1],
    final_adoption_rate = final_rate,
    peak_new_adopters = max(subset_data$new_adopters),
    time_to_half_adoption = time_to_half,
    mean_threshold = unique(subset_data$mean_threshold)[1],
    diagnostic = ifelse(
      final_rate >= 0.8,
      "broad adoption emerged from local threshold dynamics",
      ifelse(
        final_rate >= 0.4,
        "partial adoption emerged under current assumptions",
        "adoption stalled under current assumptions"
      )
    )
  ))
}

write.csv(all_data, file.path(tables_dir, "r_abm_threshold_adoption_trajectory.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_abm_threshold_adoption_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_abm_threshold_adoption_trajectories.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$time),
  ylim = c(0, 1),
  xlab = "Time",
  ylab = "Adoption Rate",
  main = "Threshold Adoption Across Heterogeneous Agent Scenarios"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$adoption_rate, lwd = 2)
}

legend("bottomright", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

print(summary_rows)
cat("R agent-based modeling diagnostics complete.\n")
