-- environmental_systems_modeling_schema.sql
-- SQLite schema and analysis queries for environmental systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_environmental_system_components;
DROP VIEW IF EXISTS v_environmental_feedback_loops;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_environmental_justice_dimensions;
DROP VIEW IF EXISTS v_environmental_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS environmental_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS environmental_justice_dimensions;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS environmental_feedback_loops;
DROP TABLE IF EXISTS environmental_system_components;

CREATE TABLE environmental_system_components (
  component TEXT PRIMARY KEY,
  system_role TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE environmental_feedback_loops (
  feedback_loop TEXT PRIMARY KEY,
  loop_type TEXT NOT NULL,
  environmental_mechanism TEXT NOT NULL,
  system_risk TEXT NOT NULL
);

CREATE TABLE modeling_approaches (
  approach TEXT PRIMARY KEY,
  best_suited_for TEXT NOT NULL,
  key_diagnostic TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  n_steps INTEGER NOT NULL,
  initial_stock REAL NOT NULL,
  carrying_capacity REAL NOT NULL,
  growth_rate REAL NOT NULL,
  extraction_rate REAL NOT NULL,
  restoration_rate REAL NOT NULL,
  disturbance_step INTEGER NOT NULL,
  disturbance_size REAL NOT NULL,
  initial_concentration REAL NOT NULL,
  baseline_load REAL NOT NULL,
  decay_rate REAL NOT NULL,
  flow_rate REAL NOT NULL,
  exposure_weight REAL NOT NULL,
  intervention_step INTEGER NOT NULL,
  load_reduction_fraction REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE environmental_justice_dimensions (
  dimension TEXT PRIMARY KEY,
  environmental_issue TEXT NOT NULL,
  modeling_implication TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE environmental_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO environmental_system_components (
  component,
  system_role,
  modeling_representation,
  diagnostic_question
) VALUES
('environmental_stocks', 'accumulated_quantities_such_as_water_biomass_carbon_pollutants_or_habitat', 'state_variables_updated_by_inflows_and_outflows', 'Which_accumulated_conditions_shape_current_and_future_risk'),
('flows', 'movement_transformation_extraction_recharge_decay_or_restoration', 'rates_fluxes_transition_rules_or_flow_networks', 'Which_processes_increase_decrease_or_move_environmental_stocks'),
('stressors', 'pressures_such_as_pollution_heat_drought_extraction_or_land_conversion', 'forcing_variables_scenario_inputs_or_exposure_fields', 'Which_pressures_drive_environmental_change'),
('receptors', 'people_species_ecosystems_assets_or_places_affected_by_stressors', 'population_groups_ecological_units_assets_or_spatial_layers', 'Who_or_what_is_exposed_or_affected'),
('pathways', 'routes_through_which_stressors_move_and_create_exposure', 'air_water_soil_food_web_hydrological_or_network_pathways', 'How_does_harm_travel_from_source_to_receptor'),
('thresholds', 'conditions_where_response_changes_sharply_or_resilience_declines', 'critical_values_nonlinear_functions_or_regime_states', 'Where_can_environmental_response_shift_abruptly'),
('scenarios', 'plausible_futures_for_climate_policy_land_use_or_behavior', 'alternative_parameter_sets_storylines_or_simulation_ensembles', 'How_do_outcomes_change_under_alternative_futures'),
('interventions', 'actions_to_reduce_harm_restore_function_or_improve_resilience', 'emission_reduction_restoration_adaptation_regulation_or_infrastructure', 'Which_actions_change_system_trajectory');

INSERT INTO environmental_feedback_loops (
  feedback_loop,
  loop_type,
  environmental_mechanism,
  system_risk
) VALUES
('vegetation_water', 'reinforcing_or_balancing', 'vegetation_supports_infiltration_microclimate_and_water_retention', 'vegetation_loss_can_accelerate_drying_and_erosion'),
('ice_albedo', 'reinforcing', 'ice_loss_reduces_reflectivity_and_increases_absorbed_heat', 'warming_can_accelerate_cryosphere_change'),
('fire_fuel', 'reinforcing', 'fire_changes_vegetation_and_fuel_structure_altering_future_fire_risk', 'landscapes_can_shift_to_more_severe_fire_regimes'),
('nutrient_algae', 'reinforcing', 'nutrients_increase_algal_growth_and_reduce_oxygen', 'water_bodies_can_shift_to_degraded_regimes'),
('predator_prey', 'balancing', 'predators_regulate_prey_and_prey_availability_affects_predators', 'loss_of_key_species_can_trigger_trophic_cascades'),
('policy_behavior', 'reinforcing_or_balancing', 'regulation_incentives_trust_and_compliance_shape_environmental_outcomes', 'poor_legitimacy_can_reduce_compliance_and_effectiveness'),
('restoration_resilience', 'reinforcing', 'restoration_improves_ecological_function_which_improves_recovery_capacity', 'underinvestment_can_lock_systems_into_degraded_states');

INSERT INTO modeling_approaches (
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('system_dynamics', 'accumulation_feedback_delay_resource_depletion_pollution_and_restoration', 'stock_trajectories_loop_dominance_thresholds_and_policy_response', 'feedback_structure_can_be_disputed_or_incomplete'),
('gis_spatial_modeling', 'land_use_exposure_habitat_flood_risk_heat_and_environmental_justice', 'spatial_distribution_overlap_hotspots_and_vulnerability', 'high_resolution_maps_can_create_false_precision'),
('hydrological_modeling', 'runoff_groundwater_flood_drought_water_quality_and_watersheds', 'flow_storage_recharge_peak_discharge_and_pollutant_load', 'watershed_boundaries_may_not_match_policy_boundaries'),
('atmospheric_modeling', 'air_quality_dispersion_emissions_smoke_and_chemical_transformation', 'concentration_deposition_exposure_and_source_contribution', 'meteorology_and_chemistry_assumptions_drive_results'),
('ecological_modeling', 'species_habitats_food_webs_biodiversity_disturbance_and_restoration', 'population_habitat_suitability_connectivity_and_resilience', 'ecological_interactions_are_often_uncertain'),
('integrated_assessment', 'economy_energy_environment_climate_land_use_and_policy_pathways', 'emissions_temperature_damages_investment_and_tradeoffs', 'damage_functions_discounting_and_values_must_be_explicit'),
('participatory_modeling', 'contested_environmental_decisions_local_knowledge_and_environmental_justice', 'stakeholder_assumptions_pathways_values_and_decision_legitimacy', 'participation_must_be_meaningful_not_symbolic');

INSERT INTO scenario_definitions (
  scenario,
  n_steps,
  initial_stock,
  carrying_capacity,
  growth_rate,
  extraction_rate,
  restoration_rate,
  disturbance_step,
  disturbance_size,
  initial_concentration,
  baseline_load,
  decay_rate,
  flow_rate,
  exposure_weight,
  intervention_step,
  load_reduction_fraction,
  description
) VALUES
('baseline_pressure', 120, 70, 100, 0.065, 0.040, 0.010, 65, 12, 12, 4.2, 0.035, 2.5, 1.0, 70, 0.00, 'Baseline resource pressure and pollutant loading'),
('high_extraction', 120, 70, 100, 0.065, 0.065, 0.010, 65, 12, 12, 4.2, 0.035, 2.5, 1.0, 70, 0.00, 'Higher extraction pressure reduces environmental stock'),
('restoration_investment', 120, 70, 100, 0.065, 0.040, 0.035, 65, 12, 12, 4.2, 0.035, 2.5, 1.0, 70, 0.25, 'Restoration and moderate load intervention'),
('larger_disturbance', 120, 70, 100, 0.065, 0.040, 0.010, 65, 24, 12, 4.2, 0.035, 2.5, 1.0, 70, 0.25, 'Larger ecological disturbance event'),
('lower_growth', 120, 70, 100, 0.040, 0.040, 0.010, 65, 12, 12, 4.2, 0.035, 2.5, 1.0, 70, 0.25, 'Lower regeneration rate and moderate intervention'),
('strong_intervention', 120, 70, 100, 0.065, 0.040, 0.020, 65, 12, 12, 4.2, 0.035, 2.5, 1.0, 70, 0.50, 'Stronger pollution load reduction and restoration'),
('high_exposure_weight', 120, 70, 100, 0.065, 0.040, 0.010, 65, 12, 12, 4.2, 0.035, 2.5, 1.6, 70, 0.25, 'Higher exposure vulnerability despite intervention'),
('low_flow_persistence', 120, 70, 100, 0.065, 0.040, 0.010, 65, 12, 12, 4.2, 0.035, 1.2, 1.0, 70, 0.25, 'Lower flushing increases pollutant persistence');

INSERT INTO environmental_justice_dimensions (
  dimension,
  environmental_issue,
  modeling_implication,
  professional_caution
) VALUES
('exposure', 'some_groups_face_higher_pollution_heat_flood_or_hazard_exposure', 'disaggregate_exposure_by_place_population_and_vulnerability', 'aggregate_results_can_hide_hotspots'),
('vulnerability', 'health_income_housing_age_work_and_access_affect_harm', 'represent_sensitivity_and_adaptive_capacity_not_just_hazard', 'do_not_treat_all_receptors_as_equally_sensitive'),
('historical_burden', 'past_siting_segregation_extraction_and_disinvestment_shape_present_risk', 'include_historical_context_and_cumulative_burden', 'current_snapshot_data_can_miss_structural_causes'),
('benefit_distribution', 'environmental_improvements_may_benefit_some_more_than_others', 'track_who_receives_protection_restoration_and_investment', 'project_benefits_can_be_uneven_or_displacing'),
('procedural_justice', 'affected_communities_may_be_excluded_from_model_design', 'use_participatory_modeling_and_transparent_assumptions', 'community_knowledge_should_not_be_tokenized'),
('intergenerational_justice', 'environmental_damage_and_climate_risk_persist_across_generations', 'model_long_term_outcomes_and_future_burdens', 'short_discounted_horizons_can_hide_future_harm');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('stock', 0, 1000000, 'Environmental stock should remain nonnegative and finite'),
('regeneration', 0, 1000000, 'Regeneration should remain nonnegative and finite'),
('extraction', 0, 1000000, 'Extraction should remain nonnegative and finite'),
('restoration', 0, 1000000, 'Restoration should remain nonnegative and finite'),
('resilience_index', 0, 1000000, 'Resilience index should remain nonnegative and finite'),
('concentration', 0, 1000000, 'Pollutant concentration should remain nonnegative and finite'),
('exposure', 0, 1000000, 'Exposure should remain nonnegative and finite'),
('cumulative_exposure', 0, 1000000, 'Cumulative exposure should remain nonnegative and finite');

INSERT INTO environmental_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_pressure', 'illustrative_extraction_rate', 0.040, 'Baseline extraction pressure'),
('high_extraction', 'illustrative_extraction_rate', 0.065, 'Higher extraction pressure'),
('restoration_investment', 'illustrative_restoration_rate', 0.035, 'Higher restoration investment'),
('larger_disturbance', 'illustrative_disturbance_size', 24.0, 'Larger disturbance event'),
('lower_growth', 'illustrative_growth_rate', 0.040, 'Lower regeneration capacity'),
('strong_intervention', 'illustrative_load_reduction_fraction', 0.50, 'Stronger source load reduction'),
('high_exposure_weight', 'illustrative_exposure_weight', 1.60, 'Higher exposure vulnerability'),
('low_flow_persistence', 'illustrative_flow_rate', 1.20, 'Lower flushing and greater persistence');

CREATE VIEW v_environmental_system_components AS
SELECT
  component,
  system_role,
  modeling_representation,
  diagnostic_question
FROM environmental_system_components
ORDER BY component;

CREATE VIEW v_environmental_feedback_loops AS
SELECT
  feedback_loop,
  loop_type,
  environmental_mechanism,
  system_risk
FROM environmental_feedback_loops
ORDER BY feedback_loop;

CREATE VIEW v_modeling_approaches AS
SELECT
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
FROM modeling_approaches
ORDER BY approach;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  n_steps,
  initial_stock,
  carrying_capacity,
  growth_rate,
  extraction_rate,
  restoration_rate,
  disturbance_step,
  disturbance_size,
  initial_concentration,
  baseline_load,
  decay_rate,
  flow_rate,
  exposure_weight,
  intervention_step,
  load_reduction_fraction,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_environmental_justice_dimensions AS
SELECT
  dimension,
  environmental_issue,
  modeling_implication,
  professional_caution
FROM environmental_justice_dimensions
ORDER BY dimension;

CREATE VIEW v_environmental_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM environmental_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT
  metric,
  target_low,
  target_high,
  notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_environmental_system_components;
SELECT * FROM v_environmental_feedback_loops;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_environmental_justice_dimensions;
SELECT * FROM v_environmental_metric_summary;
SELECT * FROM v_validation_targets;
