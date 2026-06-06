-- uncertainty_interpretation_schema.sql
-- SQLite schema and analysis queries for uncertainty interpretation workflows.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_uncertainty_sources;
DROP VIEW IF EXISTS v_policy_options;
DROP VIEW IF EXISTS v_output_metric_summary;
DROP VIEW IF EXISTS v_confidence_language;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS model_runs;
DROP TABLE IF EXISTS confidence_language;
DROP TABLE IF EXISTS policy_options;
DROP TABLE IF EXISTS uncertainty_sources;

CREATE TABLE uncertainty_sources (
  source_id TEXT PRIMARY KEY,
  uncertainty_type TEXT NOT NULL,
  source_name TEXT NOT NULL,
  modeling_example TEXT NOT NULL,
  interpretive_response TEXT NOT NULL
);

CREATE TABLE policy_options (
  policy_id INTEGER PRIMARY KEY,
  policy_name TEXT NOT NULL,
  policy_strength REAL NOT NULL,
  adaptive_capacity REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE confidence_language (
  category TEXT PRIMARY KEY,
  meaning TEXT NOT NULL,
  example TEXT NOT NULL
);

CREATE TABLE model_runs (
  run_id INTEGER PRIMARY KEY,
  article_slug TEXT NOT NULL,
  model_name TEXT NOT NULL,
  run_type TEXT NOT NULL,
  run_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  purpose TEXT NOT NULL,
  notes TEXT
);

CREATE TABLE model_outputs (
  output_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  policy_name TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT INTO uncertainty_sources (
  source_id,
  uncertainty_type,
  source_name,
  modeling_example,
  interpretive_response
) VALUES
('U1', 'parameter', 'growth_rate_uncertainty', 'Uncertain growth or accumulation rate', 'Use parameter ranges and sensitivity analysis'),
('U2', 'parameter', 'shock_intensity_uncertainty', 'Unknown magnitude of disturbance or disruption', 'Use scenario ensembles and stress tests'),
('U3', 'scenario', 'policy_context_uncertainty', 'Unknown future implementation or governance conditions', 'Use structured scenarios and robustness diagnostics'),
('U4', 'structural', 'feedback_structure_uncertainty', 'Uncertain feedback or adaptation mechanism', 'Compare alternative structures and document boundaries'),
('U5', 'data', 'measurement_uncertainty', 'Noisy or incomplete observations', 'Document data provenance and measurement limits'),
('U6', 'deep', 'probability_model_uncertainty', 'Probabilities and outcome space are contested', 'Use robust decision methods and exploratory modeling');

INSERT INTO policy_options (
  policy_id,
  policy_name,
  policy_strength,
  adaptive_capacity,
  description
) VALUES
(1, 'Policy_A_low_control', 0.025, 0.010, 'Low direct control and limited adaptive capacity'),
(2, 'Policy_B_balanced', 0.045, 0.020, 'Balanced policy control and moderate adaptive capacity'),
(3, 'Policy_C_high_adaptation', 0.035, 0.045, 'Adaptation-oriented policy with stronger response capacity'),
(4, 'Policy_D_precautionary', 0.055, 0.040, 'Higher control and adaptation with stronger precautionary assumptions');

INSERT INTO confidence_language (
  category,
  meaning,
  example
) VALUES
('likelihood', 'Estimated event frequency under a defined model or ensemble', 'The event occurs in 70 percent of ensemble runs'),
('confidence', 'Strength of evidence and agreement behind a conclusion', 'High confidence in direction but lower confidence in magnitude'),
('robustness', 'Stability of a conclusion across assumptions', 'Policy ranking is stable across tested scenarios'),
('fragility', 'Dependence of conclusion on uncertain assumptions', 'Result changes when growth exceeds the high scenario range'),
('domain_of_applicability', 'Scope where the model can responsibly be interpreted', 'Scenario comparison only not point forecasting');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  run_type,
  purpose,
  notes
) VALUES
(1, 'uncertainty-and-model-interpretation', 'deep_uncertainty_policy_ensemble', 'scenario_ensemble', 'robustness comparison', 'Synthetic policy comparison across uncertainty space'),
(2, 'uncertainty-and-model-interpretation', 'uncertainty_propagation_model', 'monte_carlo', 'uncertainty propagation', 'Synthetic parameter and shock uncertainty');

INSERT INTO model_outputs (
  run_id,
  policy_name,
  metric_name,
  metric_value
) VALUES
(1, 'Policy_A_low_control', 'illustrative_mean_resilience_score', 31.5),
(1, 'Policy_B_balanced', 'illustrative_mean_resilience_score', 52.8),
(1, 'Policy_C_high_adaptation', 'illustrative_mean_resilience_score', 61.4),
(1, 'Policy_D_precautionary', 'illustrative_mean_resilience_score', 66.2),
(1, 'Policy_C_high_adaptation', 'illustrative_mean_regret', 7.3),
(2, 'ensemble', 'illustrative_final_state_p10', 42.1),
(2, 'ensemble', 'illustrative_final_state_p90', 118.7);

CREATE VIEW v_uncertainty_sources AS
SELECT
  source_id,
  uncertainty_type,
  source_name,
  modeling_example,
  interpretive_response
FROM uncertainty_sources
ORDER BY source_id;

CREATE VIEW v_policy_options AS
SELECT
  policy_name,
  policy_strength,
  adaptive_capacity,
  description
FROM policy_options
ORDER BY policy_id;

CREATE VIEW v_confidence_language AS
SELECT
  category,
  meaning,
  example
FROM confidence_language
ORDER BY category;

CREATE VIEW v_output_metric_summary AS
SELECT
  r.run_type,
  o.policy_name,
  o.metric_name,
  COUNT(*) AS observation_count,
  ROUND(MIN(o.metric_value), 3) AS minimum_value,
  ROUND(AVG(o.metric_value), 3) AS average_value,
  ROUND(MAX(o.metric_value), 3) AS maximum_value
FROM model_outputs o
JOIN model_runs r
  ON o.run_id = r.run_id
GROUP BY r.run_type, o.policy_name, o.metric_name;

.headers on
.mode column

SELECT * FROM v_uncertainty_sources;
SELECT * FROM v_policy_options;
SELECT * FROM v_confidence_language;
SELECT * FROM v_output_metric_summary;
