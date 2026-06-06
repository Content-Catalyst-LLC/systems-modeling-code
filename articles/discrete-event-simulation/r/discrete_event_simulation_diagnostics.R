# discrete_event_simulation_diagnostics.R
# Base R workflow:
# single-server queue with stochastic arrivals, service times, and diagnostics.

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

scenario_params <- read.csv(file.path(data_dir, "des_scenarios.csv"), stringsAsFactors = FALSE)

simulate_single_server <- function(row, n_entities = 240) {
  set.seed(row$seed)

  interarrival <- rexp(n_entities, rate = row$arrival_rate)
  service_time <- rexp(n_entities, rate = row$service_rate)

  arrival_time <- cumsum(interarrival)
  service_start <- numeric(n_entities)
  departure_time <- numeric(n_entities)
  waiting_time <- numeric(n_entities)

  service_start[1] <- arrival_time[1]
  departure_time[1] <- service_start[1] + service_time[1]
  waiting_time[1] <- 0

  for (i in 2:n_entities) {
    service_start[i] <- max(arrival_time[i], departure_time[i - 1])
    departure_time[i] <- service_start[i] + service_time[i]
    waiting_time[i] <- service_start[i] - arrival_time[i]
  }

  entity_df <- data.frame(
    scenario = row$scenario,
    entity = seq_len(n_entities),
    arrival_time = arrival_time,
    service_time = service_time,
    service_start = service_start,
    departure_time = departure_time,
    waiting_time = waiting_time,
    time_in_system = departure_time - arrival_time,
    met_service_level = waiting_time <= row$service_level_target
  )

  summary_df <- data.frame(
    scenario = row$scenario,
    arrival_rate = row$arrival_rate,
    service_rate = row$service_rate,
    implied_utilization = row$arrival_rate / max(row$servers * row$service_rate, 1e-9),
    completed_entities = n_entities,
    average_waiting_time = mean(waiting_time),
    maximum_waiting_time = max(waiting_time),
    average_time_in_system = mean(entity_df$time_in_system),
    maximum_time_in_system = max(entity_df$time_in_system),
    service_level_share = mean(entity_df$met_service_level),
    diagnostic = ifelse(
      mean(waiting_time) > row$service_level_target,
      "high waiting pressure",
      "contained waiting under current assumptions"
    )
  )

  list(entity = entity_df, summary = summary_df)
}

scenario_outputs <- list()

for (i in seq_len(nrow(scenario_params))) {
  scenario_outputs[[i]] <- simulate_single_server(scenario_params[i, ])
}

entity_rows <- do.call(rbind, lapply(scenario_outputs, function(x) x$entity))
summary_rows <- do.call(rbind, lapply(scenario_outputs, function(x) x$summary))

write.csv(entity_rows, file.path(tables_dir, "r_des_entity_trace.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_des_queue_summary.csv"), row.names = FALSE)

baseline <- entity_rows[entity_rows$scenario == "baseline_single_server", ]

png(file.path(figures_dir, "r_des_waiting_time_by_entity.png"), width = 1200, height = 700)
plot(
  baseline$entity,
  baseline$waiting_time,
  type = "l",
  lwd = 2,
  xlab = "Entity",
  ylab = "Waiting Time",
  main = "Waiting Time Across Entities in Baseline DES Queue"
)
grid()
dev.off()

png(file.path(figures_dir, "r_des_average_waiting_by_scenario.png"), width = 1200, height = 700)
barplot(
  summary_rows$average_waiting_time,
  names.arg = summary_rows$scenario,
  las = 2,
  ylab = "Average Waiting Time",
  main = "Average Waiting Time by DES Scenario"
)
grid()
dev.off()

print(summary_rows)
cat("R discrete event simulation diagnostics complete.\n")
