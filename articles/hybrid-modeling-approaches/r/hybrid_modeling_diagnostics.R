# hybrid_modeling_diagnostics.R
# Base R workflow:
# coupling aggregate feedback with heterogeneous adoption.

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

simulate_hybrid_adoption <- function(
  scenario,
  n_agents = 150,
  n_steps = 60,
  demand_initial = 0.30,
  growth_rate = 0.03,
  adoption_feedback = 0.25,
  saturation_pressure = 0.04,
  threshold_low = 0.20,
  threshold_high = 0.80,
  seed = 42
) {
  set.seed(seed)

  thresholds <- runif(n_agents, threshold_low, threshold_high)
  adopted <- rep(FALSE, n_agents)

  demand <- numeric(n_steps)
  adoption_rate <- numeric(n_steps)
  new_adopters <- numeric(n_steps)

  demand[1] <- demand_initial
  adoption_rate[1] <- mean(adopted)

  for (t in 2:n_steps) {
    previous <- adopted

    adopted <- adopted | (demand[t - 1] > thresholds)

    adoption_rate[t] <- mean(adopted)
    new_adopters[t] <- sum(adopted) - sum(previous)

    demand[t] <- demand[t - 1] +
      growth_rate * demand[t - 1] +
      adoption_feedback * adoption_rate[t] -
      saturation_pressure * demand[t - 1]^2

    demand[t] <- min(max(demand[t], 0), 1.5)
  }

  data.frame(
    scenario = scenario,
    time = seq_len(n_steps),
    demand = demand,
    adoption_rate = adoption_rate,
    new_adopters = new_adopters,
    mean_threshold = mean(thresholds),
    threshold_low = threshold_low,
    threshold_high = threshold_high,
    adoption_feedback = adoption_feedback,
    saturation_pressure = saturation_pressure
  )
}

all_data <- rbind(
  simulate_hybrid_adoption("baseline_hybrid_feedback", seed = 42),
  simulate_hybrid_adoption("weak_adoption_feedback", adoption_feedback = 0.10, seed = 43),
  simulate_hybrid_adoption("strong_adoption_feedback", adoption_feedback = 0.40, seed = 44),
  simulate_hybrid_adoption("low_threshold_population", threshold_low = 0.10, threshold_high = 0.50, seed = 45),
  simulate_hybrid_adoption("high_threshold_population", threshold_low = 0.45, threshold_high = 0.95, seed = 46)
)

scenario_names <- unique(all_data$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]

  if (any(subset_data$adoption_rate >= 0.5)) {
    time_to_half_adoption <- min(subset_data$time[subset_data$adoption_rate >= 0.5])
  } else {
    time_to_half_adoption <- NA
  }

  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    final_demand = tail(subset_data$demand, 1),
    final_adoption_rate = tail(subset_data$adoption_rate, 1),
    peak_new_adopters = max(subset_data$new_adopters),
    time_to_half_adoption = time_to_half_adoption,
    mean_threshold = unique(subset_data$mean_threshold)[1],
    diagnostic = ifelse(
      tail(subset_data$adoption_rate, 1) >= 0.8,
      "broad adoption emerged through aggregate-agent feedback",
      ifelse(
        tail(subset_data$adoption_rate, 1) >= 0.4,
        "partial adoption emerged under current coupling assumptions",
        "adoption stalled under current coupling assumptions"
      )
    )
  ))
}

write.csv(all_data, file.path(tables_dir, "r_hybrid_adoption_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_hybrid_adoption_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_hybrid_demand_adoption_trajectories.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$time),
  ylim = c(0, max(all_data$demand, all_data$adoption_rate)),
  xlab = "Time",
  ylab = "Value",
  main = "Hybrid Aggregate-Agent Feedback Across Scenarios"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$adoption_rate, lwd = 2)
}

legend("bottomright", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

print(summary_rows)
cat("R hybrid modeling diagnostics complete.\n")
