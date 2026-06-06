-- history_of_systems_modeling_schema.sql
-- SQLite schema and analysis queries for historical systems-modeling workflows.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS historical_milestones;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE historical_milestones (
  milestone_id INTEGER PRIMARY KEY,
  period TEXT NOT NULL,
  tradition TEXT NOT NULL,
  core_contribution TEXT NOT NULL,
  representational_focus TEXT NOT NULL,
  example_modeling_problem TEXT
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

INSERT INTO historical_milestones (
  period,
  tradition,
  core_contribution,
  representational_focus,
  example_modeling_problem
) VALUES
('1940s', 'cybernetics', 'feedback and control', 'error correction and regulation', 'thermostat regulation and biological control'),
('1940s-1960s', 'general_systems_theory', 'boundary and cross-domain structure', 'open systems and hierarchy', 'biological and social system organization'),
('1950s-1960s', 'system_dynamics', 'stocks flows feedback and delay', 'dynamic accumulation and behavior over time', 'industrial inventory oscillation'),
('1950s-1970s', 'operations_research', 'constraints allocation and queues', 'resource use and process flow', 'logistics scheduling and service systems'),
('1960s-1980s', 'computer_simulation', 'executable dynamic experiments', 'stochastic and nonlinear simulation', 'scenario comparison under uncertainty'),
('1970s', 'global_modeling', 'coupled socioecological systems', 'long-horizon resource and population models', 'limits to growth scenarios'),
('1980s-2000s', 'complexity_science', 'emergence and adaptation', 'local interaction and nonlinear macro behavior', 'complex adaptive systems'),
('1990s-present', 'agent_based_modeling', 'heterogeneous actors and local rules', 'bottom-up emergence', 'diffusion adoption markets epidemics'),
('1990s-present', 'network_modeling', 'connectivity dependency and propagation', 'nodes edges contagion and centrality', 'infrastructure and financial contagion'),
('1990s-present', 'integrated_assessment_modeling', 'coupled sectoral pathways', 'energy economy land climate and policy', 'climate mitigation scenarios');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'history-of-systems-modeling', 'historical_dynamics_comparison', 'baseline_historical_dynamics', 'workflow demonstration', 'Reference growth, constraint, and delayed feedback comparison'),
(2, 'history-of-systems-modeling', 'historical_dynamics_comparison', 'long_delay', 'delay stress test', 'Longer delay scenario'),
(3, 'history-of-systems-modeling', 'historical_dynamics_comparison', 'weak_balancing', 'feedback strength test', 'Weaker balancing feedback scenario'),
(4, 'history-of-systems-modeling', 'historical_dynamics_comparison', 'higher_growth', 'growth stress test', 'Higher reinforcing growth scenario');

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
(1, 160, 'illustrative_final_delayed_feedback', 74.0),
(1, 160, 'illustrative_peak_delayed_feedback', 132.0),
(2, 160, 'illustrative_final_delayed_feedback', 82.0),
(2, 160, 'illustrative_peak_delayed_feedback', 156.0),
(3, 160, 'illustrative_final_delayed_feedback', 116.0),
(3, 160, 'illustrative_peak_delayed_feedback', 185.0),
(4, 160, 'illustrative_final_delayed_feedback', 94.0),
(4, 160, 'illustrative_peak_delayed_feedback', 205.0);

CREATE VIEW v_historical_method_inventory AS
SELECT
  period,
  tradition,
  core_contribution,
  representational_focus
FROM historical_milestones
ORDER BY milestone_id;

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

SELECT * FROM v_historical_method_inventory;
SELECT * FROM v_scenario_parameter_inventory;
SELECT * FROM v_output_metric_summary;
