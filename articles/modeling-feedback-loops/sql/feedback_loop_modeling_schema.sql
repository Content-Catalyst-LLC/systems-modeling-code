-- feedback_loop_modeling_schema.sql
-- SQLite schema and analysis queries for feedback loop modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_feedback_loop_taxonomy;
DROP VIEW IF EXISTS v_delayed_feedback_scenarios;
DROP VIEW IF EXISTS v_policy_resistance_scenarios;
DROP VIEW IF EXISTS v_feedback_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS feedback_metrics;
DROP TABLE IF EXISTS policy_resistance_scenarios;
DROP TABLE IF EXISTS delayed_feedback_scenarios;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS feedback_parameters;
DROP TABLE IF EXISTS feedback_loop_taxonomy;

CREATE TABLE feedback_loop_taxonomy (
  loop_type TEXT PRIMARY KEY,
  primary_effect TEXT NOT NULL,
  common_pattern TEXT NOT NULL,
  modeling_method TEXT NOT NULL
);

CREATE TABLE feedback_parameters (
  parameter TEXT PRIMARY KEY,
  value REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE delayed_feedback_scenarios (
  scenario_id INTEGER PRIMARY KEY,
  delay INTEGER NOT NULL,
  correction_strength REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE policy_resistance_scenarios (
  scenario TEXT PRIMARY KEY,
  intervention_strength REAL NOT NULL,
  behavioral_response REAL NOT NULL,
  implementation_delay INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE feedback_metrics (
  metric_id INTEGER PRIMARY KEY,
  model_component TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO feedback_loop_taxonomy (
  loop_type,
  primary_effect,
  common_pattern,
  modeling_method
) VALUES
('reinforcing', 'Amplifies change', 'Exponential growth collapse escalation contagion', 'Recursive growth equations system dynamics agent rules'),
('balancing', 'Counteracts change', 'Stabilization target seeking regulation', 'Control equations stock-flow adjustment equilibrium models'),
('delayed', 'Separates action from consequence', 'Oscillation overshoot policy resistance', 'Lagged variables delay functions discrete-time recurrences'),
('nonlinear', 'Changes feedback strength by state', 'Thresholds saturation tipping points', 'Nonlinear equations response curves stress tests'),
('adaptive', 'Changes behavior through learning', 'Lock-in imitation strategic response', 'Agent-based models game theory adaptive control'),
('network', 'Uses relational structure as feedback pathway', 'Diffusion cascade clustering contagion', 'Graphs centrality network diffusion cascade models'),
('stock_flow', 'Operates through accumulation', 'Overshoot depletion backlog recovery', 'Stocks inflows outflows feedback functions'),
('policy_resistance', 'Activates counter-feedback', 'Unintended consequences rebound effects', 'Scenario models behavioral response institutional delay');

INSERT INTO feedback_parameters (
  parameter,
  value,
  description
) VALUES
('reinforcing_rate', 0.10, 'Base compounding rate for reinforcing feedback'),
('balancing_target', 20.0, 'Target value for balancing feedback'),
('balancing_correction', 0.15, 'Correction strength for standard balancing feedback'),
('logistic_capacity', 25.0, 'Capacity limit for logistic feedback'),
('logistic_rate', 0.12, 'Base growth rate for logistic feedback'),
('delay_initial_state', 5.0, 'Initial state for delayed balancing feedback'),
('delay_target', 20.0, 'Target state for delayed feedback scenarios');

INSERT INTO delayed_feedback_scenarios (
  scenario_id,
  delay,
  correction_strength,
  description
) VALUES
(1, 1, 0.12, 'Short delay and weak correction'),
(2, 3, 0.20, 'Moderate delay and moderate correction'),
(3, 5, 0.28, 'Longer delay and stronger correction'),
(4, 8, 0.36, 'Long delay and strong correction'),
(5, 12, 0.36, 'Very long delay and strong correction');

INSERT INTO policy_resistance_scenarios (
  scenario,
  intervention_strength,
  behavioral_response,
  implementation_delay,
  description
) VALUES
('capacity_expansion', 0.35, 0.26, 4, 'Capacity increase partly offset by induced demand'),
('metric_targeting', 0.30, 0.35, 3, 'Performance target improves reported score but increases gaming response'),
('maintenance_push', 0.42, 0.12, 5, 'Maintenance intervention reduces degradation after implementation delay'),
('congestion_pricing', 0.28, -0.10, 2, 'Pricing intervention reduces demand pressure'),
('trust_rebuilding', 0.22, -0.18, 8, 'Slow institutional trust intervention reduces noncompliance after delay');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('state', -1000000, 1000000, 'System state should remain finite'),
('target_crossings', 0, 1000, 'Target crossings should remain bounded'),
('mean_absolute_target_gap', 0, 1000000, 'Gap should remain nonnegative and finite'),
('overshoot_above_target', 0, 1000000, 'Overshoot should remain nonnegative and finite'),
('loop_count', 1, 100, 'Workflow should include one or more feedback structures'),
('policy_pressure', 0, 1000000, 'Policy pressure should remain nonnegative and finite');

INSERT INTO feedback_metrics (
  model_component,
  metric_name,
  metric_value,
  interpretation
) VALUES
('reinforcing', 'illustrative_final_state', 102.41, 'Compounding reinforcing loop final state'),
('balancing', 'illustrative_final_state', 19.99, 'Target-seeking balancing loop final state'),
('logistic', 'illustrative_final_state', 24.85, 'Capacity-constrained logistic loop final state'),
('delayed_balancing', 'illustrative_target_crossings', 7, 'Delayed balancing oscillation indicator'),
('stock_flow', 'illustrative_final_stock', 58.4, 'Stock-flow feedback final accumulation'),
('policy_resistance', 'illustrative_pressure_reduction', 22.7, 'Pressure reduction after intervention and counter-feedback');

CREATE VIEW v_feedback_loop_taxonomy AS
SELECT
  loop_type,
  primary_effect,
  common_pattern,
  modeling_method
FROM feedback_loop_taxonomy
ORDER BY loop_type;

CREATE VIEW v_delayed_feedback_scenarios AS
SELECT
  scenario_id,
  delay,
  correction_strength,
  description
FROM delayed_feedback_scenarios
ORDER BY scenario_id;

CREATE VIEW v_policy_resistance_scenarios AS
SELECT
  scenario,
  intervention_strength,
  behavioral_response,
  implementation_delay,
  description
FROM policy_resistance_scenarios
ORDER BY scenario;

CREATE VIEW v_feedback_metric_summary AS
SELECT
  model_component,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM feedback_metrics
GROUP BY model_component, metric_name
ORDER BY model_component, metric_name;

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

SELECT * FROM v_feedback_loop_taxonomy;
SELECT * FROM v_delayed_feedback_scenarios;
SELECT * FROM v_policy_resistance_scenarios;
SELECT * FROM v_feedback_metric_summary;
SELECT * FROM v_validation_targets;
