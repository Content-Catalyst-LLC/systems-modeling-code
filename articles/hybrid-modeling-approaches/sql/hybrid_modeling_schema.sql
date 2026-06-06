-- hybrid_modeling_schema.sql
-- SQLite schema and analysis queries for hybrid modeling workflows.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_module_registry;
DROP VIEW IF EXISTS v_interface_inventory;
DROP VIEW IF EXISTS v_output_metric_summary;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS interfaces;
DROP TABLE IF EXISTS modules;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE modules (
  module_id TEXT PRIMARY KEY,
  module_name TEXT NOT NULL,
  method_family TEXT NOT NULL,
  system_layer TEXT NOT NULL,
  state_variables TEXT NOT NULL,
  primary_output TEXT NOT NULL
);

CREATE TABLE interfaces (
  interface_id TEXT PRIMARY KEY,
  source_module TEXT NOT NULL,
  target_module TEXT NOT NULL,
  exchange_variable TEXT NOT NULL,
  units TEXT NOT NULL,
  exchange_frequency TEXT NOT NULL,
  transformation_rule TEXT NOT NULL
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

INSERT INTO modules (
  module_id,
  module_name,
  method_family,
  system_layer,
  state_variables,
  primary_output
) VALUES
('M1', 'aggregate_feedback', 'system_dynamics', 'macro', 'demand capacity adoption_pressure', 'aggregate_demand'),
('M2', 'heterogeneous_adoption', 'agent_based_modeling', 'micro', 'threshold adopted propensity', 'adoption_rate'),
('M3', 'interaction_network', 'network_modeling', 'relational', 'degree exposure bridge_status', 'network_pressure'),
('M4', 'service_queue', 'discrete_event_simulation', 'operational', 'queue_length busy_capacity service_backlog', 'queue_pressure'),
('M5', 'policy_scenario', 'scenario_modeling', 'governance', 'incentive capacity_investment implementation_delay', 'policy_signal');

INSERT INTO interfaces (
  interface_id,
  source_module,
  target_module,
  exchange_variable,
  units,
  exchange_frequency,
  transformation_rule
) VALUES
('I1', 'aggregate_feedback', 'heterogeneous_adoption', 'demand_signal', 'index', 'monthly', 'scale demand to agent decision pressure'),
('I2', 'heterogeneous_adoption', 'aggregate_feedback', 'adoption_rate', 'share', 'monthly', 'aggregate adopted agents into macro adoption'),
('I3', 'service_queue', 'heterogeneous_adoption', 'queue_pressure', 'index', 'weekly', 'reduce demand propensity under operational congestion'),
('I4', 'interaction_network', 'heterogeneous_adoption', 'peer_exposure', 'share', 'monthly', 'translate neighbor adoption into local exposure'),
('I5', 'policy_scenario', 'aggregate_feedback', 'policy_signal', 'index', 'annual', 'apply policy effect to aggregate growth and capacity');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'hybrid-modeling-approaches', 'hybrid_agent_queue', 'baseline_hybrid_agent_queue', 'workflow demonstration', 'Reference coupled agent-demand queue-pressure model'),
(2, 'hybrid-modeling-approaches', 'hybrid_agent_queue', 'low_capacity', 'capacity stress test', 'Lower service capacity scenario'),
(3, 'hybrid-modeling-approaches', 'hybrid_agent_queue', 'strong_pressure_feedback', 'coupling sensitivity test', 'Stronger feedback from queue pressure to demand'),
(4, 'hybrid-modeling-approaches', 'aggregate_agent_feedback', 'baseline_hybrid_feedback', 'cross-scale feedback demonstration', 'Aggregate demand and heterogeneous adoption coupling');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units
) VALUES
(1, 'service_capacity', 28, 'entities per step'),
(1, 'pressure_sensitivity', 0.18, 'index'),
(2, 'service_capacity', 18, 'entities per step'),
(2, 'pressure_sensitivity', 0.18, 'index'),
(3, 'service_capacity', 28, 'entities per step'),
(3, 'pressure_sensitivity', 0.35, 'index'),
(4, 'adoption_feedback', 0.25, 'index');

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 80, 'illustrative_average_queue_length', 4.20),
(1, 80, 'illustrative_average_utilization', 0.82),
(2, 80, 'illustrative_average_queue_length', 18.70),
(2, 80, 'illustrative_average_utilization', 0.96),
(3, 80, 'illustrative_average_queue_length', 2.90),
(3, 80, 'illustrative_average_utilization', 0.70),
(4, 60, 'illustrative_final_adoption_rate', 0.66),
(4, 60, 'illustrative_final_demand', 1.12);

CREATE VIEW v_module_registry AS
SELECT
  module_id,
  module_name,
  method_family,
  system_layer,
  state_variables,
  primary_output
FROM modules
ORDER BY module_id;

CREATE VIEW v_interface_inventory AS
SELECT
  interface_id,
  source_module,
  target_module,
  exchange_variable,
  units,
  exchange_frequency,
  transformation_rule
FROM interfaces
ORDER BY interface_id;

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

SELECT * FROM v_module_registry;
SELECT * FROM v_interface_inventory;
SELECT * FROM v_output_metric_summary;
