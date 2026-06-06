-- sensitivity_analysis_schema.sql
-- SQLite schema and analysis queries for sensitivity analysis workflows.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_parameter_ranges;
DROP VIEW IF EXISTS v_structural_variants;
DROP VIEW IF EXISTS v_output_metric_summary;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS model_runs;
DROP TABLE IF EXISTS structural_variants;
DROP TABLE IF EXISTS parameter_ranges;

CREATE TABLE parameter_ranges (
  parameter TEXT PRIMARY KEY,
  minimum REAL NOT NULL,
  baseline REAL NOT NULL,
  maximum REAL NOT NULL,
  units TEXT NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE structural_variants (
  variant_id TEXT PRIMARY KEY,
  variant_name TEXT NOT NULL,
  structural_change TEXT NOT NULL,
  expected_effect TEXT NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE model_runs (
  run_id INTEGER PRIMARY KEY,
  article_slug TEXT NOT NULL,
  model_name TEXT NOT NULL,
  analysis_type TEXT NOT NULL,
  run_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  purpose TEXT NOT NULL,
  notes TEXT
);

CREATE TABLE model_outputs (
  output_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT INTO parameter_ranges (
  parameter,
  minimum,
  baseline,
  maximum,
  units,
  description
) VALUES
('growth_rate', 0.04, 0.08, 0.12, 'per_time_step', 'Intrinsic growth or accumulation pressure'),
('carrying_capacity', 60, 100, 140, 'state_units', 'Upper system capacity or saturation level'),
('extraction_pressure', 0.005, 0.025, 0.060, 'share_per_time_step', 'Removal pressure or service demand load'),
('recovery_delay', 1, 5, 12, 'time_steps', 'Delay before recovery feedback affects the state'),
('feedback_strength', 0.005, 0.020, 0.050, 'share_per_time_step', 'Strength of delayed recovery feedback'),
('shock_intensity', 0, 8, 24, 'state_units', 'External shock imposed during sensitivity runs');

INSERT INTO structural_variants (
  variant_id,
  variant_name,
  structural_change,
  expected_effect,
  notes
) VALUES
('V1', 'baseline_logistic_delay', 'logistic growth with delayed recovery feedback', 'reference behavior', 'Default nonlinear recurrence'),
('V2', 'no_recovery_feedback', 'feedback_strength set to zero', 'lower recovery and more depletion', 'Tests omitted feedback'),
('V3', 'strong_recovery_feedback', 'feedback_strength doubled', 'higher recovery and possible overshoot', 'Tests feedback strength'),
('V4', 'no_capacity_limit', 'carrying capacity term removed', 'unbounded growth risk', 'Tests saturation structure'),
('V5', 'shock_added', 'external shock introduced at midpoint', 'tests disturbance sensitivity', 'Stress-style variant');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  analysis_type,
  purpose,
  notes
) VALUES
(1, 'sensitivity-analysis-in-systems-models', 'nonlinear_growth_delay', 'local_one_at_a_time', 'local sensitivity demonstration', 'One parameter varies around baseline'),
(2, 'sensitivity-analysis-in-systems-models', 'nonlinear_growth_delay', 'monte_carlo_global', 'global sensitivity demonstration', 'Random sampling across ranges'),
(3, 'sensitivity-analysis-in-systems-models', 'nonlinear_growth_delay', 'latin_hypercube_style', 'stratified sampling demonstration', 'Dependency-light stratified design'),
(4, 'sensitivity-analysis-in-systems-models', 'nonlinear_growth_delay', 'structural_variant', 'structural sensitivity demonstration', 'Model-form comparison placeholder');

INSERT INTO model_outputs (
  run_id,
  metric_name,
  metric_value
) VALUES
(1, 'illustrative_growth_elasticity', 0.62),
(1, 'illustrative_extraction_elasticity', -0.48),
(2, 'illustrative_top_rank_absolute_correlation', 0.79),
(2, 'illustrative_final_state_p90', 121.5),
(3, 'illustrative_stratified_final_state_mean', 84.2),
(4, 'illustrative_structural_difference', 18.4);

CREATE VIEW v_parameter_ranges AS
SELECT
  parameter,
  minimum,
  baseline,
  maximum,
  units,
  description
FROM parameter_ranges
ORDER BY parameter;

CREATE VIEW v_structural_variants AS
SELECT
  variant_id,
  variant_name,
  structural_change,
  expected_effect,
  notes
FROM structural_variants
ORDER BY variant_id;

CREATE VIEW v_output_metric_summary AS
SELECT
  r.analysis_type,
  o.metric_name,
  COUNT(*) AS observation_count,
  ROUND(MIN(o.metric_value), 3) AS minimum_value,
  ROUND(AVG(o.metric_value), 3) AS average_value,
  ROUND(MAX(o.metric_value), 3) AS maximum_value
FROM model_outputs o
JOIN model_runs r
  ON o.run_id = r.run_id
GROUP BY r.analysis_type, o.metric_name;

.headers on
.mode column

SELECT * FROM v_parameter_ranges;
SELECT * FROM v_structural_variants;
SELECT * FROM v_output_metric_summary;
