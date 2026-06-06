-- calibration_validation_schema.sql
-- SQLite schema and analysis queries for calibration and validation workflows.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_calibration_settings;
DROP VIEW IF EXISTS v_structural_validation_checks;
DROP VIEW IF EXISTS v_validation_metric_summary;
DROP VIEW IF EXISTS v_benchmark_comparison;

DROP TABLE IF EXISTS validation_metrics;
DROP TABLE IF EXISTS parameter_estimates;
DROP TABLE IF EXISTS benchmark_metrics;
DROP TABLE IF EXISTS structural_validation_checks;
DROP TABLE IF EXISTS calibration_settings;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE calibration_settings (
  setting TEXT PRIMARY KEY,
  value REAL NOT NULL,
  units TEXT NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE structural_validation_checks (
  check_id TEXT PRIMARY KEY,
  check_name TEXT NOT NULL,
  validation_type TEXT NOT NULL,
  question TEXT NOT NULL,
  evidence_required TEXT NOT NULL
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

CREATE TABLE parameter_estimates (
  estimate_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  parameter TEXT NOT NULL,
  estimated_value REAL NOT NULL,
  lower_bound REAL NOT NULL,
  upper_bound REAL NOT NULL,
  calibration_method TEXT NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE validation_metrics (
  metric_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  dataset TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE benchmark_metrics (
  benchmark_id INTEGER PRIMARY KEY,
  benchmark_name TEXT NOT NULL,
  validation_rmse REAL NOT NULL,
  validation_mae REAL NOT NULL,
  validation_bias REAL NOT NULL
);

INSERT INTO calibration_settings (
  setting,
  value,
  units,
  description
) VALUES
('n_steps', 80, 'time_steps', 'Synthetic observed series length'),
('train_cutoff', 52, 'time_step', 'Last observation used for calibration'),
('true_growth_rate', 0.095, 'per_time_step', 'Synthetic data-generating growth parameter'),
('true_carrying_capacity', 120, 'state_units', 'Synthetic data-generating carrying capacity'),
('noise_sd', 0.85, 'state_units', 'Synthetic observation noise standard deviation'),
('initial_state', 10, 'state_units', 'Initial model state');

INSERT INTO structural_validation_checks (
  check_id,
  check_name,
  validation_type,
  question,
  evidence_required
) VALUES
('S1', 'boundary_check', 'structural', 'Are system boundaries explicit and defensible?', 'Document included and excluded mechanisms'),
('S2', 'equation_check', 'verification', 'Do implemented equations match intended model?', 'Equation review and code inspection'),
('S3', 'parameter_plausibility', 'calibration', 'Are calibrated values within defensible ranges?', 'Parameter bounds and source notes'),
('S4', 'out_of_sample_check', 'empirical', 'Does the model perform on held-out data?', 'Validation-period metrics'),
('S5', 'residual_pattern_check', 'empirical', 'Do residuals show systematic structure?', 'Residual table and plot'),
('S6', 'benchmark_check', 'comparative', 'Does the model improve on a simpler benchmark?', 'Benchmark error comparison');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  run_type,
  purpose,
  notes
) VALUES
(1, 'calibration-and-validation-of-models', 'logistic_dynamic_model', 'calibration', 'parameter calibration demonstration', 'Synthetic training-period calibration'),
(2, 'calibration-and-validation-of-models', 'logistic_dynamic_model', 'validation', 'out-of-sample validation demonstration', 'Synthetic validation-period evaluation'),
(3, 'calibration-and-validation-of-models', 'benchmark_models', 'benchmark_validation', 'benchmark comparison demonstration', 'Persistence and linear benchmarks');

INSERT INTO parameter_estimates (
  run_id,
  parameter,
  estimated_value,
  lower_bound,
  upper_bound,
  calibration_method
) VALUES
(1, 'growth_rate', 0.095, 0.040, 0.200, 'grid_search'),
(1, 'carrying_capacity', 120.0, 70.0, 180.0, 'grid_search');

INSERT INTO validation_metrics (
  run_id,
  dataset,
  metric_name,
  metric_value
) VALUES
(1, 'calibration', 'illustrative_rmse', 0.91),
(1, 'calibration', 'illustrative_mae', 0.72),
(2, 'validation', 'illustrative_rmse', 1.08),
(2, 'validation', 'illustrative_mae', 0.86),
(2, 'validation', 'illustrative_generalization_gap', 0.17);

INSERT INTO benchmark_metrics (
  benchmark_name,
  validation_rmse,
  validation_mae,
  validation_bias
) VALUES
('calibrated_logistic', 1.08, 0.86, 0.04),
('persistence', 5.75, 5.02, 4.80),
('linear_trend', 2.94, 2.25, 1.77);

CREATE VIEW v_calibration_settings AS
SELECT
  setting,
  value,
  units,
  description
FROM calibration_settings
ORDER BY setting;

CREATE VIEW v_structural_validation_checks AS
SELECT
  check_id,
  check_name,
  validation_type,
  question,
  evidence_required
FROM structural_validation_checks
ORDER BY check_id;

CREATE VIEW v_validation_metric_summary AS
SELECT
  r.run_type,
  m.dataset,
  m.metric_name,
  ROUND(MIN(m.metric_value), 3) AS minimum_value,
  ROUND(AVG(m.metric_value), 3) AS average_value,
  ROUND(MAX(m.metric_value), 3) AS maximum_value
FROM validation_metrics m
JOIN model_runs r
  ON m.run_id = r.run_id
GROUP BY r.run_type, m.dataset, m.metric_name;

CREATE VIEW v_benchmark_comparison AS
SELECT
  benchmark_name,
  validation_rmse,
  validation_mae,
  validation_bias
FROM benchmark_metrics
ORDER BY validation_rmse ASC;

.headers on
.mode column

SELECT * FROM v_calibration_settings;
SELECT * FROM v_structural_validation_checks;
SELECT * FROM v_validation_metric_summary;
SELECT * FROM v_benchmark_comparison;
