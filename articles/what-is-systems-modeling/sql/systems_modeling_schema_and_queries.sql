-- systems_modeling_schema_and_queries.sql
-- SQLite schema and analytical queries for systems modeling outputs.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS model_runs;
DROP TABLE IF EXISTS validation_diagnostics;

CREATE TABLE model_runs (
  run_id INTEGER PRIMARY KEY,
  article_slug TEXT NOT NULL,
  model_name TEXT NOT NULL,
  scenario_name TEXT NOT NULL,
  run_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  random_seed INTEGER,
  purpose TEXT NOT NULL,
  notes TEXT
);

CREATE TABLE scenario_parameters (
  parameter_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  parameter_name TEXT NOT NULL,
  parameter_value REAL NOT NULL,
  parameter_units TEXT,
  parameter_source TEXT,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE model_outputs (
  output_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  time_step INTEGER,
  entity_name TEXT,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE validation_diagnostics (
  diagnostic_id INTEGER PRIMARY KEY,
  run_id INTEGER,
  metric_name TEXT NOT NULL,
  observed_value REAL,
  target_low REAL,
  target_high REAL,
  passed INTEGER,
  notes TEXT,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  random_seed,
  purpose,
  notes
) VALUES
(1, 'what-is-systems-modeling', 'network_shock_propagation', 'baseline', 2026, 'workflow demonstration', 'Synthetic baseline network shock scenario'),
(2, 'what-is-systems-modeling', 'network_shock_propagation', 'high_coupling', 2026, 'stress testing', 'Synthetic scenario with stronger dependencies'),
(3, 'what-is-systems-modeling', 'network_shock_propagation', 'higher_redundancy', 2026, 'resilience comparison', 'Synthetic scenario with higher redundancy and recovery'),
(4, 'what-is-systems-modeling', 'stock_flow_ensemble', 'monte_carlo', 60606, 'uncertainty analysis', 'Synthetic stock-flow Monte Carlo ensemble');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units,
  parameter_source
) VALUES
(1, 'coupling_strength', 0.18, 'dimensionless', 'synthetic scenario'),
(1, 'recovery_rate', 0.075, 'fraction per time step', 'synthetic scenario'),
(1, 'redundancy', 0.20, 'fraction', 'synthetic scenario'),
(2, 'coupling_strength', 0.29, 'dimensionless', 'synthetic scenario'),
(2, 'recovery_rate', 0.070, 'fraction per time step', 'synthetic scenario'),
(2, 'redundancy', 0.12, 'fraction', 'synthetic scenario'),
(3, 'coupling_strength', 0.16, 'dimensionless', 'synthetic scenario'),
(3, 'recovery_rate', 0.105, 'fraction per time step', 'synthetic scenario'),
(3, 'redundancy', 0.44, 'fraction', 'synthetic scenario'),
(4, 'monte_carlo_runs', 300, 'runs', 'workflow configuration');

INSERT INTO model_outputs (
  run_id,
  time_step,
  entity_name,
  metric_name,
  metric_value
) VALUES
(1, 42, 'system', 'shock_time', 42),
(1, 140, 'system', 'illustrative_final_performance', 0.94),
(2, 140, 'system', 'illustrative_final_performance', 0.86),
(3, 140, 'system', 'illustrative_final_performance', 0.98),
(4, 180, 'ensemble', 'illustrative_median_recovery_ratio', 1.07);

CREATE VIEW v_model_run_summary AS
SELECT
  r.run_id,
  r.article_slug,
  r.model_name,
  r.scenario_name,
  r.purpose,
  COUNT(o.output_id) AS output_count,
  ROUND(AVG(o.metric_value), 6) AS average_metric_value
FROM model_runs r
LEFT JOIN model_outputs o
  ON r.run_id = o.run_id
GROUP BY
  r.run_id,
  r.article_slug,
  r.model_name,
  r.scenario_name,
  r.purpose;

CREATE VIEW v_parameter_inventory AS
SELECT
  r.model_name,
  r.scenario_name,
  p.parameter_name,
  p.parameter_value,
  p.parameter_units,
  p.parameter_source
FROM scenario_parameters p
JOIN model_runs r
  ON p.run_id = r.run_id
ORDER BY
  r.model_name,
  r.scenario_name,
  p.parameter_name;

CREATE VIEW v_output_metric_summary AS
SELECT
  r.model_name,
  r.scenario_name,
  o.metric_name,
  COUNT(*) AS observation_count,
  ROUND(MIN(o.metric_value), 6) AS minimum_value,
  ROUND(AVG(o.metric_value), 6) AS average_value,
  ROUND(MAX(o.metric_value), 6) AS maximum_value
FROM model_outputs o
JOIN model_runs r
  ON o.run_id = r.run_id
GROUP BY
  r.model_name,
  r.scenario_name,
  o.metric_name;

.headers on
.mode column

SELECT * FROM v_model_run_summary;
SELECT * FROM v_parameter_inventory;
SELECT * FROM v_output_metric_summary;
