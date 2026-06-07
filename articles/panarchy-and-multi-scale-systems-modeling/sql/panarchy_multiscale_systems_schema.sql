-- panarchy_multiscale_systems_schema.sql
-- SQLite schema and analysis queries for panarchy and multi-scale systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_panarchy_concepts;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_multiscale_examples;
DROP VIEW IF EXISTS v_panarchy_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS panarchy_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS multiscale_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS panarchy_concepts;

CREATE TABLE panarchy_concepts (
  concept TEXT PRIMARY KEY,
  system_meaning TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  fast_growth REAL NOT NULL,
  fast_capacity REAL NOT NULL,
  slow_constraint REAL NOT NULL,
  release_threshold REAL NOT NULL,
  release_magnitude REAL NOT NULL,
  revolt_strength REAL NOT NULL,
  remember_strength REAL NOT NULL,
  slow_adjustment REAL NOT NULL,
  slow_target REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE multiscale_examples (
  domain TEXT PRIMARY KEY,
  lower_scale TEXT NOT NULL,
  focal_scale TEXT NOT NULL,
  higher_scale TEXT NOT NULL,
  fast_variable TEXT NOT NULL,
  slow_variable TEXT NOT NULL,
  panarchy_question TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE panarchy_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO panarchy_concepts (
  concept,
  system_meaning,
  modeling_representation,
  diagnostic_question
) VALUES
('adaptive_cycle', 'recurring pattern of growth conservation release and reorganization', 'phase state or parameter regime', 'Which phase dominates system behavior'),
('growth_phase', 'expansion innovation resource accumulation', 'positive growth flow and low connectedness', 'Is the system expanding or overextending'),
('conservation_phase', 'efficiency connectedness specialization and rigidity', 'high resource stock and high connectedness', 'Is efficiency producing hidden fragility'),
('release_phase', 'disturbance collapse or loosening of accumulated structure', 'threshold-triggered loss or reset', 'Does disturbance remain local or cascade'),
('reorganization_phase', 'experimentation recombination and renewal', 'post-release learning and memory influence', 'Does the system adapt transform or become trapped'),
('revolt', 'fast lower-scale disruption influencing slower higher-scale systems', 'threshold-triggered upward coupling', 'Does local disturbance alter larger-scale state'),
('remember', 'slower higher-scale memory shaping lower-scale reorganization', 'downward memory term or stabilizing constraint', 'Does memory support or constrain recovery'),
('fast_variable', 'rapidly changing process or disturbance', 'short time constant state variable', 'Which visible changes are symptoms'),
('slow_variable', 'gradual structural process or memory', 'long time constant stock or parameter', 'Which slow variables structure system possibility'),
('cross_scale_coupling', 'influence between nested adaptive cycles', 'coupled state equations or network dependency', 'Which scales interact strongly');

INSERT INTO scenario_definitions (
  scenario,
  fast_growth,
  fast_capacity,
  slow_constraint,
  release_threshold,
  release_magnitude,
  revolt_strength,
  remember_strength,
  slow_adjustment,
  slow_target,
  description
) VALUES
('baseline_panarchy', 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.035, 0.010, 1.60, 'Moderate fast growth with moderate revolt and remember coupling'),
('strong_revolt', 0.16, 3.20, 0.08, 2.35, 1.35, 0.24, 0.035, 0.010, 1.60, 'Fast-cycle release strongly shifts the slower memory scale'),
('strong_remember', 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.065, 0.014, 1.60, 'Slow memory strongly stabilizes fast-cycle reorganization'),
('rigid_slow_structure', 0.16, 3.20, 0.13, 2.50, 1.35, 0.14, 0.020, 0.004, 1.60, 'Slow structure strongly constrains the fast cycle and adjusts slowly'),
('weak_memory_high_volatility', 0.17, 3.10, 0.06, 2.30, 1.45, 0.20, 0.015, 0.008, 1.45, 'Weak remember effects produce volatile fast-cycle release'),
('adaptive_transformation', 0.15, 3.40, 0.07, 2.55, 1.20, 0.18, 0.055, 0.018, 1.80, 'Memory and learning support reorganization after release'),
('locked_conservation', 0.12, 3.60, 0.15, 2.80, 1.10, 0.08, 0.025, 0.003, 1.70, 'High constraint and weak revolt keep the system near conservation'),
('recurrent_release', 0.20, 3.00, 0.05, 2.20, 1.15, 0.16, 0.025, 0.012, 1.50, 'Fast growth and low threshold generate repeated release events');

INSERT INTO multiscale_examples (
  domain,
  lower_scale,
  focal_scale,
  higher_scale,
  fast_variable,
  slow_variable,
  panarchy_question
) VALUES
('ecology', 'patch_or_species', 'landscape_or_watershed', 'regional_climate_and_biome', 'fire_pest_water_level', 'soil_climate_biodiversity', 'Does local disturbance regenerate or shift the broader ecosystem'),
('infrastructure', 'asset_or_facility', 'network_or_utility', 'regional_governance_and_climate', 'outage_repair_load', 'asset_age_workforce_capital', 'Does component failure cascade through network and governance constraints'),
('public_health', 'patient_or_clinic', 'hospital_system_or_local_health_department', 'national_policy_supply_chains_public_trust', 'demand_surge_staff_loss', 'workforce_pipeline_trust_institutions', 'Does local surge expose larger capacity limits'),
('supply_chains', 'supplier_or_port', 'production_network', 'global_trade_finance_regulation', 'shipment_delay_shortage', 'inventory_strategy_transport_structure', 'Does local disruption propagate into systemic shortage'),
('urban_systems', 'household_block_or_street', 'neighborhood_or_city', 'region_state_climate_system', 'traffic_flood_heat_event', 'land_use_housing_stock_infrastructure', 'Does local adaptation align with regional transformation'),
('organizations', 'team_or_project', 'department_or_firm', 'industry_labor_market_regulation', 'deadline_error_turnover', 'culture_capability_institutional_memory', 'Does local overload reveal slow organizational fragility'),
('energy_systems', 'building_feeder_or_microgrid', 'utility_or_grid_region', 'national_policy_fuel_markets_climate_transition', 'load_spike_outage_device_adoption', 'grid_topology_market_rules_capital_stock', 'Does distributed change transform the larger energy regime');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('fast_cycle', 0, 1000000, 'Fast-cycle state should remain nonnegative and finite'),
('slow_memory', 0, 1000000, 'Slow-memory state should remain nonnegative and finite'),
('release_events', 0, 1000000, 'Release-event count should be nonnegative'),
('cross_scale_coupling', 0, 1000000, 'Cross-scale coupling should remain nonnegative and finite'),
('growth_periods', 0, 1000000, 'Growth-period count should be nonnegative'),
('conservation_periods', 0, 1000000, 'Conservation-period count should be nonnegative'),
('release_periods', 0, 1000000, 'Release-period count should be nonnegative'),
('reorganization_periods', 0, 1000000, 'Reorganization-period count should be nonnegative');

INSERT INTO panarchy_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_panarchy', 'illustrative_release_events', 2, 'Moderate release and recovery dynamics'),
('strong_revolt', 'illustrative_release_events', 4, 'Lower threshold and stronger revolt increase upward disruption'),
('strong_remember', 'illustrative_slow_memory', 1.9, 'Stronger remember dynamics stabilize reorganization'),
('rigid_slow_structure', 'illustrative_conservation_periods', 80, 'Rigid slow structure constrains fast-cycle movement'),
('weak_memory_high_volatility', 'illustrative_release_events', 5, 'Weak memory and low threshold increase volatility'),
('adaptive_transformation', 'illustrative_slow_memory', 2.1, 'Memory and learning support transformation'),
('locked_conservation', 'illustrative_release_events', 0, 'Strong constraint and weak revolt suppress release'),
('recurrent_release', 'illustrative_release_events', 6, 'Fast growth and low threshold produce repeated release');

CREATE VIEW v_panarchy_concepts AS
SELECT
  concept,
  system_meaning,
  modeling_representation,
  diagnostic_question
FROM panarchy_concepts
ORDER BY concept;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  fast_growth,
  fast_capacity,
  slow_constraint,
  release_threshold,
  release_magnitude,
  revolt_strength,
  remember_strength,
  slow_adjustment,
  slow_target,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_multiscale_examples AS
SELECT
  domain,
  lower_scale,
  focal_scale,
  higher_scale,
  fast_variable,
  slow_variable,
  panarchy_question
FROM multiscale_examples
ORDER BY domain;

CREATE VIEW v_panarchy_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM panarchy_metrics
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

SELECT * FROM v_panarchy_concepts;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_multiscale_examples;
SELECT * FROM v_panarchy_metric_summary;
SELECT * FROM v_validation_targets;
