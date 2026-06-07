# cascading_failure_network_workflow.R
# Base R workflow: synthetic network cascade simulation with thresholds, propagation, and recovery.

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

create_network <- function(n_nodes = 40, base_probability = 0.08) {
  adjacency <- matrix(0, nrow = n_nodes, ncol = n_nodes)

  for (i in 1:n_nodes) {
    for (j in 1:n_nodes) {
      if (i != j && runif(1) < base_probability) {
        adjacency[i, j] <- runif(1, 0.15, 0.65)
      }
    }
  }

  hubs <- c(5, 12, 25)
  for (hub in hubs) {
    targets <- sample(setdiff(1:n_nodes, hub), 10)
    adjacency[hub, targets] <- runif(length(targets), 0.35, 0.90)
  }

  adjacency
}

simulate_cascade <- function(adjacency, scenario, initial_failed, threshold_multiplier = 1.00, recovery_probability = 0.05, n_steps = 24) {
  n_nodes <- nrow(adjacency)
  thresholds <- runif(n_nodes, 0.55, 1.35) * threshold_multiplier
  failed <- rep(FALSE, n_nodes)
  failed[initial_failed] <- TRUE
  rows <- data.frame()

  for (time in 1:n_steps) {
    stress <- rep(0, n_nodes)

    for (target in 1:n_nodes) {
      incoming_failed <- which(failed)
      if (length(incoming_failed) > 0) {
        stress[target] <- sum(adjacency[incoming_failed, target])
      }
    }

    new_failures <- which(stress >= thresholds & !failed)
    recovering <- which(failed & runif(n_nodes) < recovery_probability)

    failed[new_failures] <- TRUE
    failed[recovering] <- FALSE

    rows <- rbind(rows, data.frame(
      scenario = scenario,
      time = time,
      failed_count = sum(failed),
      failed_fraction = sum(failed) / n_nodes,
      new_failures = length(new_failures),
      recovered = length(recovering),
      mean_stress = mean(stress),
      max_stress = max(stress)
    ))
  }

  rows
}

adjacency <- create_network()
degree_out <- rowSums(adjacency > 0)
degree_in <- colSums(adjacency > 0)
hub_node <- which.max(degree_out)
random_initial <- sample(1:nrow(adjacency), 2)
targeted_initial <- c(hub_node)

runs <- rbind(
  simulate_cascade(adjacency, "random_failure_baseline", random_initial, 1.00, 0.05),
  simulate_cascade(adjacency, "targeted_hub_failure", targeted_initial, 1.00, 0.05),
  simulate_cascade(adjacency, "low_buffer_high_fragility", random_initial, 0.70, 0.03),
  simulate_cascade(adjacency, "resilience_intervention", targeted_initial, 1.35, 0.12)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    peak_failed_fraction = max(subset_data$failed_fraction),
    final_failed_fraction = subset_data$failed_fraction[nrow(subset_data)],
    total_new_failures = sum(subset_data$new_failures),
    total_recovered = sum(subset_data$recovered),
    mean_stress = mean(subset_data$mean_stress),
    max_stress_observed = max(subset_data$max_stress)
  ))
}

network_rows <- data.frame(
  node = 1:nrow(adjacency),
  in_degree = degree_in,
  out_degree = degree_out,
  incoming_weight = colSums(adjacency),
  outgoing_weight = rowSums(adjacency)
)

write.csv(runs, file.path(tables_dir, "r_cascade_trajectories.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_cascade_summary.csv"), row.names = FALSE)
write.csv(network_rows, file.path(tables_dir, "r_network_node_diagnostics.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_cascade_failed_fraction.png"), width = 1200, height = 700)
plot(NULL, xlim = range(runs$time), ylim = c(0, 1), xlab = "Time", ylab = "Failed Fraction", main = "Cascading Failure Scenarios")
for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$failed_fraction, lwd = 2)
}
legend("topright", legend = unique(runs$scenario), lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

print(summary_rows)
cat("R cascading failure workflow complete.\n")
