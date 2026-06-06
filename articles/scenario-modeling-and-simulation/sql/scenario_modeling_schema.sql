-- scenario_modeling_schema.sql
-- SQLite schema and analysis queries for scenario modeling workflows.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_policy_levers;
DROP VIEW IF EXISTS v_output_metric_summary;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS policy_levers;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE scenario_definitions (
  scenario_id INTEGER PRIMARY KEY,
  scenario_name TEXT NOT NULL,
  scenario_type TEXT NOT NULL,
  growth REAL NOT NULL,
  policy_drag REAL NOT NULL,
  shock_time INTEGER NOT NULL,
  shock_size REAL NOT NULL,
  resilience_investment REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE policy_levers (
  policy_id INTEGER PRIMARY KEY,
  policy_name TEXT NOT NULL,
  policy_drag REAL NOT NULL,
  resilience_buffer REAL NOT NULL,
  implementation_delay INTEGER NOT NULL,
  description TEXT NOT NULL
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

CREATE TABLE model_outputs (
  output_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  time_step INTEGER,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT INTO scenario_definitions (
  scenario_id,
  scenario_name,
  scenario_type,
  growth,
  policy_drag,
  shock_time,
  shock_size,
  resilience_investment,
  description
) VALUES
(1, 'baseline', 'baseline', 0.045, 0.000, 0, 0, 0, 'Continuation of reference growth without intervention or shock'),
(2, 'policy_intervention', 'policy', 0.045, 0.020, 0, 0, 0, 'Policy drag reduces growth pressure over time'),
(3, 'stress_shock', 'stress', 0.045, 0.000, 42, 22, 0, 'External shock tests system vulnerability'),
(4, 'rapid_growth', 'exploratory', 0.065, 0.000, 0, 0, 0, 'Higher growth pressure explores accelerated demand'),
(5, 'resilience_investment', 'policy_stress', 0.045, 0.012, 42, 22, 8, 'Policy plus resilience buffer tests shock absorption');

INSERT INTO policy_levers (
  policy_id,
  policy_name,
  policy_drag,
  resilience_buffer,
  implementation_delay,
  description
) VALUES
(1, 'Policy_A_low_intervention', 0.010, 4, 0, 'Low intervention with limited resilience buffer'),
(2, 'Policy_B_moderate_intervention', 0.025, 7, 0, 'Moderate intervention with medium resilience buffer'),
(3, 'Policy_C_high_resilience', 0.020, 12, 0, 'Resilience-oriented policy with stronger shock buffer'),
(4, 'Policy_D_delayed_adaptation', 0.015, 6, 8, 'Delayed adaptation with moderate policy effect');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'scenario-modeling-and-simulation', 'dynamic_scenario_model', 'baseline', 'workflow demonstration', 'Reference scenario'),
(2, 'scenario-modeling-and-simulation', 'dynamic_scenario_model', 'policy_intervention', 'policy comparison', 'Policy intervention scenario'),
(3, 'scenario-modeling-and-simulation', 'dynamic_scenario_model', 'stress_shock', 'stress test', 'Shock scenario'),
(4, 'scenario-modeling-and-simulation', 'policy_robustness_ensemble', 'ensemble', 'robustness comparison', 'Policy comparison across uncertain futures');

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 80, 'illustrative_final_state', 680.0),
(2, 80, 'illustrative_final_state', 142.0),
(3, 80, 'illustrative_final_state', 675.0),
(4, 60, 'illustrative_mean_regret', 8.4),
(4, 60, 'illustrative_worst_resilience_score', 31.2);

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario_name,
  scenario_type,
  growth,
  policy_drag,
  shock_time,
  shock_size,
  resilience_investment,
  description
FROM scenario_definitions
ORDER BY scenario_id;

CREATE VIEW v_policy_levers AS
SELECT
  policy_name,
  policy_drag,
  resilience_buffer,
  implementation_delay,
  description
FROM policy_levers
ORDER BY policy_id;

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

SELECT * FROM v_scenario_definitions;
SELECT * FROM v_policy_levers;
SELECT * FROM v_output_metric_summary;
