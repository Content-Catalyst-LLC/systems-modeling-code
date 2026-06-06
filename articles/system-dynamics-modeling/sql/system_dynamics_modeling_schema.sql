-- system_dynamics_modeling_schema.sql
-- SQLite schema and analysis queries for system dynamics modeling workflows.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS causal_loop_inventory;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE causal_loop_inventory (
  loop_id TEXT PRIMARY KEY,
  loop_name TEXT NOT NULL,
  loop_type TEXT NOT NULL,
  variables TEXT NOT NULL,
  interpretation TEXT NOT NULL,
  stock_flow_translation TEXT NOT NULL
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

INSERT INTO causal_loop_inventory (
  loop_id,
  loop_name,
  loop_type,
  variables,
  interpretation,
  stock_flow_translation
) VALUES
('R1', 'capacity_growth', 'reinforcing', 'stock inflow visibility adoption', 'More stock increases reinforcing inflow until capacity constraints bind', 'stock creates inflow through growth_rate'),
('B1', 'target_correction', 'balancing', 'stock delayed_stock target outflow', 'Delayed stock above target triggers corrective outflow', 'outflow depends on max(delayed_stock-target,0)'),
('B2', 'capacity_constraint', 'balancing', 'stock capacity inflow', 'Growth slows as stock approaches capacity', 'inflow uses logistic capacity term'),
('B3', 'threshold_pressure', 'balancing', 'stock threshold penalty', 'Stock above threshold triggers nonlinear correction', 'threshold_penalty activates above threshold'),
('S1', 'shock_response', 'disturbance', 'shock stock recovery', 'A discrete shock disturbs the stock and tests recovery', 'shock enters stock update directly');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'system-dynamics-modeling', 'stock_flow_delayed_feedback_model', 'baseline_system_dynamics', 'workflow demonstration', 'Reference system dynamics model'),
(2, 'system-dynamics-modeling', 'stock_flow_delayed_feedback_model', 'long_delay', 'delay stress test', 'Longer delay scenario'),
(3, 'system-dynamics-modeling', 'stock_flow_delayed_feedback_model', 'weak_balancing', 'feedback strength test', 'Weaker balancing feedback scenario'),
(4, 'system-dynamics-modeling', 'stock_flow_delayed_feedback_model', 'strong_threshold_correction', 'threshold stress test', 'Stronger threshold correction scenario');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units
) VALUES
(1, 'growth_rate', 0.090, 'fraction per period'),
(1, 'balancing_strength', 0.055, 'fraction per period'),
(1, 'delay', 7, 'periods'),
(1, 'capacity', 100, 'stock units'),
(2, 'growth_rate', 0.090, 'fraction per period'),
(2, 'balancing_strength', 0.055, 'fraction per period'),
(2, 'delay', 14, 'periods'),
(2, 'capacity', 100, 'stock units'),
(3, 'growth_rate', 0.090, 'fraction per period'),
(3, 'balancing_strength', 0.025, 'fraction per period'),
(3, 'delay', 7, 'periods'),
(3, 'capacity', 100, 'stock units'),
(4, 'growth_rate', 0.090, 'fraction per period'),
(4, 'balancing_strength', 0.055, 'fraction per period'),
(4, 'delay', 7, 'periods'),
(4, 'capacity', 100, 'stock units');

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 160, 'illustrative_final_stock', 72.0),
(1, 160, 'illustrative_peak_stock', 104.0),
(2, 160, 'illustrative_final_stock', 79.0),
(2, 160, 'illustrative_peak_stock', 132.0),
(3, 160, 'illustrative_final_stock', 94.0),
(3, 160, 'illustrative_peak_stock', 150.0),
(4, 160, 'illustrative_final_stock', 68.0),
(4, 160, 'illustrative_peak_stock', 86.0);

CREATE VIEW v_causal_loop_inventory AS
SELECT
  loop_id,
  loop_name,
  loop_type,
  variables,
  interpretation,
  stock_flow_translation
FROM causal_loop_inventory
ORDER BY loop_id;

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

SELECT * FROM v_causal_loop_inventory;
SELECT * FROM v_scenario_parameter_inventory;
SELECT * FROM v_output_metric_summary;
