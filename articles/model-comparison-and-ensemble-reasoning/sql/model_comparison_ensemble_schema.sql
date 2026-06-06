-- model_comparison_ensemble_schema.sql
-- SQLite schema and analysis queries for model comparison and ensemble reasoning.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_model_families;
DROP VIEW IF EXISTS v_comparison_criteria;
DROP VIEW IF EXISTS v_validation_metric_summary;
DROP VIEW IF EXISTS v_policy_robustness_summary;

DROP TABLE IF EXISTS policy_outputs;
DROP TABLE IF EXISTS validation_metrics;
DROP TABLE IF EXISTS model_weights;
DROP TABLE IF EXISTS model_runs;
DROP TABLE IF EXISTS comparison_criteria;
DROP TABLE IF EXISTS model_families;

CREATE TABLE model_families (
  model TEXT PRIMARY KEY,
  model_family TEXT NOT NULL,
  structure TEXT NOT NULL,
  primary_use TEXT NOT NULL,
  known_limitation TEXT NOT NULL
);

CREATE TABLE comparison_criteria (
  criterion TEXT PRIMARY KEY,
  question TEXT NOT NULL,
  metric_or_evidence TEXT NOT NULL,
  notes TEXT NOT NULL
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

CREATE TABLE validation_metrics (
  metric_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  dataset TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE model_weights (
  weight_id INTEGER PRIMARY KEY,
  model_name TEXT NOT NULL,
  weight_type TEXT NOT NULL,
  weight REAL NOT NULL
);

CREATE TABLE policy_outputs (
  output_id INTEGER PRIMARY KEY,
  policy_name TEXT NOT NULL,
  model_name TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL
);

INSERT INTO model_families (
  model,
  model_family,
  structure,
  primary_use,
  known_limitation
) VALUES
('exponential', 'aggregate_growth', 'Unbounded growth recurrence', 'Simple benchmark and stress baseline', 'Can overstate growth when saturation exists'),
('logistic', 'capacity_limited_growth', 'Capacity-limited nonlinear recurrence', 'Models saturation and carrying capacity', 'Does not represent active extraction or management'),
('managed_logistic', 'managed_dynamic_system', 'Capacity-limited growth with extraction pressure', 'Represents managed system pressure', 'Still simplified and synthetic'),
('equal_weight_ensemble', 'ensemble_average', 'Equal-weight average across model families', 'Transparent ensemble comparison', 'Assumes equal credibility and dependence'),
('performance_weighted_ensemble', 'weighted_ensemble', 'Inverse-validation-error weighted model average', 'Validation-informed ensemble comparison', 'Can overfit validation metric');

INSERT INTO comparison_criteria (
  criterion,
  question,
  metric_or_evidence,
  notes
) VALUES
('calibration_fit', 'How well does the model fit calibration data?', 'calibration_rmse', 'Fit alone is not validation'),
('validation_performance', 'How well does the model generalize?', 'validation_rmse', 'Uses held-out validation period'),
('bias', 'Does the model systematically overpredict or underpredict?', 'mean_residual', 'Positive and negative errors can cancel'),
('structural_plausibility', 'Does the structure represent plausible mechanisms?', 'model_metadata_review', 'Requires expert judgment'),
('benchmark_value', 'Does complexity improve on simpler alternatives?', 'rank_against_benchmarks', 'Complexity must earn its keep'),
('model_dependence', 'Are models independent?', 'shared_data_and_assumption_notes', 'Agreement may reflect shared assumptions');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  run_type,
  purpose,
  notes
) VALUES
(1, 'model-comparison-and-ensemble-reasoning', 'exponential', 'validation', 'benchmark model comparison', 'Synthetic validation example'),
(2, 'model-comparison-and-ensemble-reasoning', 'logistic', 'validation', 'structural model comparison', 'Synthetic validation example'),
(3, 'model-comparison-and-ensemble-reasoning', 'managed_logistic', 'validation', 'managed systems model comparison', 'Synthetic validation example'),
(4, 'model-comparison-and-ensemble-reasoning', 'equal_weight_ensemble', 'validation', 'ensemble model comparison', 'Synthetic validation example'),
(5, 'model-comparison-and-ensemble-reasoning', 'performance_weighted_ensemble', 'validation', 'weighted ensemble comparison', 'Synthetic validation example');

INSERT INTO validation_metrics (
  run_id,
  dataset,
  metric_name,
  metric_value
) VALUES
(1, 'validation', 'illustrative_rmse', 8.40),
(2, 'validation', 'illustrative_rmse', 2.85),
(3, 'validation', 'illustrative_rmse', 1.12),
(4, 'validation', 'illustrative_rmse', 2.64),
(5, 'validation', 'illustrative_rmse', 1.38),
(1, 'validation', 'illustrative_mae', 7.20),
(2, 'validation', 'illustrative_mae', 2.10),
(3, 'validation', 'illustrative_mae', 0.92),
(4, 'validation', 'illustrative_mae', 2.05),
(5, 'validation', 'illustrative_mae', 1.02);

INSERT INTO model_weights (
  model_name,
  weight_type,
  weight
) VALUES
('exponential', 'validation_inverse_rmse', 0.08),
('logistic', 'validation_inverse_rmse', 0.28),
('managed_logistic', 'validation_inverse_rmse', 0.64);

INSERT INTO policy_outputs (
  policy_name,
  model_name,
  metric_name,
  metric_value
) VALUES
('Policy_A_low_intervention', 'model_ensemble', 'illustrative_mean_regret', 17.4),
('Policy_B_balanced', 'model_ensemble', 'illustrative_mean_regret', 4.8),
('Policy_C_high_adaptation', 'model_ensemble', 'illustrative_mean_regret', 8.7),
('Policy_A_low_intervention', 'model_ensemble', 'illustrative_worst_score', 18.2),
('Policy_B_balanced', 'model_ensemble', 'illustrative_worst_score', 45.5),
('Policy_C_high_adaptation', 'model_ensemble', 'illustrative_worst_score', 39.1);

CREATE VIEW v_model_families AS
SELECT
  model,
  model_family,
  structure,
  primary_use,
  known_limitation
FROM model_families
ORDER BY model;

CREATE VIEW v_comparison_criteria AS
SELECT
  criterion,
  question,
  metric_or_evidence,
  notes
FROM comparison_criteria
ORDER BY criterion;

CREATE VIEW v_validation_metric_summary AS
SELECT
  r.model_name,
  m.dataset,
  m.metric_name,
  ROUND(MIN(m.metric_value), 3) AS minimum_value,
  ROUND(AVG(m.metric_value), 3) AS average_value,
  ROUND(MAX(m.metric_value), 3) AS maximum_value
FROM validation_metrics m
JOIN model_runs r
  ON m.run_id = r.run_id
GROUP BY r.model_name, m.dataset, m.metric_name
ORDER BY m.metric_name, average_value;

CREATE VIEW v_policy_robustness_summary AS
SELECT
  policy_name,
  metric_name,
  ROUND(metric_value, 3) AS metric_value
FROM policy_outputs
ORDER BY policy_name, metric_name;

.headers on
.mode column

SELECT * FROM v_model_families;
SELECT * FROM v_comparison_criteria;
SELECT * FROM v_validation_metric_summary;
SELECT * FROM v_policy_robustness_summary;
