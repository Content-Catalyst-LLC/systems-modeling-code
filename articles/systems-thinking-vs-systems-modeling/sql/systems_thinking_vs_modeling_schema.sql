-- systems_thinking_vs_modeling_schema.sql
-- SQLite schema for conceptual-to-formal systems modeling diagnostics.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS conceptual_relationships;
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

CREATE TABLE conceptual_relationships (
  relationship_id INTEGER PRIMARY KEY,
  source TEXT NOT NULL,
  target TEXT NOT NULL,
  polarity TEXT NOT NULL,
  relationship_strength REAL NOT NULL,
  relationship_type TEXT NOT NULL,
  description TEXT
);

CREATE TABLE scenario_parameters (
  parameter_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  parameter_name TEXT NOT NULL,
  parameter_value REAL NOT NULL,
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

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'systems-thinking-vs-systems-modeling', 'conceptual_formal_gap_model', 'linear_pressure_frame', 'diagnostic comparison', 'High intervention pressure with weak structural redesign'),
(2, 'systems-thinking-vs-systems-modeling', 'conceptual_formal_gap_model', 'conceptual_systems_frame', 'diagnostic comparison', 'Systems thinking with partial formal model discipline'),
(3, 'systems-thinking-vs-systems-modeling', 'conceptual_formal_gap_model', 'formal_model_learning_frame', 'diagnostic comparison', 'Formal learning-oriented systems modeling');

INSERT INTO conceptual_relationships (
  source,
  target,
  polarity,
  relationship_strength,
  relationship_type,
  description
) VALUES
('demand', 'backlog', 'positive', 0.72, 'stock_flow', 'Higher demand increases backlog when capacity is constrained'),
('capacity', 'backlog', 'negative', 0.66, 'stock_flow', 'Higher capacity reduces backlog'),
('backlog', 'trust', 'negative', 0.58, 'feedback', 'Higher backlog reduces trust'),
('trust', 'service_quality', 'positive', 0.41, 'feedback', 'Higher trust improves cooperation and perceived service quality'),
('service_quality', 'trust', 'positive', 0.47, 'feedback', 'Higher service quality rebuilds trust'),
('intervention_pressure', 'rework', 'positive', 0.52, 'unintended_consequence', 'Pressure increases rework when structure is unchanged'),
('rework', 'capacity', 'negative', 0.44, 'feedback', 'Rework consumes usable capacity'),
('learning', 'capacity', 'positive', 0.50, 'adaptive_feedback', 'Learning improves effective capacity');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value
) VALUES
(1, 'intervention_pressure', 0.82),
(1, 'systems_redesign_strength', 0.12),
(1, 'uncertainty_humility', 0.18),
(2, 'intervention_pressure', 0.48),
(2, 'systems_redesign_strength', 0.54),
(2, 'uncertainty_humility', 0.55),
(3, 'intervention_pressure', 0.28),
(3, 'systems_redesign_strength', 0.78),
(3, 'uncertainty_humility', 0.82);

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 80, 'illustrative_final_modeled_score', 42.0),
(1, 80, 'illustrative_conceptual_model_gap', 21.0),
(2, 80, 'illustrative_final_modeled_score', 61.0),
(2, 80, 'illustrative_conceptual_model_gap', 12.0),
(3, 80, 'illustrative_final_modeled_score', 74.0),
(3, 80, 'illustrative_conceptual_model_gap', 7.0);

CREATE VIEW v_relationship_inventory AS
SELECT
  relationship_type,
  polarity,
  COUNT(*) AS relationship_count,
  ROUND(AVG(relationship_strength), 3) AS average_strength
FROM conceptual_relationships
GROUP BY relationship_type, polarity;

CREATE VIEW v_scenario_parameter_summary AS
SELECT
  r.scenario_name,
  p.parameter_name,
  p.parameter_value
FROM scenario_parameters p
JOIN model_runs r
  ON p.run_id = r.run_id
ORDER BY r.scenario_name, p.parameter_name;

CREATE VIEW v_model_output_summary AS
SELECT
  r.scenario_name,
  o.metric_name,
  ROUND(AVG(o.metric_value), 3) AS average_metric_value,
  ROUND(MIN(o.metric_value), 3) AS minimum_metric_value,
  ROUND(MAX(o.metric_value), 3) AS maximum_metric_value
FROM model_outputs o
JOIN model_runs r
  ON o.run_id = r.run_id
GROUP BY r.scenario_name, o.metric_name;

.headers on
.mode column

SELECT * FROM v_relationship_inventory;
SELECT * FROM v_scenario_parameter_summary;
SELECT * FROM v_model_output_summary;
