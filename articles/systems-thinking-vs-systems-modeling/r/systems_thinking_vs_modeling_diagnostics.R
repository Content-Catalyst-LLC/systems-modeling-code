# systems_thinking_vs_modeling_diagnostics.R
# Base R workflow for comparing conceptual systems framing
# with formal model behavior.

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

scenario_params <- read.csv(file.path(data_dir, "scenario_parameters.csv"), stringsAsFactors = FALSE)

clamp <- function(value, low = 0, high = 200) {
  max(low, min(high, value))
}

simulate_scenario <- function(row, periods = 80) {
  demand <- 80
  capacity <- 70
  backlog <- 22
  trust <- 58
  rework <- 8
  learning <- 22

  rows <- data.frame()

  for (period in 0:periods) {
    service_gap <- max(demand + backlog - capacity, 0)
    service_quality <- clamp(100 - service_gap * 0.50 - rework * 0.35, 0, 100)

    conceptual_score <- clamp(
      50 +
        row$systems_redesign_strength * 24 +
        row$uncertainty_humility * 14 -
        row$intervention_pressure * 8 -
        service_gap * 0.08,
      0,
      100
    )

    modeled_score <- clamp(
      service_quality * 0.30 +
        trust * 0.25 +
        learning * 0.20 +
        capacity * 0.10 -
        backlog * 0.10 -
        rework * 0.15,
      0,
      100
    )

    rows <- rbind(rows, data.frame(
      scenario = row$scenario,
      period = period,
      demand = demand,
      capacity = capacity,
      backlog = backlog,
      trust = trust,
      rework = rework,
      learning = learning,
      service_gap = service_gap,
      service_quality = service_quality,
      conceptual_systems_score = conceptual_score,
      modeled_systems_score = modeled_score,
      conceptual_model_gap = conceptual_score - modeled_score
    ))

    pressure_gain <- row$intervention_pressure * 4
    redesign_gain <- row$systems_redesign_strength * 3.2
    delayed_learning_effect <- learning * 0.03 * (1 - row$delay_factor)

    demand <- demand + row$demand_growth * demand
    capacity <- capacity + row$capacity_growth * capacity + redesign_gain + delayed_learning_effect - rework * 0.015
    backlog <- backlog + demand * 0.10 + rework * 0.30 - capacity * 0.09 - redesign_gain * 0.80
    rework <- rework + service_gap * row$rework_rate + pressure_gain * 0.15 - redesign_gain * 0.45
    trust <- trust - backlog * row$trust_loss_from_backlog + service_quality * row$trust_gain_from_service + redesign_gain * 0.10
    learning <- learning + row$uncertainty_humility * 1.3 + row$systems_redesign_strength * 1.1 - row$intervention_pressure * 0.45

    demand <- clamp(demand, 0, 200)
    capacity <- clamp(capacity, 0, 200)
    backlog <- clamp(backlog, 0, 200)
    trust <- clamp(trust, 0, 100)
    rework <- clamp(rework, 0, 120)
    learning <- clamp(learning, 0, 100)
  }

  rows
}

all_data <- data.frame()

for (i in seq_len(nrow(scenario_params))) {
  all_data <- rbind(all_data, simulate_scenario(scenario_params[i, ]))
}

scenario_names <- unique(all_data$scenario)
summary_rows <- data.frame()

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  final_row <- subset_data[nrow(subset_data), ]

  avg_gap <- mean(abs(subset_data$conceptual_model_gap))
  avg_modeled <- mean(subset_data$modeled_systems_score)
  max_backlog <- max(subset_data$backlog)
  min_trust <- min(subset_data$trust)

  diagnostic <- ifelse(
    avg_gap > 18,
    "conceptual map and formal model diverge; assumptions need revision",
    ifelse(
      max_backlog > 90,
      "formal model reveals backlog amplification",
      ifelse(
        min_trust < 35,
        "formal model reveals trust depletion",
        ifelse(
          avg_modeled >= 65,
          "conceptual framing and formal model support systemic improvement",
          "partial improvement with unresolved structural pressure"
        )
      )
    )
  )

  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    final_modeled_score = final_row$modeled_systems_score,
    final_conceptual_score = final_row$conceptual_systems_score,
    final_service_quality = final_row$service_quality,
    final_learning = final_row$learning,
    average_absolute_conceptual_model_gap = avg_gap,
    average_modeled_score = avg_modeled,
    maximum_backlog = max_backlog,
    minimum_trust = min_trust,
    diagnostic = diagnostic
  ))
}

write.csv(all_data, file.path(tables_dir, "r_systems_thinking_vs_modeling_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_systems_thinking_vs_modeling_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_conceptual_vs_modeled_scores.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$period),
  ylim = range(c(all_data$modeled_systems_score, all_data$conceptual_systems_score)),
  xlab = "Period",
  ylab = "Score",
  main = "Conceptual Systems Score vs Formal Modeled Score"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$period, subset_data$modeled_systems_score, lwd = 2)
  lines(subset_data$period, subset_data$conceptual_systems_score, lty = 2)
}

legend("bottomright", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

png(file.path(figures_dir, "r_backlog_and_trust.png"), width = 1200, height = 700)
plot(
  NA,
  xlim = range(all_data$period),
  ylim = range(c(all_data$backlog, all_data$trust)),
  xlab = "Period",
  ylab = "Value",
  main = "Backlog and Trust Across Scenarios"
)

for (scenario_name in scenario_names) {
  subset_data <- all_data[all_data$scenario == scenario_name, ]
  lines(subset_data$period, subset_data$backlog, lwd = 2)
  lines(subset_data$period, subset_data$trust, lty = 2)
}

legend("topright", legend = scenario_names, lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

print(summary_rows)
cat("R systems thinking vs systems modeling diagnostics complete.\n")
