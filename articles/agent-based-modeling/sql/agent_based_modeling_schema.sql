-- agent_based_modeling_schema.sql
-- SQLite schema and analysis queries for agent-based modeling workflows.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS agent_rule_inventory;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE agent_rule_inventory (
  rule_id TEXT PRIMARY KEY,
  rule_name TEXT NOT NULL,
  rule_type TEXT NOT NULL,
  agent_state TEXT NOT NULL,
  interaction_structure TEXT NOT NULL,
  macro_observable TEXT NOT NULL
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

INSERT INTO agent_rule_inventory (
  rule_id,
  rule_name,
  rule_type,
  agent_state,
  interaction_structure,
  macro_observable
) VALUES
('R1', 'local_satisfaction_rule', 'spatial_relocation', 'agent_type location satisfied', 'grid_neighbors', 'clustering_index'),
('R2', 'threshold_adoption_rule', 'diffusion', 'adopted threshold', 'ring_neighbors', 'adoption_rate'),
('R3', 'heterogeneous_thresholds', 'agent_diversity', 'threshold adopted', 'local_network', 'adoption_distribution'),
('R4', 'randomized_update_order', 'scheduling', 'agent_order', 'simulation_schedule', 'run_variability'),
('R5', 'scenario_parameterization', 'experiment_design', 'threshold_radius_seed', 'scenario_set', 'comparative_outcomes');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'agent-based-modeling', 'schelling_spatial_abm', 'baseline_abm', 'workflow demonstration', 'Reference spatial interaction model'),
(2, 'agent-based-modeling', 'schelling_spatial_abm', 'high_threshold', 'behavioral sensitivity test', 'Higher satisfaction threshold scenario'),
(3, 'agent-based-modeling', 'threshold_adoption_abm', 'baseline_threshold_adoption', 'workflow demonstration', 'Reference threshold adoption model'),
(4, 'agent-based-modeling', 'threshold_adoption_abm', 'low_threshold_population', 'behavioral sensitivity test', 'Lower adoption threshold scenario');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units
) VALUES
(1, 'satisfaction_threshold', 0.45, 'share'),
(1, 'empty_share', 0.18, 'share'),
(2, 'satisfaction_threshold', 0.60, 'share'),
(2, 'empty_share', 0.18, 'share'),
(3, 'threshold_low', 0.10, 'share'),
(3, 'threshold_high', 0.70, 'share'),
(3, 'initial_adopters', 12, 'agents'),
(4, 'threshold_low', 0.05, 'share'),
(4, 'threshold_high', 0.45, 'share'),
(4, 'initial_adopters', 12, 'agents');

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 60, 'illustrative_final_satisfied_share', 0.95),
(1, 60, 'illustrative_final_clustering_index', 0.74),
(2, 60, 'illustrative_final_satisfied_share', 0.90),
(2, 60, 'illustrative_final_clustering_index', 0.86),
(3, 50, 'illustrative_final_adoption_rate', 0.58),
(3, 50, 'illustrative_peak_new_adopters', 14),
(4, 50, 'illustrative_final_adoption_rate', 0.94),
(4, 50, 'illustrative_peak_new_adopters', 31);

CREATE VIEW v_agent_rule_inventory AS
SELECT
  rule_id,
  rule_name,
  rule_type,
  agent_state,
  interaction_structure,
  macro_observable
FROM agent_rule_inventory
ORDER BY rule_id;

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

SELECT * FROM v_agent_rule_inventory;
SELECT * FROM v_scenario_parameter_inventory;
SELECT * FROM v_output_metric_summary;
