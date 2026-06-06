-- core_principles_systems_modeling_schema.sql
-- SQLite schema and analysis queries for core systems-modeling principles.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS core_principles;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE core_principles (
  principle_id INTEGER PRIMARY KEY,
  principle TEXT NOT NULL,
  modeling_question TEXT NOT NULL,
  formal_representation TEXT NOT NULL,
  diagnostic TEXT NOT NULL
);

CREATE TABLE model_runs (
  run_id INTEGER PRIMARY KEY,
  article_slug TEXT NOT NULL,
  model_name TEXT NOT NULL,
  scenario_name TEXT NOT NULL,
  run_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  purpose TEXT NOT NULL,
  notes TEXT
);

CREATE TABLE scenario_parameters (
  parameter_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  parameter_name TEXT NOT NULL,
  parameter_value REAL NOT NULL,
  parameter_units TEXT,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE model_outputs (
  output_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  time_step INTEGER,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT INTO core_principles (
  principle,
  modeling_question,
  formal_representation,
  diagnostic
) VALUES
('purpose', 'why is the model being built', 'model objective and use case', 'use-validity review'),
('boundary', 'what is inside and outside', 'endogenous and exogenous variables', 'boundary critique'),
('state', 'what conditions define the system', 'state variables stocks agents nodes events', 'state range checks'),
('stocks_and_flows', 'what accumulates and what changes it', 'stock-flow equations', 'accumulation diagnostics'),
('feedback', 'how effects return as causes', 'reinforcing and balancing loops', 'loop dominance'),
('delay', 'where responses lag causes', 'delayed state or lagged variable', 'overshoot and oscillation checks'),
('nonlinearity', 'where response changes with scale', 'thresholds saturation piecewise functions', 'threshold-active periods'),
('scenarios', 'which futures are compared', 'scenario parameter sets', 'scenario comparison'),
('uncertainty', 'which assumptions are fragile', 'parameter ranges and ensembles', 'sensitivity analysis'),
('validation', 'is the model credible for purpose', 'targets historical checks expert review', 'validation report');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'core-principles-of-systems-modeling', 'stock_flow_feedback_threshold_model', 'baseline_core_principles', 'workflow demonstration', 'Reference stock-flow feedback model'),
(2, 'core-principles-of-systems-modeling', 'stock_flow_feedback_threshold_model', 'long_delay', 'delay stress test', 'Longer delay scenario'),
(3, 'core-principles-of-systems-modeling', 'stock_flow_feedback_threshold_model', 'weak_balancing', 'feedback strength test', 'Weaker balancing feedback scenario'),
(4, 'core-principles-of-systems-modeling', 'stock_flow_feedback_threshold_model', 'strong_threshold_correction', 'threshold stress test', 'Stronger threshold correction scenario');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units
) VALUES
(1, 'growth_rate', 0.090, 'fraction per period'),
(1, 'balancing_strength', 0.050, 'fraction per period'),
(1, 'delay', 6, 'periods'),
(1, 'capacity', 90, 'stock units'),
(2, 'growth_rate', 0.090, 'fraction per period'),
(2, 'balancing_strength', 0.050, 'fraction per period'),
(2, 'delay', 12, 'periods'),
(2, 'capacity', 90, 'stock units'),
(3, 'growth_rate', 0.090, 'fraction per period'),
(3, 'balancing_strength', 0.025, 'fraction per period'),
(3, 'delay', 6, 'periods'),
(3, 'capacity', 90, 'stock units'),
(4, 'growth_rate', 0.090, 'fraction per period'),
(4, 'balancing_strength', 0.050, 'fraction per period'),
(4, 'delay', 6, 'periods'),
(4, 'capacity', 90, 'stock units');

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 160, 'illustrative_final_stock', 70.0),
(1, 160, 'illustrative_peak_stock', 95.0),
(2, 160, 'illustrative_final_stock', 74.0),
(2, 160, 'illustrative_peak_stock', 112.0),
(3, 160, 'illustrative_final_stock', 88.0),
(3, 160, 'illustrative_peak_stock', 130.0),
(4, 160, 'illustrative_final_stock', 66.0),
(4, 160, 'illustrative_peak_stock', 82.0);

CREATE VIEW v_core_principle_inventory AS
SELECT
  principle,
  modeling_question,
  formal_representation,
  diagnostic
FROM core_principles
ORDER BY principle_id;

CREATE VIEW v_scenario_parameter_inventory AS
SELECT
  r.scenario_name,
  p.parameter_name,
  p.parameter_value,
  p.parameter_units
FROM scenario_parameters p
JOIN model_runs r
  ON p.run_id = r.run_id
ORDER BY r.scenario_name, p.parameter_name;

CREATE VIEW v_output_metric_summary AS
SELECT
  r.scenario_name,
  o.metric_name,
  COUNT(*) AS observation_count,
  ROUND(MIN(o.metric_value), 3) AS minimum_value,
  ROUND(AVG(o.metric_value), 3) AS average_value,
  ROUND(MAX(o.metric_value), 3) AS maximum_value
FROM model_outputs o
JOIN model_runs r
  ON o.run_id = r.run_id
GROUP BY r.scenario_name, o.metric_name;

.headers on
.mode column

SELECT * FROM v_core_principle_inventory;
SELECT * FROM v_scenario_parameter_inventory;
SELECT * FROM v_output_metric_summary;
