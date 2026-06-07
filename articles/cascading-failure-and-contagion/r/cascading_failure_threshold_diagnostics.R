# cascading_failure_threshold_diagnostics.R
# Base R workflow:
# simulating a network threshold cascade.

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

build_random_network <- function(node_count = 80, link_probability = 0.055) {
  adjacency <- matrix(0, nrow = node_count, ncol = node_count)

  for (i in 1:(node_count - 1)) {
    for (j in (i + 1):node_count) {
      if (runif(1) < link_probability) {
        adjacency[i, j] <- 1
        adjacency[j, i] <- 1
      }
    }
  }

  adjacency
}

simulate_threshold_cascade <- function(
  scenario,
  node_count = 80,
  link_probability = 0.055,
  threshold = 0.25,
  seed_count = 4,
  max_steps = 40
) {
  adjacency <- build_random_network(node_count, link_probability)
  affected <- rep(0, node_count)

  degree <- rowSums(adjacency)
  seed_nodes <- order(degree, decreasing = TRUE)[1:seed_count]
  affected[seed_nodes] <- 1

  rows <- data.frame()
  previous_affected_count <- 0

  for (step in 0:max_steps) {
    current_affected_count <- sum(affected)
    new_failures <- current_affected_count - previous_affected_count

    rows <- rbind(
      rows,
      data.frame(
        scenario = scenario,
        step = step,
        node_count = node_count,
        link_probability = link_probability,
        threshold = threshold,
        seed_count = seed_count,
        affected_count = current_affected_count,
        affected_share = current_affected_count / node_count,
        new_failures = new_failures,
        mean_degree = mean(degree),
        maximum_degree = max(degree)
      )
    )

    next_affected <- affected
    step_new_failures <- 0

    for (node in 1:node_count) {
      if (affected[node] == 1 || degree[node] == 0) {
        next
      }

      affected_neighbors <- sum(adjacency[node, ] * affected)
      exposure_share <- affected_neighbors / degree[node]

      if (exposure_share >= threshold) {
        next_affected[node] <- 1
        step_new_failures <- step_new_failures + 1
      }
    }

    if (step_new_failures == 0) {
      break
    }

    previous_affected_count <- current_affected_count
    affected <- next_affected
  }

  rows
}

runs <- rbind(
  simulate_threshold_cascade("baseline_threshold", threshold = 0.25, link_probability = 0.055, seed_count = 4),
  simulate_threshold_cascade("lower_threshold", threshold = 0.18, link_probability = 0.055, seed_count = 4),
  simulate_threshold_cascade("higher_connectivity", threshold = 0.25, link_probability = 0.075, seed_count = 4),
  simulate_threshold_cascade("larger_initial_shock", threshold = 0.25, link_probability = 0.055, seed_count = 8),
  simulate_threshold_cascade("high_threshold_containment", threshold = 0.35, link_probability = 0.055, seed_count = 4)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_affected_share = subset_data$affected_share[nrow(subset_data)],
      final_affected_count = subset_data$affected_count[nrow(subset_data)],
      cascade_duration = max(subset_data$step),
      maximum_new_failures = max(subset_data$new_failures, na.rm = TRUE),
      mean_degree = subset_data$mean_degree[nrow(subset_data)],
      maximum_degree = subset_data$maximum_degree[nrow(subset_data)],
      diagnostic_label = ifelse(
        subset_data$affected_share[nrow(subset_data)] >= 0.5,
        "systemic cascade",
        "contained cascade"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_threshold_cascade_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_threshold_cascade_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_threshold_cascade_affected_share.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$step),
  ylim = c(0, 1),
  xlab = "Step",
  ylab = "Affected Share",
  main = "Threshold Cascade Dynamics"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$step, subset_data$affected_share, lwd = 2)
}

legend(
  "bottomright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.8
)
grid()
dev.off()

print(summary_rows)
cat("R cascading failure threshold diagnostics complete.\n")
