-- geospatial_systems_modeling_schema.sql
-- SQLite schema and analysis queries for geospatial systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_spatial_components;
DROP VIEW IF EXISTS v_spatial_data_structures;
DROP VIEW IF EXISTS v_scale_boundary_risks;
DROP VIEW IF EXISTS v_spatial_ethics_register;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_spatial_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS spatial_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS spatial_ethics_register;
DROP TABLE IF EXISTS scale_boundary_risks;
DROP TABLE IF EXISTS spatial_data_structures;
DROP TABLE IF EXISTS spatial_components;

CREATE TABLE spatial_components (
  component TEXT PRIMARY KEY,
  function TEXT NOT NULL,
  example TEXT NOT NULL,
  modeling_risk TEXT NOT NULL
);

CREATE TABLE spatial_data_structures (
  data_structure TEXT PRIMARY KEY,
  represents TEXT NOT NULL,
  systems_modeling_use TEXT NOT NULL,
  risk TEXT NOT NULL
);

CREATE TABLE scale_boundary_risks (
  scale_issue TEXT PRIMARY KEY,
  modeling_problem TEXT NOT NULL,
  responsible_practice TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE spatial_ethics_register (
  ethical_issue TEXT PRIMARY KEY,
  risk TEXT NOT NULL,
  responsible_practice TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  grid_size INTEGER NOT NULL,
  hazard_multiplier REAL NOT NULL,
  vulnerability_multiplier REAL NOT NULL,
  population_multiplier REAL NOT NULL,
  service_capacity_multiplier REAL NOT NULL,
  service_shift INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE spatial_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO spatial_components VALUES
('spatial_units', 'define_the_basic_geography_of_analysis', 'grid_cells_parcels_census_tracts_watersheds_road_segments_facilities_or_habitat_patches', 'wrong_unit_choice_changes_results'),
('attributes', 'describe_properties_of_spatial_units', 'population_elevation_income_land_cover_demand_capacity_exposure_or_asset_condition', 'attribute_error_distorts_spatial_outputs'),
('spatial_relationships', 'define_adjacency_distance_containment_overlap_flow_or_connectivity', 'nearby_neighborhoods_upstream_areas_connected_roads_or_service_catchments', 'relationship_assumptions_drive_model_behavior'),
('processes', 'represent_change_movement_diffusion_accumulation_failure_or_interaction', 'flood_spread_migration_congestion_disease_transmission_or_pollution_transport', 'process_simplification_hides_dynamics'),
('constraints', 'limit_feasible_movement_access_development_service_or_intervention', 'terrain_jurisdiction_budget_road_capacity_zoning_or_watershed_boundaries', 'constraints_may_be_ignored_or_misrepresented'),
('scenarios', 'test_alternative_futures_or_interventions', 'new_transit_line_clinic_placement_flood_protection_or_land_use_change', 'scenario_framing_controls_interpretation'),
('outputs', 'summarize_spatial_system_behavior', 'risk_surface_access_score_vulnerability_index_service_gap_or_hotspot', 'outputs_can_look_more_precise_than_evidence_supports');

INSERT INTO spatial_data_structures VALUES
('points', 'discrete_locations', 'facilities_sensors_incidents_wells_hospitals_schools_or_failures', 'may_omit_service_area_capacity_or_location_uncertainty'),
('lines', 'linear_features_and_connections', 'roads_rivers_pipelines_transmission_lines_or_transit_routes', 'connectivity_and_direction_may_be_misrepresented'),
('polygons', 'bounded_areas', 'neighborhoods_parcels_watersheds_jurisdictions_or_land_use_zones', 'boundaries_may_be_arbitrary_or_politically_constructed'),
('raster_grids', 'continuous_surfaces_divided_into_cells', 'elevation_temperature_flood_depth_pollution_land_cover_or_exposure', 'resolution_can_create_false_precision_or_hide_variation'),
('networks', 'nodes_edges_connectivity_direction_capacity_and_flow', 'transportation_utilities_supply_chains_communication_or_ecological_corridors', 'topological_errors_can_distort_accessibility_or_cascade_analysis'),
('time_enabled_spatial_data', 'spatial_observations_over_time', 'mobility_land_cover_change_weather_disease_or_sensor_monitoring', 'temporal_mismatch_can_distort_causal_interpretation'),
('spatial_interaction_matrices', 'relationships_among_places', 'commuting_migration_trade_flows_adjacency_or_influence', 'interaction_weights_embed_strong_assumptions');

INSERT INTO scale_boundary_risks VALUES
('aggregation', 'combining_small_units_into_larger_areas_can_hide_local_variation', 'compare_results_across_multiple_spatial_scales_when_possible', 'do_conclusions_change_when_units_are_aggregated'),
('modifiable_areal_unit_problem', 'results_can_change_when_boundaries_or_zones_are_redrawn', 'test_sensitivity_to_spatial_unit_definitions', 'are_results_boundary_dependent'),
('resolution_mismatch', 'input_layers_may_have_different_spatial_resolutions', 'document_resampling_interpolation_and_scale_harmonization', 'which_layer_sets_the_effective_resolution'),
('boundary_mismatch', 'administrative_boundaries_may_not_match_functional_systems', 'use_functional_regions_such_as_watersheds_travel_sheds_ecosystems_or_service_areas_when_appropriate', 'does_the_model_boundary_match_the_process'),
('edge_effects', 'processes_crossing_the_model_boundary_may_be_ignored', 'use_buffers_regional_context_or_boundary_condition_assumptions', 'what_cross_boundary_processes_are_missing'),
('temporal_scale_mismatch', 'spatial_layers_may_describe_different_time_periods', 'align_timeframes_or_explicitly_flag_temporal_inconsistency', 'are_input_layers_from_compatible_time_periods');

INSERT INTO spatial_ethics_register VALUES
('visibility_and_invisibility', 'unmapped_communities_informal_systems_or_lived_experiences_may_be_ignored', 'ask_what_is_missing_and_supplement_data_with_local_knowledge_where_appropriate', 'available_data_are_treated_as_complete_reality'),
('surveillance', 'fine_grained_spatial_data_can_expose_sensitive_behavior_or_locations', 'use_privacy_protection_aggregation_minimization_and_clear_authority', 'outputs_identify_people_households_or_sensitive_sites_unnecessarily'),
('stigmatization', 'risk_maps_can_label_places_as_deficient_or_dangerous', 'frame_outputs_around_structural_conditions_not_community_blame', 'places_are_named_as_problems_without_context'),
('boundary_power', 'administrative_boundaries_can_shape_eligibility_funding_or_attention', 'explain_boundary_choices_and_test_alternatives', 'one_boundary_scheme_controls_all_conclusions'),
('false_objectivity', 'maps_can_make_contestable_assumptions_look_factual', 'document_assumptions_weights_data_sources_and_uncertainty', 'map_design_hides_uncertainty_and_value_choices'),
('extractive_mapping', 'communities_may_be_studied_without_benefit_or_consent', 'use_participatory_methods_and_reciprocal_data_practices_where_possible', 'local_knowledge_is_not_consulted'),
('unequal_data_quality', 'some_places_may_have_better_data_because_they_are_better_resourced', 'assess_whether_data_quality_itself_reflects_inequality', 'low_data_quality_places_are_treated_as_low_need_places');

INSERT INTO scenario_definitions VALUES
('baseline_spatial_system', 25, 1.00, 1.00, 1.00, 1.00, 0, 'Baseline synthetic spatial exposure and access system'),
('higher_hazard_system', 25, 1.35, 1.00, 1.00, 1.00, 0, 'Higher hazard intensity increases exposure pressure'),
('high_vulnerability_system', 25, 1.00, 1.35, 1.00, 1.00, 0, 'Higher vulnerability raises social risk burden'),
('low_access_system', 25, 1.00, 1.00, 1.00, 0.65, 0, 'Lower service capacity creates larger service gaps'),
('population_growth_system', 25, 1.00, 1.00, 1.25, 1.00, 0, 'Higher population increases exposure and access demand'),
('resilient_service_system', 25, 0.90, 0.90, 1.00, 1.30, 3, 'Reduced hazard and vulnerability plus shifted service placement improve resilience');

INSERT INTO validation_targets VALUES
('cell_count', 1, 1000000, 'Grid should generate a positive number of cells'),
('population', 0, 100000000, 'Population should remain nonnegative'),
('hazard', 0, 1, 'Hazard scores should remain in unit interval'),
('vulnerability', 0, 1, 'Vulnerability scores should remain in unit interval'),
('risk_score', 0, 100000000, 'Risk score should remain nonnegative'),
('accessibility', 0, 100000000, 'Accessibility should remain nonnegative'),
('service_gap_score', 0, 100000000, 'Service gap score should remain nonnegative'),
('priority_zone_count', 1, 1000000, 'Priority classification should produce at least one group');

INSERT INTO spatial_metrics VALUES
(NULL, 'baseline_spatial_system', 'illustrative_total_risk', 1000.0, 'Illustrative baseline total risk'),
(NULL, 'higher_hazard_system', 'illustrative_total_risk', 1350.0, 'Illustrative higher hazard total risk'),
(NULL, 'high_vulnerability_system', 'illustrative_total_risk', 1350.0, 'Illustrative higher vulnerability total risk'),
(NULL, 'low_access_system', 'illustrative_service_gap', 1500.0, 'Illustrative lower access service gap'),
(NULL, 'resilient_service_system', 'illustrative_service_gap', 650.0, 'Illustrative resilient service gap');

CREATE VIEW v_spatial_components AS
SELECT component, function, example, modeling_risk
FROM spatial_components
ORDER BY component;

CREATE VIEW v_spatial_data_structures AS
SELECT data_structure, represents, systems_modeling_use, risk
FROM spatial_data_structures
ORDER BY data_structure;

CREATE VIEW v_scale_boundary_risks AS
SELECT scale_issue, modeling_problem, responsible_practice, diagnostic_question
FROM scale_boundary_risks
ORDER BY scale_issue;

CREATE VIEW v_spatial_ethics_register AS
SELECT ethical_issue, risk, responsible_practice, warning_sign
FROM spatial_ethics_register
ORDER BY ethical_issue;

CREATE VIEW v_scenario_definitions AS
SELECT *
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_spatial_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM spatial_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_spatial_components;
SELECT * FROM v_spatial_data_structures;
SELECT * FROM v_scale_boundary_risks;
SELECT * FROM v_spatial_ethics_register;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_spatial_metric_summary;
SELECT * FROM v_validation_targets;
