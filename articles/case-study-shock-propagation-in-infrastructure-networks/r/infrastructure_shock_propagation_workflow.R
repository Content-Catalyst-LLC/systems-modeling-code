# infrastructure_shock_propagation_workflow.R
# Base R workflow: synthetic infrastructure network, shock propagation, cascade diagnostics.

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

nodes <- read.csv(file.path(data_dir, "infrastructure_nodes.csv"), stringsAsFactors = FALSE)
edges <- read.csv(file.path(data_dir, "infrastructure_edges.csv"), stringsAsFactors = FALSE)
scenarios <- read.csv(file.path(data_dir, "shock_scenarios.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(data_dir, "model_assumptions.csv"), stringsAsFactors = FALSE)
diagnostics <- read.csv(file.path(data_dir, "diagnostic_definitions.csv"), stringsAsFactors = FALSE)

simulate_cascade <- function(scenario_name, initial_failures, max_steps = 8, overload_threshold = 1.05, dependency_tolerance = 0.50) {
  status <- rep(1, nrow(nodes))
  names(status) <- nodes$node
  status[initial_failures] <- 0

  current_load <- nodes$load
  names(current_load) <- nodes$node

  rows <- data.frame()

  for (step in 0:max_steps) {
    failed_nodes <- names(status)[status == 0]
    weighted_service_loss <- sum(nodes$criticality[nodes$node %in% failed_nodes])
    failed_count <- length(failed_nodes)

    new_dependency_failures <- character(0)
    new_overload_failures <- character(0)

    if (step < max_steps) {
      for (node_name in nodes$node[status == 1]) {
        incoming_deps <- edges$source[edges$target == node_name & edges$edge_type == "dependency"]
        if (length(incoming_deps) > 0) {
          failed_deps <- sum(status[incoming_deps] == 0)
          failed_fraction <- failed_deps / length(incoming_deps)
          if (failed_fraction > dependency_tolerance) {
            new_dependency_failures <- c(new_dependency_failures, node_name)
          }
        }
      }

      for (failed in failed_nodes) {
        neighbors <- edges$target[edges$source == failed]
        neighbors <- neighbors[status[neighbors] == 1]
        if (length(neighbors) > 0) {
          redistributed_load <- current_load[failed] / length(neighbors)
          current_load[neighbors] <- current_load[neighbors] + redistributed_load
        }
      }

      for (node_name in nodes$node[status == 1]) {
        capacity <- nodes$capacity[nodes$node == node_name]
        if (current_load[node_name] / capacity > overload_threshold) {
          new_overload_failures <- c(new_overload_failures, node_name)
        }
      }
    }

    rows <- rbind(
      rows,
      data.frame(
        scenario = scenario_name,
        step = step,
        failed_count = failed_count,
        failed_nodes = paste(failed_nodes, collapse = "|"),
        weighted_service_loss = weighted_service_loss,
        functional_count = sum(status == 1),
        new_dependency_failures = paste(unique(new_dependency_failures), collapse = "|"),
        new_overload_failures = paste(unique(new_overload_failures), collapse = "|"),
        stringsAsFactors = FALSE
      )
    )

    if (step == max_steps) {
      break
    }

    new_failures <- unique(c(new_dependency_failures, new_overload_failures))
    if (length(new_failures) > 0) {
      status[new_failures] <- 0
    }
  }

  rows
}

all_runs <- data.frame()

for (i in seq_len(nrow(scenarios))) {
  scenario_name <- scenarios$scenario[i]
  initial_failures <- unlist(strsplit(scenarios$initial_failures[i], "\\|"))
  run <- simulate_cascade(scenario_name, initial_failures)
  all_runs <- rbind(all_runs, run)
}

scenario_names <- unique(all_runs$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]
  final_row <- subset_rows[nrow(subset_rows), ]
  max_failed <- max(subset_rows$failed_count)

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_failed_count = final_row$failed_count,
      max_failed_count = max_failed,
      final_weighted_service_loss = final_row$weighted_service_loss,
      max_weighted_service_loss = max(subset_rows$weighted_service_loss),
      cascade_depth = max(subset_rows$step[subset_rows$failed_count == max_failed]),
      dependency_failure_events = sum(subset_rows$new_dependency_failures != ""),
      overload_failure_events = sum(subset_rows$new_overload_failures != ""),
      stringsAsFactors = FALSE
    )
  )
}

validation_checks <- data.frame(
  check = c("nodes_created", "edges_created", "scenarios_created", "scenario_runs_created", "weighted_service_loss_nonnegative", "failed_counts_nonnegative", "summary_created"),
  passed = c(
    nrow(nodes) > 0,
    nrow(edges) > 0,
    nrow(scenarios) > 0,
    nrow(all_runs) > 0,
    all(all_runs$weighted_service_loss >= 0),
    all(all_runs$failed_count >= 0),
    nrow(summary_rows) > 0
  )
)

write.csv(nodes, file.path(tables_dir, "r_infrastructure_nodes.csv"), row.names = FALSE)
write.csv(edges, file.path(tables_dir, "r_infrastructure_edges.csv"), row.names = FALSE)
write.csv(scenarios, file.path(tables_dir, "r_shock_scenarios.csv"), row.names = FALSE)
write.csv(all_runs, file.path(tables_dir, "r_shock_propagation_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_shock_propagation_summary.csv"), row.names = FALSE)
write.csv(assumptions, file.path(tables_dir, "r_model_assumptions.csv"), row.names = FALSE)
write.csv(diagnostics, file.path(tables_dir, "r_diagnostic_definitions.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_shock_propagation_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_shock_propagation_failed_nodes.png"), width = 1000, height = 700)
plot(
  NULL,
  xlim = range(all_runs$step),
  ylim = c(0, max(all_runs$failed_count)),
  xlab = "Propagation Step",
  ylab = "Failed Nodes",
  main = "Shock Propagation in Infrastructure Network Scenarios"
)

for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]
  lines(subset_rows$step, subset_rows$failed_count, lwd = 2)
}

legend("topleft", legend = scenario_names, lwd = 2, cex = 0.75)
grid()
dev.off()

print(summary_rows)
print(validation_checks)
cat("R infrastructure shock propagation workflow complete.\n")
