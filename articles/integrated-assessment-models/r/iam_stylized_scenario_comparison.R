# Base R stylized IAM scenario comparison.
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

simulate_iam <- function(scenario, years = seq(2025, 2100, by = 5), output = 100,
                         productivity_growth = 0.012, emissions_intensity = 0.42,
                         emissions_intensity_decline = 0.010, mitigation_rate = 0.05,
                         mitigation_growth = 0.020, max_mitigation = 0.95,
                         damage_coefficient = 0.010, mitigation_cost_scale = 0.040,
                         discount_rate = 0.015) {
  atmospheric_pressure <- 1.0
  temperature_proxy <- 1.2
  rows <- data.frame()
  for (i in seq_along(years)) {
    if (i > 1) {
      output <- output * (1 + productivity_growth)^5
      emissions_intensity <- max(0.02, emissions_intensity * (1 - emissions_intensity_decline)^5)
      mitigation_rate <- min(max_mitigation, mitigation_rate + mitigation_growth)
    }
    emissions <- output * emissions_intensity * (1 - mitigation_rate)
    if (i > 1) {
      atmospheric_pressure <- max(0, atmospheric_pressure + 0.012 * emissions - 0.010 * atmospheric_pressure)
      temperature_proxy <- max(0, temperature_proxy + 0.030 * atmospheric_pressure - 0.012 * temperature_proxy)
    }
    damages <- damage_coefficient * temperature_proxy^2 * output
    mitigation_cost <- mitigation_cost_scale * mitigation_rate^2 * output
    consumption_proxy <- max(0, output - damages - mitigation_cost)
    welfare <- log(consumption_proxy + 1) / ((1 + discount_rate)^(years[i] - years[1]))
    rows <- rbind(rows, data.frame(scenario, year = years[i], output, emissions_intensity,
                                   mitigation_rate, emissions, atmospheric_pressure,
                                   temperature_proxy, damages, mitigation_cost,
                                   consumption_proxy, discounted_welfare_proxy = welfare))
  }
  rows
}

runs <- rbind(
  simulate_iam("delayed_transition", mitigation_rate = 0.02, mitigation_growth = 0.010, emissions_intensity_decline = 0.006, damage_coefficient = 0.012),
  simulate_iam("moderate_transition", mitigation_rate = 0.06, mitigation_growth = 0.025, emissions_intensity_decline = 0.012),
  simulate_iam("accelerated_decarbonization", mitigation_rate = 0.10, mitigation_growth = 0.045, emissions_intensity_decline = 0.018, mitigation_cost_scale = 0.055, damage_coefficient = 0.008),
  simulate_iam("high_innovation_pathway", mitigation_rate = 0.08, mitigation_growth = 0.040, emissions_intensity_decline = 0.026, mitigation_cost_scale = 0.038, damage_coefficient = 0.008),
  simulate_iam("resilient_transition_pathway", emissions_intensity = 0.40, mitigation_rate = 0.12, mitigation_growth = 0.045, emissions_intensity_decline = 0.024, mitigation_cost_scale = 0.036, damage_coefficient = 0.007, discount_rate = 0.010)
)

summary_rows <- data.frame()
for (scenario_name in unique(runs$scenario)) {
  x <- runs[runs$scenario == scenario_name, ]
  final <- x[nrow(x), ]
  summary_rows <- rbind(summary_rows, data.frame(
    scenario = scenario_name,
    final_emissions = final$emissions,
    final_temperature_proxy = final$temperature_proxy,
    cumulative_emissions = sum(x$emissions),
    cumulative_damages = sum(x$damages),
    cumulative_mitigation_cost = sum(x$mitigation_cost),
    discounted_welfare_proxy = sum(x$discounted_welfare_proxy),
    average_mitigation_rate = mean(x$mitigation_rate),
    diagnostic_label = ifelse(final$temperature_proxy > 3, "high climate pressure pathway", "lower climate pressure pathway")
  ))
}

write.csv(runs, file.path(tables_dir, "r_iam_stylized_scenario_trajectories.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_iam_stylized_scenario_summary.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_iam_emissions_pathways.png"), width = 1200, height = 700)
plot(NULL, xlim = range(runs$year), ylim = range(runs$emissions), xlab = "Year", ylab = "Emissions Proxy", main = "Stylized IAM Scenario Comparison: Emissions")
for (scenario_name in unique(runs$scenario)) {
  x <- runs[runs$scenario == scenario_name, ]
  lines(x$year, x$emissions, lwd = 2)
}
legend("topright", legend = unique(runs$scenario), lwd = 2, bty = "n", cex = 0.75)
grid()
dev.off()

print(summary_rows)
cat("R stylized IAM scenario comparison complete.\n")
