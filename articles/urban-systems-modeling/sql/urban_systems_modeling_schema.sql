-- urban_systems_modeling_schema.sql
-- SQLite schema and analysis queries for urban systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_urban_system_components;
DROP VIEW IF EXISTS v_urban_feedback_loops;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_equity_dimensions;
DROP VIEW IF EXISTS v_urban_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS urban_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS equity_dimensions;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS urban_feedback_loops;
DROP TABLE IF EXISTS urban_system_components;

CREATE TABLE urban_system_components (
  component TEXT PRIMARY KEY,
  system_role TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE urban_feedback_loops (
  feedback_loop TEXT PRIMARY KEY,
  loop_type TEXT NOT NULL,
  urban_mechanism TEXT NOT NULL,
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
  initial_population REAL NOT NULL,
  initial_housing REAL NOT NULL,
  initial_transport REAL NOT NULL,
  initial_service_capacity REAL NOT NULL,
  growth_pressure REAL NOT NULL,
  accessibility_attraction REAL NOT NULL,
  congestion_penalty REAL NOT NULL,
  housing_constraint_penalty REAL NOT NULL,
  housing_build_rate REAL NOT NULL,
  transport_investment_rate REAL NOT NULL,
  service_investment_rate REAL NOT NULL,
  periodic_policy_investment REAL NOT NULL,
  policy_interval INTEGER NOT NULL,
  pressure_penalty REAL NOT NULL,
  seed INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE equity_dimensions (
  dimension TEXT PRIMARY KEY,
  urban_system_issue TEXT NOT NULL,
  modeling_implication TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE urban_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO urban_system_components (
  component,
  system_role,
  modeling_representation,
  diagnostic_question
) VALUES
('population', 'creates_demand_for_housing_mobility_services_energy_water_and_public_space', 'households_demographic_groups_migration_flows_or_neighborhood_populations', 'How_does_population_change_affect_service_and_capacity_pressure'),
('housing', 'shapes_affordability_density_location_choice_wealth_stability_and_displacement', 'housing_stock_rents_construction_vacancies_zoning_and_household_budgets', 'Where_does_housing_shortage_or_affordability_pressure_accumulate'),
('transportation', 'connects_people_jobs_services_goods_and_land_markets', 'networks_travel_times_mode_choice_accessibility_congestion_and_transit_service', 'How_does_accessibility_shape_growth_and_equity'),
('land_use', 'organizes_activities_density_development_rights_ecological_pressure_and_spatial_form', 'parcels_zones_land_cover_development_scenarios_and_transition_rules', 'How_does_spatial_form_shape_long_term_system_behavior'),
('infrastructure', 'provides_water_energy_drainage_sanitation_roads_communications_and_services', 'capacity_condition_service_areas_maintenance_failure_risk_and_investment_plans', 'Where_do_capacity_condition_and_service_gaps_emerge'),
('economy', 'shapes_employment_wages_investment_land_values_public_revenue_and_inequality', 'jobs_firms_sectors_labor_markets_commercial_districts_and_fiscal_flows', 'How_do_economic_dynamics_affect_land_values_and_access'),
('environment', 'shapes_heat_air_quality_water_habitat_flood_risk_carbon_and_livability', 'green_infrastructure_watersheds_emissions_exposure_layers_and_ecological_stocks', 'Who_is_exposed_to_urban_environmental_risk'),
('governance', 'sets_rules_budgets_plans_rights_incentives_enforcement_and_public_priorities', 'policy_scenarios_institutional_constraints_zoning_rules_and_investment_decisions', 'Which_governance_levers_change_urban_trajectory');

INSERT INTO urban_feedback_loops (
  feedback_loop,
  loop_type,
  urban_mechanism,
  system_risk
) VALUES
('accessibility_development', 'reinforcing', 'better_access_attracts_development_activity_and_more_access_investment', 'can_accelerate_land_value_increase_and_displacement'),
('road_capacity_traffic', 'reinforcing', 'expanded_roads_reduce_congestion_temporarily_and_encourage_more_driving', 'induced_demand_can_restore_congestion'),
('housing_price_supply', 'balancing_or_delayed', 'rising_prices_encourage_construction_when_rules_finance_and_capacity_allow', 'delays_and_constraints_can_sustain_affordability_crisis'),
('disinvestment', 'reinforcing', 'declining_services_reduce_confidence_and_investment_worsening_conditions', 'can_produce_long_term_neighborhood_decline'),
('green_infrastructure', 'reinforcing', 'tree_canopy_parks_and_water_management_improve_livability_health_and_resilience', 'benefits_may_be_unequal_or_create_green_gentrification'),
('trust_participation', 'reinforcing', 'legitimate_planning_increases_participation_compliance_and_policy_effectiveness', 'exclusion_reduces_trust_and_undermines_implementation'),
('infrastructure_growth', 'reinforcing_or_balancing', 'capacity_expansion_enables_growth_while_growth_increases_capacity_demand', 'underinvestment_can_create_service_failure_and_overinvestment_can_create_fiscal_burden');

INSERT INTO modeling_approaches (
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('land_use_transport_modeling', 'accessibility_congestion_development_commuting_transit_and_emissions', 'travel_time_accessibility_mode_share_and_development_pattern', 'transport_results_depend_on_land_use_and_behavioral_assumptions'),
('agent_based_modeling', 'household_choice_segregation_displacement_adoption_and_emergent_behavior', 'agent_outcomes_distribution_and_emergent_spatial_pattern', 'decision_rules_can_encode_bias_or_weak_evidence'),
('network_modeling', 'mobility_infrastructure_resilience_utilities_and_cascading_failure', 'centrality_connectivity_redundancy_and_service_disruption', 'missing_dependencies_can_understate_systemic_risk'),
('system_dynamics', 'urban_growth_housing_infrastructure_pressure_fiscal_stress_and_feedback_loops', 'stock_trajectories_capacity_gaps_loop_dominance_and_delay_effects', 'aggregate_models_can_hide_spatial_inequality'),
('gis_spatial_modeling', 'land_use_heat_flooding_exposure_services_and_environmental_justice', 'hotspots_overlap_accessibility_and_spatial_inequality', 'spatial_precision_can_create_false_confidence'),
('digital_twin_modeling', 'integrated_monitoring_scenario_simulation_and_infrastructure_operations', 'real_time_state_performance_indicators_and_intervention_scenarios', 'operational_data_must_be_governed_for_privacy_and_public_purpose'),
('participatory_modeling', 'neighborhood_planning_contested_values_and_local_knowledge', 'community_assumptions_priorities_pathways_and_legitimacy', 'participation_must_be_meaningful_not_symbolic');

INSERT INTO scenario_definitions (
  scenario,
  n_steps,
  initial_population,
  initial_housing,
  initial_transport,
  initial_service_capacity,
  growth_pressure,
  accessibility_attraction,
  congestion_penalty,
  housing_constraint_penalty,
  housing_build_rate,
  transport_investment_rate,
  service_investment_rate,
  periodic_policy_investment,
  policy_interval,
  pressure_penalty,
  seed,
  description
) VALUES
('baseline_neighborhood', 100, 100, 112, 90, 120, 1.10, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35, 8, 20, 0.70, 42, 'Baseline urban growth and capacity pathway'),
('strong_growth_pressure', 100, 100, 112, 90, 120, 1.65, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35, 8, 20, 0.70, 43, 'Higher growth pressure increases capacity stress'),
('housing_constraint', 100, 100, 106, 90, 120, 1.10, 1.25, 0.70, 0.55, 0.25, 0.45, 0.35, 8, 20, 0.70, 44, 'Lower housing build rate increases shortage risk'),
('transport_investment', 100, 100, 112, 90, 120, 1.10, 1.25, 0.70, 0.45, 0.65, 1.15, 0.85, 10, 20, 0.70, 45, 'Higher transport and service investment'),
('congestion_sensitive', 100, 100, 112, 90, 120, 1.10, 1.25, 1.10, 0.45, 0.65, 0.45, 0.35, 8, 20, 1.10, 46, 'Higher penalty when congestion and pressure rise'),
('high_accessibility_attraction', 100, 100, 112, 90, 120, 1.10, 1.75, 0.70, 0.45, 0.65, 0.45, 0.35, 8, 20, 0.70, 47, 'Accessibility attracts stronger population growth'),
('low_policy_investment', 100, 100, 112, 90, 120, 1.10, 1.25, 0.70, 0.45, 0.65, 0.25, 0.15, 2, 20, 0.70, 48, 'Lower public investment increases pressure'),
('managed_growth', 100, 100, 118, 95, 130, 1.00, 1.15, 0.80, 0.35, 1.05, 0.90, 0.80, 12, 15, 0.80, 49, 'Coordinated capacity and growth management');

INSERT INTO equity_dimensions (
  dimension,
  urban_system_issue,
  modeling_implication,
  professional_caution
) VALUES
('accessibility_equity', 'people_have_unequal_access_to_jobs_schools_healthcare_parks_and_services', 'measure_access_by_income_race_age_disability_mode_and_neighborhood', 'average_access_can_hide_disconnected_places'),
('housing_burden', 'rent_mortgage_utilities_and_transportation_costs_strain_households_differently', 'model_combined_housing_and_transportation_affordability', 'unit_counts_alone_do_not_measure_affordability'),
('environmental_exposure', 'heat_pollution_flooding_noise_and_industrial_burden_are_unevenly_distributed', 'disaggregate_exposure_and_cumulative_burden_spatially', 'citywide_environmental_improvement_can_leave_hotspots'),
('infrastructure_service_gaps', 'reliability_maintenance_broadband_drainage_and_transit_service_vary_by_place', 'map_service_quality_not_only_infrastructure_presence', 'nominal_coverage_can_hide_poor_service'),
('displacement_risk', 'investment_can_raise_costs_and_displace_residents_or_businesses', 'model_affordability_loss_tenure_rent_increases_and_protections', 'development_benefits_can_bypass_current_residents'),
('procedural_justice', 'communities_may_be_excluded_from_model_design_and_policy_interpretation', 'use_participatory_modeling_and_transparent_assumptions', 'models_should_support_public_reasoning_not_replace_it'),
('privacy_and_surveillance', 'smart_city_data_can_capture_movement_behavior_and_service_use', 'apply_data_minimization_consent_privacy_and_accountability', 'efficiency_goals_can_conflict_with_rights');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('population', 0, 1000000, 'Population should remain nonnegative and finite'),
('housing', 0, 1000000, 'Housing capacity should remain nonnegative and finite'),
('transport', 0, 1000000, 'Transport capacity should remain nonnegative and finite'),
('service_capacity', 0, 1000000, 'Service capacity should remain nonnegative and finite'),
('accessibility', 0, 1000000, 'Accessibility proxy should remain nonnegative and finite'),
('congestion', 0, 1000000, 'Congestion should remain nonnegative and finite'),
('housing_gap', 0, 1000000, 'Housing gap should remain nonnegative and finite'),
('service_pressure', 0, 1000000, 'Service pressure should remain nonnegative and finite');

INSERT INTO urban_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_neighborhood', 'illustrative_growth_pressure', 1.10, 'Baseline urban growth pressure'),
('strong_growth_pressure', 'illustrative_growth_pressure', 1.65, 'Higher growth pressure'),
('housing_constraint', 'illustrative_housing_build_rate', 0.25, 'Lower housing build rate'),
('transport_investment', 'illustrative_transport_investment_rate', 1.15, 'Higher transport investment'),
('congestion_sensitive', 'illustrative_congestion_penalty', 1.10, 'Higher sensitivity to congestion'),
('high_accessibility_attraction', 'illustrative_accessibility_attraction', 1.75, 'Stronger attraction from accessibility'),
('low_policy_investment', 'illustrative_periodic_policy_investment', 2.00, 'Lower periodic public investment'),
('managed_growth', 'illustrative_periodic_policy_investment', 12.00, 'Coordinated capacity and growth management');

CREATE VIEW v_urban_system_components AS
SELECT
  component,
  system_role,
  modeling_representation,
  diagnostic_question
FROM urban_system_components
ORDER BY component;

CREATE VIEW v_urban_feedback_loops AS
SELECT
  feedback_loop,
  loop_type,
  urban_mechanism,
  system_risk
FROM urban_feedback_loops
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
  initial_population,
  initial_housing,
  initial_transport,
  initial_service_capacity,
  growth_pressure,
  accessibility_attraction,
  congestion_penalty,
  housing_constraint_penalty,
  housing_build_rate,
  transport_investment_rate,
  service_investment_rate,
  periodic_policy_investment,
  policy_interval,
  pressure_penalty,
  seed,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_equity_dimensions AS
SELECT
  dimension,
  urban_system_issue,
  modeling_implication,
  professional_caution
FROM equity_dimensions
ORDER BY dimension;

CREATE VIEW v_urban_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM urban_metrics
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

SELECT * FROM v_urban_system_components;
SELECT * FROM v_urban_feedback_loops;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_equity_dimensions;
SELECT * FROM v_urban_metric_summary;
SELECT * FROM v_validation_targets;
