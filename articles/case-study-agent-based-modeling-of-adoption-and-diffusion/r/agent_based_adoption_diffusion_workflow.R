# agent_based_adoption_diffusion_workflow.R
# Base R workflow: synthetic agents, networks, thresholds, peer influence, diffusion diagnostics.

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

scenarios <- read.csv(file.path(data_dir, "diffusion_scenarios.csv"), stringsAsFactors = FALSE)
group_assumptions <- read.csv(file.path(data_dir, "agent_group_assumptions.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(data_dir, "model_assumptions.csv"), stringsAsFactors = FALSE)
diagnostics <- read.csv(file.path(data_dir, "diagnostic_definitions.csv"), stringsAsFactors = FALSE)

set.seed(42)

create_agents <- function(n = 120) {
  groups <- rep(group_assumptions$group, length.out = n)
  agents <- data.frame()

  for (i in seq_len(n)) {
    group_name <- groups[i]
    g <- group_assumptions[group_assumptions$group == group_name, ]

    agents <- rbind(
      agents,
      data.frame(
        agent_id = i,
        group = group_name,
        threshold = runif(1, g$threshold_low, g$threshold_high),
        perceived_benefit = runif(1, g$benefit_low, g$benefit_high),
        cost_sensitivity = runif(1, g$cost_low, g$cost_high),
        trust = runif(1, g$trust_low, g$trust_high),
        resistance = runif(1, g$resistance_low, g$resistance_high),
        adopted = 0,
        stringsAsFactors = FALSE
      )
    )
  }

  agents
}

create_network <- function(agents, connection_probability, bridge_probability) {
  edges <- data.frame(from = integer(0), to = integer(0))

  for (i in seq_len(nrow(agents))) {
    for (j in seq_len(nrow(agents))) {
      if (i < j) {
        same_group <- agents$group[i] == agents$group[j]
        probability <- ifelse(same_group, connection_probability, bridge_probability)

        if (runif(1) < probability) {
          edges <- rbind(edges, data.frame(from = i, to = j))
          edges <- rbind(edges, data.frame(from = j, to = i))
        }
      }
    }
  }

  edges
}

neighbor_share <- function(agent_id, agents, edges) {
  neighbors <- edges$to[edges$from == agent_id]

  if (length(neighbors) == 0) {
    return(0)
  }

  mean(agents$adopted[neighbors])
}

choose_seed_agents <- function(agents, edges, seed_strategy, seed_count) {
  if (seed_strategy == "high_degree") {
    degree <- sapply(agents$agent_id, function(id) sum(edges$from == id))
    return(order(degree, decreasing = TRUE)[seq_len(seed_count)])
  }

  if (seed_strategy == "bridge_and_equity") {
    degree <- sapply(agents$agent_id, function(id) sum(edges$from == id))
    high_barrier_ids <- agents$agent_id[agents$group == "high_barrier"]
    ranked <- order(degree, decreasing = TRUE)
    seed_ids <- high_barrier_ids[seq_len(min(3, length(high_barrier_ids)))]

    for (id in ranked) {
      if (!(id %in% seed_ids)) {
        seed_ids <- c(seed_ids, id)
      }
      if (length(seed_ids) >= seed_count) {
        break
      }
    }

    return(seed_ids[seq_len(seed_count)])
  }

  sample(agents$agent_id, seed_count)
}

simulate_diffusion <- function(scenario_row) {
  agents <- create_agents()
  agents$trust <- pmin(1, agents$trust * scenario_row$trust_modifier)
  agents$cost_sensitivity <- pmin(1, agents$cost_sensitivity * scenario_row$cost_modifier)

  edges <- create_network(
    agents,
    scenario_row$connection_probability,
    scenario_row$bridge_probability
  )

  seed_ids <- choose_seed_agents(
    agents,
    edges,
    scenario_row$seed_strategy,
    scenario_row$seed_count
  )

  agents$adopted[seed_ids] <- 1
  rows <- data.frame()

  for (step in 0:scenario_row$steps) {
    group_summary <- aggregate(adopted ~ group, data = agents, FUN = mean)
    adoption_gap <- max(group_summary$adopted) - min(group_summary$adopted)

    rows <- rbind(
      rows,
      data.frame(
        scenario = scenario_row$scenario,
        step = step,
        adoption_share = mean(agents$adopted),
        adopter_count = sum(agents$adopted),
        adoption_gap = adoption_gap,
        early_access_adoption = group_summary$adopted[group_summary$group == "early_access"],
        mainstream_adoption = group_summary$adopted[group_summary$group == "mainstream"],
        high_barrier_adoption = group_summary$adopted[group_summary$group == "high_barrier"],
        seed_count = scenario_row$seed_count,
        stringsAsFactors = FALSE
      )
    )

    if (step == scenario_row$steps) {
      break
    }

    new_adopters <- integer(0)

    for (i in agents$agent_id[agents$adopted == 0]) {
      peer_share <- neighbor_share(i, agents, edges)

      adoption_pressure <-
        scenario_row$benefit_weight * agents$perceived_benefit[i] +
        scenario_row$social_weight * agents$trust[i] * peer_share +
        scenario_row$intervention_weight -
        scenario_row$cost_weight * agents$cost_sensitivity[i] -
        scenario_row$resistance_weight * agents$resistance[i]

      if (adoption_pressure >= agents$threshold[i]) {
        new_adopters <- c(new_adopters, i)
      }
    }

    if (length(new_adopters) > 0) {
      agents$adopted[new_adopters] <- 1
    }
  }

  list(rows = rows, agents = agents, edges = edges)
}

all_runs <- data.frame()
final_agents <- data.frame()
network_summary <- data.frame()

for (i in seq_len(nrow(scenarios))) {
  run <- simulate_diffusion(scenarios[i, ])
  all_runs <- rbind(all_runs, run$rows)

  scenario_agents <- run$agents
  scenario_agents$scenario <- scenarios$scenario[i]
  final_agents <- rbind(final_agents, scenario_agents)

  degree <- sapply(run$agents$agent_id, function(id) sum(run$edges$from == id))
  network_summary <- rbind(
    network_summary,
    data.frame(
      scenario = scenarios$scenario[i],
      agent_count = nrow(run$agents),
      directed_edge_count = nrow(run$edges),
      undirected_edge_count = nrow(run$edges) / 2,
      mean_degree = mean(degree),
      max_degree = max(degree),
      stringsAsFactors = FALSE
    )
  )
}

scenario_names <- unique(all_runs$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]

  time_to_25 <- subset_rows$step[subset_rows$adoption_share >= 0.25]
  time_to_50 <- subset_rows$step[subset_rows$adoption_share >= 0.50]
  growth <- diff(subset_rows$adoption_share)

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_adoption_share = subset_rows$adoption_share[nrow(subset_rows)],
      final_adopter_count = subset_rows$adopter_count[nrow(subset_rows)],
      maximum_adoption_gap = max(subset_rows$adoption_gap),
      final_adoption_gap = subset_rows$adoption_gap[nrow(subset_rows)],
      time_to_25_percent = ifelse(length(time_to_25) == 0, NA, min(time_to_25)),
      time_to_50_percent = ifelse(length(time_to_50) == 0, NA, min(time_to_50)),
      peak_growth = ifelse(length(growth) == 0, 0, max(growth)),
      seed_efficiency = subset_rows$adoption_share[nrow(subset_rows)] / max(1, subset_rows$seed_count[nrow(subset_rows)]),
      stringsAsFactors = FALSE
    )
  )
}

validation_checks <- data.frame(
  check = c(
    "scenario_runs_created",
    "adoption_share_normalized",
    "adopter_count_nonnegative",
    "adoption_gap_normalized",
    "summary_created",
    "agent_attributes_normalized"
  ),
  passed = c(
    nrow(all_runs) > 0,
    all(all_runs$adoption_share >= 0 & all_runs$adoption_share <= 1),
    all(all_runs$adopter_count >= 0),
    all(all_runs$adoption_gap >= 0 & all_runs$adoption_gap <= 1),
    nrow(summary_rows) > 0,
    all(final_agents$threshold >= 0 & final_agents$threshold <= 1)
  )
)

write.csv(all_runs, file.path(tables_dir, "r_adoption_diffusion_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_adoption_diffusion_summary.csv"), row.names = FALSE)
write.csv(scenarios, file.path(tables_dir, "r_diffusion_scenarios.csv"), row.names = FALSE)
write.csv(group_assumptions, file.path(tables_dir, "r_agent_group_assumptions.csv"), row.names = FALSE)
write.csv(final_agents, file.path(tables_dir, "r_final_agent_states.csv"), row.names = FALSE)
write.csv(network_summary, file.path(tables_dir, "r_network_summary.csv"), row.names = FALSE)
write.csv(assumptions, file.path(tables_dir, "r_model_assumptions.csv"), row.names = FALSE)
write.csv(diagnostics, file.path(tables_dir, "r_diagnostic_definitions.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_adoption_diffusion_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_adoption_diffusion_curves.png"), width = 1000, height = 700)
plot(
  NULL,
  xlim = range(all_runs$step),
  ylim = c(0, 1),
  xlab = "Time Step",
  ylab = "Adoption Share",
  main = "Agent-Based Adoption and Diffusion Scenarios"
)

for (scenario_name in scenario_names) {
  subset_rows <- all_runs[all_runs$scenario == scenario_name, ]
  lines(subset_rows$step, subset_rows$adoption_share, lwd = 2)
}

legend("bottomright", legend = scenario_names, lwd = 2, cex = 0.75)
grid()
dev.off()

print(summary_rows)
print(validation_checks)
cat("R agent-based adoption and diffusion workflow complete.\n")
