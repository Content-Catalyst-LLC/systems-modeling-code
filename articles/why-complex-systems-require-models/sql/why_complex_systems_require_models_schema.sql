-- why_complex_systems_require_models_schema.sql
-- SQLite schema and analysis queries for dynamic-system model diagnostics.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS model_runs;

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

CREATE TABLE validation_targets (
  target_id INTEGER PRIMARY KEY,
  metric_name TEXT NOT NULL,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT
);

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'why-complex-systems-require-models', 'delayed_feedback_threshold_model', 'baseline_delayed_feedback', 'workflow demonstration', 'Reference delayed-feedback model'),
(2, 'why-complex-systems-require-models', 'delayed_feedback_threshold_model', 'long_delay', 'delay stress test', 'Longer delay scenario'),
(3, 'why-complex-systems-require-models', 'delayed_feedback_threshold_model', 'weak_balancing', 'feedback strength test', 'Weaker balancing feedback scenario'),
(4, 'why-complex-systems-require-models', 'delayed_feedback_threshold_model', 'higher_growth', 'growth stress test', 'Higher reinforcing growth scenario');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units
) VALUES
(1, 'growth_rate', 0.080, 'fraction per period'),
(1, 'balancing_strength', 0.060, 'fraction per period'),
(1, 'delay', 7, 'periods'),
(2, 'growth_rate', 0.080, 'fraction per period'),
(2, 'balancing_strength', 0.060, 'fraction per period'),
(2, 'delay', 14, 'periods'),
(3, 'growth_rate', 0.080, 'fraction per period'),
(3, 'balancing_strength', 0.030, 'fraction per period'),
(3, 'delay', 7, 'periods'),
(4, 'growth_rate', 0.105, 'fraction per period'),
(4, 'balancing_strength', 0.060, 'fraction per period'),
(4, 'delay', 7, 'periods');

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 160, 'illustrative_final_state', 72.0),
(1, 160, 'illustrative_peak_state', 132.0),
(2, 160, 'illustrative_final_state', 78.0),
(2, 160, 'illustrative_peak_state', 156.0),
(3, 160, 'illustrative_final_state', 118.0),
(3, 160, 'illustrative_peak_state', 190.0),
(4, 160, 'illustrative_final_state', 94.0),
(4, 160, 'illustrative_peak_state', 210.0);

INSERT INTO validation_targets (
  metric_name,
  target_low,
  target_high,
  notes
) VALUES
('final_state', 0, 250, 'Synthetic final-state range'),
('peak_state', 0, 250, 'Synthetic peak-state range'),
('delay', 0, 160, 'Delay should remain inside modeled time horizon');

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

SELECT * FROM v_scenario_parameter_inventory;
SELECT * FROM v_output_metric_summary;
