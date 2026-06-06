# stock_flow_accumulation_diagnostics.R
# Base R workflow:
# simulating backlog accumulation, resource depletion, and infrastructure recovery.

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

n_steps <- 120
time <- seq_len(n_steps)

simulate_stock_flows <- function(scenario) {
  backlog <- numeric(n_steps)
  resource <- numeric(n_steps)
  condition <- numeric(n_steps)

  backlog[1] <- 80
  resource[1] <- 600
  condition[1] <- 72

  backlog_arrivals <- numeric(n_steps)
  backlog_completions <- numeric(n_steps)
  resource_regeneration <- numeric(n_steps)
  resource_extraction <- numeric(n_steps)
  condition_maintenance <- numeric(n_steps)
  condition_wear <- numeric(n_steps)

  for (t in 2:n_steps) {
    if (scenario == "baseline") {
      backlog_arrivals[t] <- 18
      resource_extraction[t] <- 24
      condition_maintenance[t] <- 0.9
    } else if (scenario == "capacity_and_conservation") {
      backlog_arrivals[t] <- ifelse(t < 50, 16, 13)
      resource_extraction[t] <- ifelse(t < 70, 22, 12)
      condition_maintenance[t] <- ifelse(t < 60, 1.2, 2.8)
    } else if (scenario == "delayed_response") {
      backlog_arrivals[t] <- ifelse(t < 75, 18, 13)
      resource_extraction[t] <- ifelse(t < 85, 24, 12)
      condition_maintenance[t] <- ifelse(t < 85, 0.9, 2.8)
    } else if (scenario == "adaptive_recovery") {
      backlog_arrivals[t] <- ifelse(t < 50, 16, 12)
      resource_extraction[t] <- ifelse(t < 55, 22, 10)
      condition_maintenance[t] <- ifelse(t < 50, 1.4, 3.4)
    } else {
      stop(paste("Unknown scenario:", scenario))
    }

    backlog_completions[t] <- min(backlog[t - 1] + backlog_arrivals[t], 12 + 0.08 * backlog[t - 1])
    backlog[t] <- max(0, backlog[t - 1] + backlog_arrivals[t] - backlog_completions[t])

    resource_regeneration[t] <- 0.045 * resource[t - 1] * (1 - resource[t - 1] / 1000)
    resource[t] <- max(0, resource[t - 1] + resource_regeneration[t] - resource_extraction[t])

    condition_wear[t] <- 1.4 + 0.012 * max(0, 100 - condition[t - 1])
    condition[t] <- min(100, max(0, condition[t - 1] + condition_maintenance[t] - condition_wear[t]))
  }

  data.frame(
    scenario = scenario,
    time = time,
    backlog = backlog,
    backlog_arrivals = backlog_arrivals,
    backlog_completions = backlog_completions,
    backlog_net_flow = backlog_arrivals - backlog_completions,
    resource = resource,
    resource_regeneration = resource_regeneration,
    resource_extraction = resource_extraction,
    resource_net_flow = resource_regeneration - resource_extraction,
    infrastructure_condition = condition,
    condition_maintenance = condition_maintenance,
    condition_wear = condition_wear,
    condition_net_flow = condition_maintenance - condition_wear
  )
}

trajectory_df <- rbind(
  simulate_stock_flows("baseline"),
  simulate_stock_flows("capacity_and_conservation"),
  simulate_stock_flows("delayed_response"),
  simulate_stock_flows("adaptive_recovery")
)

summary_rows <- data.frame()

for (scenario_name in unique(trajectory_df$scenario)) {
  subset_data <- trajectory_df[trajectory_df$scenario == scenario_name, ]

  for (stock_name in c("backlog", "resource", "infrastructure_condition")) {
    if (stock_name == "backlog") {
      values <- subset_data$backlog
      net_flows <- subset_data$backlog_net_flow
      interpretation <- "service backlog accumulates when arrivals exceed completions"
    } else if (stock_name == "resource") {
      values <- subset_data$resource
      net_flows <- subset_data$resource_net_flow
      interpretation <- "resource stock declines when extraction exceeds regeneration"
    } else {
      values <- subset_data$infrastructure_condition
      net_flows <- subset_data$condition_net_flow
      interpretation <- "infrastructure condition recovers only when maintenance exceeds wear"
    }

    summary_rows <- rbind(
      summary_rows,
      data.frame(
        scenario = scenario_name,
        stock = stock_name,
        initial_value = values[1],
        final_value = values[length(values)],
        minimum_value = min(values),
        maximum_value = max(values),
        mean_net_flow = mean(net_flows),
        final_net_flow = net_flows[length(net_flows)],
        interpretation = interpretation
      )
    )
  }
}

write.csv(
  trajectory_df,
  file.path(tables_dir, "r_stock_flow_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_stock_flow_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_stock_flow_trajectories.png"), width = 1200, height = 700)
baseline_subset <- trajectory_df[trajectory_df$scenario == "baseline", ]
plot(
  baseline_subset$time,
  baseline_subset$backlog,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "Stock Level",
  main = "Baseline Stock-Flow Accumulation"
)
lines(baseline_subset$time, baseline_subset$resource / 10, lwd = 2, lty = 2)
lines(baseline_subset$time, baseline_subset$infrastructure_condition, lwd = 2, lty = 3)
legend(
  "topright",
  legend = c("Backlog", "Resource / 10", "Infrastructure condition"),
  lwd = 2,
  lty = c(1, 2, 3),
  bty = "n"
)
grid()
dev.off()

print(summary_rows)
cat("R stock-flow accumulation diagnostics complete.\n")
