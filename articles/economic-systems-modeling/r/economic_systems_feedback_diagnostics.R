# economic_systems_feedback_diagnostics.R
# Base R workflow:
# simulating demand, investment, capital capacity, debt, and fragility feedback.

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

simulate_economy <- function(
  scenario,
  n_steps = 120,
  demand_sensitivity = 0.62,
  investment_sensitivity = 0.16,
  interest_rate = 0.035,
  depreciation = 0.045,
  credit_sensitivity = 0.10,
  shock_step = 70,
  shock_size = -8
) {
  time <- seq_len(n_steps)

  output <- numeric(n_steps)
  consumption <- numeric(n_steps)
  investment <- numeric(n_steps)
  capital <- numeric(n_steps)
  debt <- numeric(n_steps)
  debt_service <- numeric(n_steps)
  fragility <- numeric(n_steps)
  demand_gap <- numeric(n_steps)
  government <- rep(22, n_steps)

  output[1] <- 100
  capital[1] <- 190
  debt[1] <- 60
  fragility[1] <- debt[1] / capital[1]

  for (t in 2:n_steps) {
    consumption[t - 1] <- max(0, 18 + demand_sensitivity * output[t - 1] - 0.025 * debt[t - 1])

    investment[t - 1] <- max(
      0,
      investment_sensitivity * output[t - 1] - interest_rate * debt[t - 1]
    )

    capital[t] <- max(0, capital[t - 1] + investment[t - 1] - depreciation * capital[t - 1])

    new_credit <- max(0, credit_sensitivity * investment[t - 1])
    repayment <- 0.025 * debt[t - 1]
    debt[t] <- max(0, debt[t - 1] + new_credit - repayment)

    shock <- ifelse(t == shock_step, shock_size, 0)

    output[t] <- max(
      0,
      0.33 * capital[t] + consumption[t - 1] + government[t - 1] + shock
    )

    fragility[t] <- debt[t] / max(capital[t], 1)
    debt_service[t] <- interest_rate * debt[t]
    demand_gap[t] <- output[t] - consumption[t - 1] - investment[t - 1] - government[t]
  }

  consumption[n_steps] <- max(0, 18 + demand_sensitivity * output[n_steps] - 0.025 * debt[n_steps])
  investment[n_steps] <- max(0, investment_sensitivity * output[n_steps] - interest_rate * debt[n_steps])
  debt_service[n_steps] <- interest_rate * debt[n_steps]
  demand_gap[n_steps] <- output[n_steps] - consumption[n_steps] - investment[n_steps] - government[n_steps]

  data.frame(
    scenario = scenario,
    time = time,
    output = output,
    consumption = consumption,
    investment = investment,
    capital = capital,
    debt = debt,
    debt_service = debt_service,
    fragility = fragility,
    government = government,
    demand_gap = demand_gap
  )
}

runs <- rbind(
  simulate_economy("baseline_feedback"),
  simulate_economy("higher_investment", investment_sensitivity = 0.21),
  simulate_economy("tighter_credit", interest_rate = 0.055),
  simulate_economy("larger_shock", shock_size = -18),
  simulate_economy("higher_debt_growth", credit_sensitivity = 0.18),
  simulate_economy("weak_demand", demand_sensitivity = 0.52),
  simulate_economy("rapid_depreciation", depreciation = 0.070),
  simulate_economy("policy_support", demand_sensitivity = 0.66, investment_sensitivity = 0.18, interest_rate = 0.030, shock_size = -4)
)

summary_rows <- data.frame()

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      scenario = scenario_name,
      final_output = subset_data$output[nrow(subset_data)],
      final_capital = subset_data$capital[nrow(subset_data)],
      final_debt = subset_data$debt[nrow(subset_data)],
      final_fragility = subset_data$fragility[nrow(subset_data)],
      maximum_fragility = max(subset_data$fragility),
      minimum_output = min(subset_data$output),
      average_output = mean(subset_data$output),
      average_investment = mean(subset_data$investment),
      diagnostic_label = ifelse(
        max(subset_data$fragility) > 0.75,
        "high fragility pathway",
        "moderate fragility pathway"
      )
    )
  )
}

write.csv(
  runs,
  file.path(tables_dir, "r_economic_feedback_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_economic_feedback_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_economic_feedback_output.png"), width = 1200, height = 700)
plot(
  NULL,
  xlim = range(runs$time),
  ylim = range(runs$output),
  xlab = "Time",
  ylab = "Output",
  main = "Economic Feedback Pathways"
)

for (scenario_name in unique(runs$scenario)) {
  subset_data <- runs[runs$scenario == scenario_name, ]
  lines(subset_data$time, subset_data$output, lwd = 2)
}

legend(
  "bottomright",
  legend = unique(runs$scenario),
  lwd = 2,
  bty = "n",
  cex = 0.75
)
grid()
dev.off()

print(summary_rows)
cat("R economic systems feedback diagnostics complete.\n")
