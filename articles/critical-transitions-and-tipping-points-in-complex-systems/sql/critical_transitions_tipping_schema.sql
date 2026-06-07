-- critical_transitions_tipping_schema.sql
-- SQLite schema and analysis queries for critical transitions and tipping points.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_tipping_mechanisms;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_domain_tipping_examples;
DROP VIEW IF EXISTS v_tipping_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS tipping_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS domain_tipping_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS tipping_mechanisms;

CREATE TABLE tipping_mechanisms (
  mechanism TEXT PRIMARY KEY,
  system_meaning TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  forward_start REAL NOT NULL,
  forward_end REAL NOT NULL,
  steps INTEGER NOT NULL,
  initial_state REAL NOT NULL,
  dt REAL NOT NULL,
  transition_jump_threshold REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE domain_tipping_examples (
  domain TEXT PRIMARY KEY,
  control_parameter TEXT NOT NULL,
  stable_regime TEXT NOT NULL,
  tipped_regime TEXT NOT NULL,
  modeling_concern TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE tipping_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO tipping_mechanisms (
  mechanism,
  system_meaning,
  modeling_representation,
  diagnostic_question
) VALUES
('bifurcation_tipping', 'stable state disappears as a control parameter changes', 'nonlinear state equation and equilibrium tracking', 'Does a gradual forcing path eliminate the current equilibrium'),
('noise_induced_tipping', 'shock pushes the system outside its basin of attraction', 'stochastic perturbation or pulse shock', 'Can a disturbance trigger transition before deterministic threshold'),
('rate_induced_tipping', 'external change is too fast for the system to track', 'time-varying forcing speed', 'Does transition depend on the rate of pressure change'),
('hysteresis', 'recovery path differs from collapse path', 'separate forward and backward forcing trajectories', 'Does reversing pressure restore the previous regime'),
('critical_slowing_down', 'recovery weakens near threshold', 'rolling autocorrelation and variance', 'Are recovery indicators weakening before transition'),
('network_cascade', 'local failure propagates through interdependence', 'node threshold or load redistribution model', 'Can one failure trigger systemic propagation'),
('feedback_amplification', 'reinforcing feedback accelerates transition', 'positive feedback term or regime-dependent flow', 'Which feedbacks amplify departure from the old state'),
('regime_switching', 'system follows different rules in different states', 'state-dependent parameter rule', 'Do model parameters change after threshold crossing');

INSERT INTO scenario_definitions (
  scenario,
  forward_start,
  forward_end,
  steps,
  initial_state,
  dt,
  transition_jump_threshold,
  description
) VALUES
('baseline_hysteresis', -1.20, 1.20, 300, -1.00, 0.050, 0.150, 'Standard forward and backward forcing path'),
('slow_forcing', -1.20, 1.20, 500, -1.00, 0.035, 0.120, 'Slower forcing with smaller time step'),
('fast_forcing', -1.20, 1.20, 150, -1.00, 0.075, 0.220, 'Faster forcing with larger time step'),
('wide_forcing', -1.45, 1.45, 360, -1.10, 0.050, 0.150, 'Wider control-parameter range'),
('near_threshold_start', -0.80, 1.20, 260, -0.60, 0.050, 0.130, 'Starts closer to middle branch and transition region'),
('recovery_stress', -1.20, 1.05, 300, -1.00, 0.055, 0.150, 'Backward path tests incomplete recovery pressure range'),
('high_resolution', -1.20, 1.20, 700, -1.00, 0.025, 0.080, 'High-resolution forcing path for smoother diagnostics'),
('policy_delay', -1.00, 1.30, 260, -1.00, 0.060, 0.180, 'Delayed intervention analogue with forcing beyond baseline');

INSERT INTO domain_tipping_examples (
  domain,
  control_parameter,
  stable_regime,
  tipped_regime,
  modeling_concern
) VALUES
('ecology', 'nutrient_loading_or_drought_pressure', 'clear_or_regenerative_state', 'turbid_or_degraded_state', 'hysteresis_and_recovery_thresholds'),
('climate', 'warming_or_freshwater_forcing', 'existing_earth_system_component_state', 'alternative_component_state', 'long_time_horizons_and_irreversibility'),
('infrastructure', 'load_asset_age_or_maintenance_backlog', 'preventive_maintenance_and_stable_service', 'cascading_failure_or_chronic_repair', 'threshold_capacity_and_network_dependency'),
('finance', 'leverage_liquidity_or_confidence', 'liquidity_and_orderly_market_function', 'panic_withdrawal_or_contagion', 'expectation_feedback_and_counterparty_exposure'),
('public_health', 'demand_surge_or_staffing_loss', 'managed_capacity_and_care_quality', 'overload_triage_and_delayed_care', 'capacity_threshold_and_recovery_delay'),
('organizations', 'workload_turnover_or_trust_loss', 'learning_and_adaptive_capacity', 'burnout_attrition_and_defensive_routines', 'slow_capacity_erosion_and_feedback'),
('public_institutions', 'legitimacy_loss_or_service_failure', 'cooperation_and_compliance', 'mistrust_noncompliance_and_resistance', 'trust_stock_and_performance_feedback'),
('supply_chains', 'supplier_failure_transport_delay_or_inventory_depletion', 'stable_material_flow', 'cascading_shortage_and_production_disruption', 'dependency_centrality_and_rerouting_capacity');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('system_state', -1000000, 1000000, 'System state should remain finite'),
('control_parameter', -1000000, 1000000, 'Control parameter should remain finite'),
('transition_step', 0, 1000000, 'Transition step should be nonnegative when detected'),
('rolling_variance_20', 0, 1000000, 'Rolling variance should be nonnegative and finite'),
('rolling_autocorrelation_20', -1, 1, 'Lag-1 autocorrelation should remain bounded when available'),
('minimum_state', -1000000, 1000000, 'Minimum state should remain finite'),
('maximum_state', -1000000, 1000000, 'Maximum state should remain finite'),
('hysteresis_gap', 0, 1000000, 'Estimated hysteresis gap should be nonnegative when detected');

INSERT INTO tipping_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_hysteresis', 'illustrative_hysteresis_gap', 0.72, 'Forward and backward paths transition at different control values'),
('slow_forcing', 'illustrative_transition_sharpness', 0.12, 'Slower forcing produces smoother numerical transition diagnostics'),
('fast_forcing', 'illustrative_transition_sharpness', 0.24, 'Faster forcing increases abrupt step-to-step movement'),
('wide_forcing', 'illustrative_state_range', 2.60, 'Wider forcing explores more of the nonlinear state landscape'),
('near_threshold_start', 'illustrative_transition_step', 88, 'Starting near threshold changes transition timing'),
('recovery_stress', 'illustrative_recovery_difficulty', 1.00, 'Reduced reverse forcing range can limit recovery'),
('policy_delay', 'illustrative_overshoot_pressure', 1.30, 'Delayed response pushes the control parameter beyond baseline');

CREATE VIEW v_tipping_mechanisms AS
SELECT
  mechanism,
  system_meaning,
  modeling_representation,
  diagnostic_question
FROM tipping_mechanisms
ORDER BY mechanism;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  forward_start,
  forward_end,
  steps,
  initial_state,
  dt,
  transition_jump_threshold,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_domain_tipping_examples AS
SELECT
  domain,
  control_parameter,
  stable_regime,
  tipped_regime,
  modeling_concern
FROM domain_tipping_examples
ORDER BY domain;

CREATE VIEW v_tipping_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM tipping_metrics
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

SELECT * FROM v_tipping_mechanisms;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_domain_tipping_examples;
SELECT * FROM v_tipping_metric_summary;
SELECT * FROM v_validation_targets;
