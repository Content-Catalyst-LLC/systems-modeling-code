-- infrastructure_systems_modeling_schema.sql
-- SQLite schema and analysis queries for infrastructure systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_infrastructure_system_components;
DROP VIEW IF EXISTS v_infrastructure_dependencies;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_equity_dimensions;
DROP VIEW IF EXISTS v_infrastructure_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS infrastructure_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS equity_dimensions;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS infrastructure_dependencies;
DROP TABLE IF EXISTS infrastructure_system_components;

CREATE TABLE infrastructure_system_components (
  component TEXT PRIMARY KEY,
  system_role TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE infrastructure_dependencies (
  dependency_type TEXT PRIMARY KEY,
  example TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
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
  shock_start INTEGER NOT NULL,
  shock_end INTEGER NOT NULL,
  power_loss_rate REAL NOT NULL,
  power_recovery_rate REAL NOT NULL,
  communications_dependency REAL NOT NULL,
  water_power_dependency REAL NOT NULL,
  water_comms_dependency REAL NOT NULL,
  transport_power_dependency REAL NOT NULL,
  transport_comms_dependency REAL NOT NULL,
  power_demand_base REAL NOT NULL,
  water_demand_base REAL NOT NULL,
  demand_growth REAL NOT NULL,
  dependency_strength REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE equity_dimensions (
  dimension TEXT PRIMARY KEY,
  infrastructure_issue TEXT NOT NULL,
  modeling_implication TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE infrastructure_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO infrastructure_system_components (
  component,
  system_role,
  modeling_representation,
  diagnostic_question
) VALUES
('assets', 'physical_or_digital_components_that_provide_service', 'nodes_links_facilities_equipment_sensors_control_systems_or_service_areas', 'Which_assets_are_structurally_or_operationally_critical'),
('networks', 'connections_that_move_energy_water_people_goods_data_or_services', 'graphs_adjacency_matrices_flow_networks_routes_or_dependency_layers', 'How_does_connectivity_shape_service_and_failure_propagation'),
('load_and_demand', 'use_placed_on_infrastructure_by_people_firms_weather_and_operations', 'demand_curves_load_profiles_origin_destination_flows_or_service_requests', 'Where_does_demand_approach_or_exceed_capacity'),
('capacity', 'maximum_feasible_throughput_or_service_level_under_defined_conditions', 'link_capacity_node_capacity_storage_reserve_margin_or_treatment_capacity', 'Where_are_bottlenecks_and_reserve_margins'),
('condition', 'asset_quality_age_maintenance_state_reliability_and_degradation', 'condition_index_failure_probability_deterioration_curve_or_maintenance_backlog', 'How_does_aging_or_deferred_maintenance_change_risk'),
('interdependence', 'dependence_of_one_infrastructure_system_on_another', 'cross_network_dependency_matrix_coupled_capacity_rule_or_dependency_graph', 'Which_cross_sector_dependencies_create_cascade_risk'),
('disruption', 'shock_stress_overload_failure_attack_disaster_or_outage', 'scenario_failure_event_capacity_reduction_hazard_layer_or_demand_surge', 'How_does_the_system_degrade_under_stress'),
('recovery', 'restoration_of_service_after_disruption', 'repair_sequence_restoration_curve_resource_constraint_or_priority_rule', 'How_quickly_and_fairly_is_critical_service_restored');

INSERT INTO infrastructure_dependencies (
  dependency_type,
  example,
  modeling_representation,
  system_risk
) VALUES
('physical', 'water_pumps_require_electricity_and_fuel_distribution_requires_transport', 'capacity_in_one_system_depends_on_service_availability_in_another', 'cross_sector_service_loss'),
('cyber', 'grid_operations_depend_on_communications_and_control_systems', 'digital_dependency_layer_control_node_failure_or_telemetry_loss', 'loss_of_observability_or_control'),
('geographic', 'roads_substations_fiber_and_water_lines_share_a_floodplain_or_corridor', 'hazard_overlay_and_co_location_exposure_map', 'multiple_systems_fail_from_one_hazard'),
('operational', 'emergency_response_depends_on_roads_dispatch_fuel_hospitals_and_staffing', 'multi_system_restoration_and_response_model', 'delayed_response_and_restoration'),
('economic', 'port_disruption_affects_firms_logistics_employment_and_regional_output', 'input_output_supply_chain_or_economic_loss_model', 'indirect_losses_exceed_direct_damage'),
('institutional', 'separate_agencies_must_coordinate_restoration_funding_and_public_communication', 'decision_rules_coordination_delays_and_governance_scenarios', 'coordination_failure');

INSERT INTO modeling_approaches (
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('network_modeling', 'connectivity_flow_redundancy_bottlenecks_and_cascading_failure', 'centrality_capacity_connectivity_cascade_size_and_service_loss', 'centrality_does_not_always_equal_real_world_criticality'),
('system_dynamics', 'maintenance_investment_demand_capacity_and_long_term_feedback', 'stock_trajectories_backlog_demand_capacity_gap_and_loop_dominance', 'aggregate_models_can_hide_spatial_and_social_inequality'),
('discrete_event_simulation', 'operational_timing_queues_repair_sequences_terminals_and_emergency_response', 'waiting_time_throughput_resource_utilization_and_restoration_time', 'event_rules_require_operational_evidence'),
('agent_based_modeling', 'user_behavior_rerouting_evacuation_demand_response_and_adaptation', 'agent_outcomes_emergent_congestion_compliance_and_adaptive_response', 'behavior_rules_can_encode_weak_assumptions'),
('geospatial_risk_modeling', 'hazard_exposure_service_areas_climate_risk_and_environmental_justice', 'hotspots_exposed_assets_vulnerable_users_and_service_area_gaps', 'spatial_precision_can_create_false_confidence'),
('digital_twin_modeling', 'real_time_monitoring_predictive_maintenance_and_scenario_operations', 'asset_state_anomaly_detection_operational_performance_and_scenario_response', 'poor_data_quality_can_create_false_control');

INSERT INTO scenario_definitions (
  scenario,
  n_steps,
  shock_start,
  shock_end,
  power_loss_rate,
  power_recovery_rate,
  communications_dependency,
  water_power_dependency,
  water_comms_dependency,
  transport_power_dependency,
  transport_comms_dependency,
  power_demand_base,
  water_demand_base,
  demand_growth,
  dependency_strength,
  description
) VALUES
('baseline_cascade', 80, 20, 36, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25, 78, 58, 0.35, 0.85, 'Baseline interdependent infrastructure cascade'),
('larger_power_loss', 80, 20, 36, 0.055, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25, 78, 58, 0.35, 0.85, 'Larger power loss produces deeper cascade'),
('faster_recovery', 80, 20, 36, 0.035, 0.045, 0.72, 0.55, 0.25, 0.30, 0.25, 78, 58, 0.35, 0.85, 'Faster restoration improves recovery trajectory'),
('high_digital_dependency', 80, 20, 36, 0.035, 0.025, 0.88, 0.55, 0.32, 0.30, 0.35, 78, 58, 0.35, 0.85, 'Higher communications dependency changes cascade shape'),
('longer_shock', 80, 20, 48, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25, 78, 58, 0.35, 0.85, 'Longer disruption extends service loss'),
('stronger_interdependence', 80, 20, 36, 0.035, 0.025, 0.72, 0.62, 0.30, 0.38, 0.30, 78, 58, 0.35, 1.00, 'Stronger cross-system dependency'),
('lower_demand_growth', 80, 20, 36, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25, 78, 58, 0.18, 0.85, 'Lower demand growth reduces load pressure'),
('resilient_backup', 80, 20, 36, 0.028, 0.040, 0.55, 0.45, 0.18, 0.22, 0.18, 78, 58, 0.25, 0.65, 'Backup capacity and lower dependencies improve resilience');

INSERT INTO equity_dimensions (
  dimension,
  infrastructure_issue,
  modeling_implication,
  professional_caution
) VALUES
('service_access', 'people_have_unequal_access_to_transportation_broadband_water_energy_and_public_facilities', 'measure_service_quality_by_place_population_cost_and_reliability', 'nominal_presence_does_not_mean_usable_service'),
('affordability', 'rates_fares_fees_and_connection_costs_burden_households_differently', 'model_cost_burden_and_affordability_thresholds', 'investment_can_improve_assets_while_increasing_household_burden'),
('exposure', 'some_communities_face_greater_flood_heat_outage_pollution_or_industrial_risk', 'map_hazard_exposure_and_cumulative_burden', 'aggregate_risk_can_hide_hotspots'),
('reliability', 'service_interruptions_may_be_more_frequent_or_longer_in_some_areas', 'track_outage_duration_restoration_priority_and_service_quality', 'average_outage_metrics_can_mask_vulnerability'),
('displacement', 'infrastructure_investment_can_increase_land_values_and_relocation_pressure', 'include_affordability_tenure_business_displacement_and_protections', 'project_benefits_can_bypass_current_residents'),
('procedural_justice', 'affected_communities_may_be_excluded_from_infrastructure_decisions', 'use_participatory_modeling_and_transparent_assumptions', 'models_should_support_public_reasoning_not_replace_it'),
('critical_dependence', 'some_users_depend_on_power_water_transport_or_communications_for_medical_or_safety_needs', 'identify_critical_facilities_and_high_dependency_households', 'restoration_priorities_are_value_laden');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('power', 0, 1, 'Power service availability should remain within 0 to 1'),
('communications', 0, 1, 'Communications service availability should remain within 0 to 1'),
('water', 0, 1, 'Water service availability should remain within 0 to 1'),
('transport', 0, 1, 'Transport service availability should remain within 0 to 1'),
('composite_service', 0, 1, 'Composite service availability should remain within 0 to 1'),
('unmet_service', 0, 1, 'Unmet service share should remain within 0 to 1'),
('total_unmet_service', 0, 1000000, 'Cumulative unmet service should remain nonnegative and finite'),
('capacity', 0, 1000000, 'Capacity values should remain nonnegative and finite');

INSERT INTO infrastructure_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_cascade', 'illustrative_power_loss_rate', 0.035, 'Baseline service loss rate'),
('larger_power_loss', 'illustrative_power_loss_rate', 0.055, 'Larger power service loss rate'),
('faster_recovery', 'illustrative_power_recovery_rate', 0.045, 'Faster restoration rate'),
('high_digital_dependency', 'illustrative_communications_dependency', 0.88, 'Higher digital dependency'),
('longer_shock', 'illustrative_shock_end', 48, 'Longer disruption duration'),
('stronger_interdependence', 'illustrative_dependency_strength', 1.00, 'Stronger cross-system dependency'),
('lower_demand_growth', 'illustrative_demand_growth', 0.18, 'Lower infrastructure demand growth'),
('resilient_backup', 'illustrative_dependency_strength', 0.65, 'Lower dependency through backup and redundancy');

CREATE VIEW v_infrastructure_system_components AS
SELECT component, system_role, modeling_representation, diagnostic_question
FROM infrastructure_system_components
ORDER BY component;

CREATE VIEW v_infrastructure_dependencies AS
SELECT dependency_type, example, modeling_representation, system_risk
FROM infrastructure_dependencies
ORDER BY dependency_type;

CREATE VIEW v_modeling_approaches AS
SELECT approach, best_suited_for, key_diagnostic, professional_caution
FROM modeling_approaches
ORDER BY approach;

CREATE VIEW v_scenario_definitions AS
SELECT *
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_equity_dimensions AS
SELECT dimension, infrastructure_issue, modeling_implication, professional_caution
FROM equity_dimensions
ORDER BY dimension;

CREATE VIEW v_infrastructure_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM infrastructure_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_infrastructure_system_components;
SELECT * FROM v_infrastructure_dependencies;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_equity_dimensions;
SELECT * FROM v_infrastructure_metric_summary;
SELECT * FROM v_validation_targets;
