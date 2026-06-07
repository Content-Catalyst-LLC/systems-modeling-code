# geospatial_systems_modeling_workflow.R
# Base R workflow:
# synthetic grid-based exposure and accessibility modeling.

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

simulate_spatial_system <- function(
  scenario,
  grid_size = 25,
  hazard_multiplier = 1.0,
  vulnerability_multiplier = 1.0,
  population_multiplier = 1.0,
  service_capacity_multiplier = 1.0,
  service_shift = 0
) {
  set.seed(42)

  cells <- expand.grid(
    x = seq_len(grid_size),
    y = seq_len(grid_size)
  )

  center_x <- (grid_size + 1) / 2
  center_y <- (grid_size + 1) / 2

  distance_to_center <- sqrt((cells$x - center_x)^2 + (cells$y - center_y)^2)
  distance_to_river <- abs(cells$y - (0.45 * cells$x + 4))

  cells$scenario <- scenario
  cells$population <- round((120 + 500 * exp(-distance_to_center / 7) + rnorm(nrow(cells), 0, 25)) * population_multiplier)
  cells$population[cells$population < 0] <- 0

  cells$hazard <- pmin(1, (exp(-distance_to_river / 3) + runif(nrow(cells), 0, 0.12)) * hazard_multiplier)
  cells$vulnerability <- pmin(1, pmax(0, (0.25 + 0.45 * exp(-distance_to_center / 9) + runif(nrow(cells), -0.1, 0.1)) * vulnerability_multiplier))

  cells$risk_score <- cells$hazard * cells$population * cells$vulnerability

  services <- data.frame(
    scenario = scenario,
    service_id = c("clinic_a", "clinic_b", "clinic_c", "clinic_d"),
    x = c(5 + service_shift, 9, 18 - service_shift, 22),
    y = c(6, 20 - service_shift, 10 + service_shift, 21),
    capacity = c(900, 650, 800, 500) * service_capacity_multiplier
  )

  accessibility <- numeric(nrow(cells))
  nearest_service <- character(nrow(cells))
  nearest_distance <- numeric(nrow(cells))

  for (i in seq_len(nrow(cells))) {
    distances <- sqrt((cells$x[i] - services$x)^2 + (cells$y[i] - services$y)^2)
    impedance <- 1 / (1 + distances^2)
    accessibility[i] <- sum(services$capacity * impedance)

    nearest_index <- which.min(distances)
    nearest_service[i] <- services$service_id[nearest_index]
    nearest_distance[i] <- distances[nearest_index]
  }

  cells$accessibility <- accessibility
  cells$nearest_service <- nearest_service
  cells$nearest_distance <- nearest_distance
  cells$service_gap_score <- cells$population / (cells$accessibility + 1)

  risk_threshold <- quantile(cells$risk_score, 0.85)
  gap_threshold <- quantile(cells$service_gap_score, 0.85)

  cells$priority_zone <- ifelse(
    cells$risk_score >= risk_threshold & cells$service_gap_score >= gap_threshold,
    "high_risk_high_service_gap",
    ifelse(
      cells$risk_score >= risk_threshold,
      "high_risk",
      ifelse(cells$service_gap_score >= gap_threshold, "high_service_gap", "standard_monitoring")
    )
  )

  summary_table <- aggregate(
    cbind(population, risk_score, accessibility, service_gap_score) ~ scenario + priority_zone,
    data = cells,
    FUN = sum
  )

  counts <- aggregate(
    cell_id_count ~ scenario + priority_zone,
    data = transform(cells, cell_id_count = 1),
    FUN = sum
  )

  summary_table <- merge(summary_table, counts, by = c("scenario", "priority_zone"))
  names(summary_table)[names(summary_table) == "cell_id_count"] <- "cell_count"

  list(cells = cells, services = services, summary = summary_table)
}

runs <- list(
  simulate_spatial_system("baseline_spatial_system"),
  simulate_spatial_system("higher_hazard_system", hazard_multiplier = 1.35),
  simulate_spatial_system("high_vulnerability_system", vulnerability_multiplier = 1.35),
  simulate_spatial_system("low_access_system", service_capacity_multiplier = 0.65),
  simulate_spatial_system("population_growth_system", population_multiplier = 1.25),
  simulate_spatial_system("resilient_service_system", hazard_multiplier = 0.90, vulnerability_multiplier = 0.90, service_capacity_multiplier = 1.30, service_shift = 3)
)

all_cells <- do.call(rbind, lapply(runs, function(item) item$cells))
all_services <- do.call(rbind, lapply(runs, function(item) item$services))
all_summary <- do.call(rbind, lapply(runs, function(item) item$summary))

validation_checks <- data.frame(
  check = c(
    "at_least_one_scenario_generated",
    "all_population_nonnegative",
    "all_hazard_between_zero_and_one",
    "all_vulnerability_between_zero_and_one",
    "priority_zones_created"
  ),
  passed = c(
    length(unique(all_cells$scenario)) > 0,
    all(all_cells$population >= 0),
    all(all_cells$hazard >= 0 & all_cells$hazard <= 1),
    all(all_cells$vulnerability >= 0 & all_cells$vulnerability <= 1),
    length(unique(all_cells$priority_zone)) > 0
  )
)

write.csv(
  all_cells,
  file.path(tables_dir, "r_geospatial_grid_risk_access.csv"),
  row.names = FALSE
)

write.csv(
  all_services,
  file.path(tables_dir, "r_geospatial_services.csv"),
  row.names = FALSE
)

write.csv(
  all_summary,
  file.path(tables_dir, "r_geospatial_priority_summary.csv"),
  row.names = FALSE
)

write.csv(
  validation_checks,
  file.path(tables_dir, "r_geospatial_validation_checks.csv"),
  row.names = FALSE
)

baseline <- all_cells[all_cells$scenario == "baseline_spatial_system", ]
grid_size <- max(baseline$x)

png(file.path(figures_dir, "r_geospatial_risk_surface.png"), width = 900, height = 800)
risk_matrix <- matrix(baseline$risk_score, nrow = grid_size, ncol = grid_size)
image(
  x = seq_len(grid_size),
  y = seq_len(grid_size),
  z = risk_matrix,
  xlab = "X coordinate",
  ylab = "Y coordinate",
  main = "Synthetic Geospatial Risk Surface"
)
baseline_services <- all_services[all_services$scenario == "baseline_spatial_system", ]
points(baseline_services$x, baseline_services$y, pch = 19)
grid()
dev.off()

print(all_summary)
print(validation_checks)
cat("R geospatial systems modeling workflow complete.\n")
