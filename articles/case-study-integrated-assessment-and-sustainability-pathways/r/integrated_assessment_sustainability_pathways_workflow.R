# integrated_assessment_sustainability_pathways_workflow.R
# Base R workflow: energy, emissions, climate stress, adaptation, land, water, equity, and sustainability pathways.

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

pathways <- read.csv(file.path(data_dir, "sustainability_pathways.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(data_dir, "model_assumptions.csv"), stringsAsFactors = FALSE)
diagnostics <- read.csv(file.path(data_dir, "diagnostic_definitions.csv"), stringsAsFactors = FALSE)

clamp <- function(value) {
  max(0, min(1, value))
}

simulate_pathway <- function(row, years = 40) {
  demand <- 1.00
  clean_share <- 0.22
  cumulative_emissions <- 0
  adaptation_capacity <- 0.28
  rows <- data.frame()

  for (year in 0:years) {
    clean_growth <- ifelse(year < 15, row$clean_growth_early, row$clean_growth_late)
    emissions_intensity <- 0.72 * (1 - clean_share)
    annual_emissions <- demand * emissions_intensity
    cumulative_emissions <- cumulative_emissions + annual_emissions

    climate_stress <- clamp(0.18 + 0.018 * cumulative_emissions)
    adaptation_capacity <- clamp(adaptation_capacity + row$adaptation_investment - 0.010 * climate_stress)

    climate_damages <- 0.42 * climate_stress^2 * (1 - adaptation_capacity)
    transition_cost <- row$transition_cost_factor * clean_growth * 4.0

    land_pressure <- clamp(0.22 + 0.18 * demand + 0.25 * clean_share - 0.18 * row$ecological_constraint)
    water_stress <- clamp(0.25 + 0.16 * demand + 0.34 * climate_stress - 0.14 * adaptation_capacity)
    equity_score <- clamp(0.42 + 0.36 * row$equity_support - 0.18 * transition_cost - 0.22 * climate_damages)

    sustainability_score <-
      0.24 * equity_score +
      0.20 * clean_share +
      0.16 * adaptation_capacity -
      0.15 * annual_emissions -
      0.10 * climate_damages -
      0.08 * land_pressure -
      0.07 * water_stress

    rows <- rbind(
      rows,
      data.frame(
        pathway = row$pathway,
        year = year,
        energy_demand = demand,
        clean_energy_share = clean_share,
        emissions_intensity = emissions_intensity,
        annual_emissions = annual_emissions,
        cumulative_emissions = cumulative_emissions,
        climate_stress = climate_stress,
        adaptation_capacity = adaptation_capacity,
        climate_damages = climate_damages,
        transition_cost = transition_cost,
        land_pressure = land_pressure,
        water_stress = water_stress,
        equity_score = equity_score,
        sustainability_score = sustainability_score,
        land_breach = land_pressure > 0.72,
        water_breach = water_stress > 0.72,
        equity_breach = equity_score < 0.45,
        stringsAsFactors = FALSE
      )
    )

    demand <- demand * (1 + row$demand_growth - row$efficiency_gain)
    clean_share <- clamp(clean_share + clean_growth)
  }

  rows
}

all_runs <- data.frame()

for (i in seq_len(nrow(pathways))) {
  all_runs <- rbind(all_runs, simulate_pathway(pathways[i, ]))
}

summary_rows <- data.frame()

for (pathway_name in unique(all_runs$pathway)) {
  subset_rows <- all_runs[all_runs$pathway == pathway_name, ]

  summary_rows <- rbind(
    summary_rows,
    data.frame(
      pathway = pathway_name,
      final_clean_energy_share = subset_rows$clean_energy_share[nrow(subset_rows)],
      cumulative_emissions = subset_rows$cumulative_emissions[nrow(subset_rows)],
      average_climate_damages = mean(subset_rows$climate_damages),
      average_transition_cost = mean(subset_rows$transition_cost),
      average_land_pressure = mean(subset_rows$land_pressure),
      average_water_stress = mean(subset_rows$water_stress),
      average_equity_score = mean(subset_rows$equity_score),
      final_adaptation_capacity = subset_rows$adaptation_capacity[nrow(subset_rows)],
      constraint_breach_count = sum(subset_rows$land_breach | subset_rows$water_breach | subset_rows$equity_breach),
      average_sustainability_score = mean(subset_rows$sustainability_score),
      stringsAsFactors = FALSE
    )
  )
}

summary_rows <- summary_rows[order(-summary_rows$average_sustainability_score), ]

validation_checks <- data.frame(
  check = c(
    "pathway_runs_created",
    "clean_share_normalized",
    "adaptation_capacity_normalized",
    "equity_score_normalized",
    "land_pressure_normalized",
    "water_stress_normalized",
    "emissions_nonnegative",
    "summary_created"
  ),
  passed = c(
    nrow(all_runs) > 0,
    all(all_runs$clean_energy_share >= 0 & all_runs$clean_energy_share <= 1),
    all(all_runs$adaptation_capacity >= 0 & all_runs$adaptation_capacity <= 1),
    all(all_runs$equity_score >= 0 & all_runs$equity_score <= 1),
    all(all_runs$land_pressure >= 0 & all_runs$land_pressure <= 1),
    all(all_runs$water_stress >= 0 & all_runs$water_stress <= 1),
    all(all_runs$annual_emissions >= 0),
    nrow(summary_rows) == nrow(pathways)
  )
)

write.csv(pathways, file.path(tables_dir, "r_sustainability_pathways.csv"), row.names = FALSE)
write.csv(all_runs, file.path(tables_dir, "r_integrated_assessment_timeseries.csv"), row.names = FALSE)
write.csv(summary_rows, file.path(tables_dir, "r_integrated_assessment_summary.csv"), row.names = FALSE)
write.csv(assumptions, file.path(tables_dir, "r_model_assumptions.csv"), row.names = FALSE)
write.csv(diagnostics, file.path(tables_dir, "r_diagnostic_definitions.csv"), row.names = FALSE)
write.csv(validation_checks, file.path(tables_dir, "r_integrated_assessment_validation_checks.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_integrated_assessment_emissions_pathways.png"), width = 1000, height = 700)
plot(
  NULL,
  xlim = range(all_runs$year),
  ylim = range(all_runs$cumulative_emissions),
  xlab = "Year",
  ylab = "Cumulative Emissions",
  main = "Integrated Assessment Sustainability Pathways"
)

for (pathway_name in unique(all_runs$pathway)) {
  subset_rows <- all_runs[all_runs$pathway == pathway_name, ]
  lines(subset_rows$year, subset_rows$cumulative_emissions, lwd = 2)
}

legend("topleft", legend = unique(all_runs$pathway), lwd = 2, cex = 0.70)
grid()
dev.off()

print(summary_rows)
print(validation_checks)
cat("R integrated assessment sustainability pathways workflow complete.\n")
