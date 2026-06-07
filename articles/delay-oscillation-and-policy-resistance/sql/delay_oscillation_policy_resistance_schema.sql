-- delay_oscillation_policy_resistance_schema.sql
-- SQLite schema and analysis queries for delay, oscillation, and policy resistance.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_delay_taxonomy;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_policy_resistance_examples;
DROP VIEW IF EXISTS v_delay_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS delay_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS policy_resistance_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS delay_taxonomy;

CREATE TABLE delay_taxonomy (
  delay_type TEXT PRIMARY KEY,
  primary_source TEXT NOT NULL,
  common_system_effect TEXT NOT NULL,
  modeling_representation TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  delay INTEGER NOT NULL,
  correction_strength REAL NOT NULL,
  counterresponse_strength REAL NOT NULL,
  perception_smoothing REAL NOT NULL,
  natural_pressure_base REAL NOT NULL,
  natural_pressure_slope REAL NOT NULL,
  target REAL NOT NULL,
  initial_state REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE policy_resistance_examples (
  domain TEXT PRIMARY KEY,
  policy_goal TEXT NOT NULL,
  intervention TEXT NOT NULL,
  counterresponse TEXT NOT NULL,
  modeling_question TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE delay_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO delay_taxonomy (
  delay_type,
  primary_source,
  common_system_effect,
  modeling_representation
) VALUES
('information_delay', 'Measurement reporting monitoring and communication lag', 'Actors respond to stale signals', 'Observed state differs from actual state'),
('decision_delay', 'Approval budgeting conflict coordination', 'Action begins after pressure accumulates', 'Trigger-to-decision lag'),
('implementation_delay', 'Hiring procurement construction deployment', 'Chosen policy takes time to affect the system', 'Pipeline stock or delayed effect'),
('material_delay', 'Production transport delivery transformation', 'Inventories or backlogs overshoot', 'Order pipeline or transit stock'),
('behavioral_delay', 'Habits trust norms learning adoption', 'Policy effect appears gradually', 'Adoption curve or adaptive response'),
('institutional_delay', 'Rules capacity legal process governance cycles', 'System response slower than system deterioration', 'Governance lag or approval queue'),
('ecological_delay', 'Regeneration climate response biological recovery', 'Damage persists after pressure falls', 'Slow stock recovery or lagged effect'),
('perception_delay', 'Noisy evidence partial observation cognitive updating', 'Decision-makers misread system state', 'Smoothed perceived state');

INSERT INTO scenario_definitions (
  scenario,
  delay,
  correction_strength,
  counterresponse_strength,
  perception_smoothing,
  natural_pressure_base,
  natural_pressure_slope,
  target,
  initial_state,
  description
) VALUES
('timely_moderate_response', 1, 0.18, 0.00, 0.75, 2.0, 0.025, 50.0, 80.0, 'Short delay with moderate correction and no modeled counterresponse'),
('delayed_response', 6, 0.18, 0.00, 0.55, 2.0, 0.025, 50.0, 80.0, 'Longer delay with same correction strength'),
('overcorrection', 6, 0.34, 0.00, 0.55, 2.0, 0.025, 50.0, 80.0, 'Longer delay with stronger correction that can overshoot'),
('undercorrection', 6, 0.09, 0.00, 0.55, 2.0, 0.025, 50.0, 80.0, 'Longer delay with weak correction that may not reverse pressure'),
('policy_resistance', 6, 0.24, 0.42, 0.55, 2.0, 0.025, 50.0, 80.0, 'Corrective policy triggers counterresponse that offsets intended effect'),
('slow_recognition_high_resistance', 10, 0.24, 0.55, 0.35, 2.0, 0.025, 50.0, 80.0, 'Long delay weak perception update and strong counterresponse'),
('adaptive_moderated_response', 3, 0.20, 0.12, 0.70, 1.6, 0.018, 50.0, 80.0, 'Moderated response with lower natural pressure and modest resistance');

INSERT INTO policy_resistance_examples (
  domain,
  policy_goal,
  intervention,
  counterresponse,
  modeling_question
) VALUES
('transportation', 'reduce_congestion', 'add_road_capacity', 'induced_demand_restores_congestion', 'Does added capacity reduce pressure or induce new demand'),
('energy', 'reduce_energy_use', 'improve_efficiency', 'rebound_effect_increases_total_use', 'Do efficiency savings survive behavioral response'),
('public_management', 'improve_performance', 'set_narrow_targets', 'metric_gaming_replaces_mission_performance', 'Does reported success track true system improvement'),
('infrastructure', 'reduce_failures', 'expand_emergency_repair', 'emergency_work_crowds_out_prevention', 'Does reactive capacity weaken preventive maintenance'),
('health_systems', 'reduce_backlog', 'add_temporary_staff', 'unchanged_demand_recreates_backlog', 'Does temporary capacity change sustained net flow'),
('public_trust', 'improve_compliance', 'communication_campaign', 'ongoing_failures_erode_credibility', 'Does policy change trust-building and trust-eroding flows'),
('environment', 'reduce_pollution', 'enforce_local_standard', 'activity_displaces_outside_boundary', 'Does harm move outside the modeled system');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('state', 0, 1000000, 'System state should remain nonnegative and finite'),
('perceived_state', 0, 1000000, 'Perceived state should remain nonnegative and finite'),
('target_crossings', 0, 1000, 'Target crossings should remain bounded'),
('maximum_overshoot_above_target', 0, 1000000, 'Overshoot should remain nonnegative and finite'),
('mean_absolute_target_gap', 0, 1000000, 'Target gap should remain nonnegative and finite'),
('cumulative_intervention', 0, 1000000, 'Intervention effort should remain nonnegative and finite'),
('cumulative_counterresponse', 0, 1000000, 'Counterresponse should remain nonnegative and finite'),
('resistance_ratio', 0, 100, 'Resistance ratio should remain bounded');

INSERT INTO delay_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('timely_moderate_response', 'illustrative_target_crossings', 1, 'Short delay limits oscillation'),
('delayed_response', 'illustrative_target_crossings', 3, 'Long delay creates more target crossings'),
('overcorrection', 'illustrative_target_crossings', 6, 'Strong correction with delay increases oscillation risk'),
('undercorrection', 'illustrative_final_state', 96.0, 'Weak correction leaves persistent pressure'),
('policy_resistance', 'illustrative_resistance_ratio', 0.42, 'Counterresponse offsets part of intervention'),
('slow_recognition_high_resistance', 'illustrative_resistance_ratio', 0.55, 'Slow recognition and resistance weaken policy effectiveness'),
('adaptive_moderated_response', 'illustrative_mean_absolute_target_gap', 18.0, 'Moderated response reduces average gap');

CREATE VIEW v_delay_taxonomy AS
SELECT
  delay_type,
  primary_source,
  common_system_effect,
  modeling_representation
FROM delay_taxonomy
ORDER BY delay_type;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  delay,
  correction_strength,
  counterresponse_strength,
  perception_smoothing,
  natural_pressure_base,
  natural_pressure_slope,
  target,
  initial_state,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_policy_resistance_examples AS
SELECT
  domain,
  policy_goal,
  intervention,
  counterresponse,
  modeling_question
FROM policy_resistance_examples
ORDER BY domain;

CREATE VIEW v_delay_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM delay_metrics
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

SELECT * FROM v_delay_taxonomy;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_policy_resistance_examples;
SELECT * FROM v_delay_metric_summary;
SELECT * FROM v_validation_targets;
