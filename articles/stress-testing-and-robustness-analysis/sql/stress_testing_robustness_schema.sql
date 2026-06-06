-- stress_testing_robustness_schema.sql
-- SQLite schema and analysis queries for stress testing and robustness analysis.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_stress_scenarios;
DROP VIEW IF EXISTS v_strategy_options;
DROP VIEW IF EXISTS v_thresholds;
DROP VIEW IF EXISTS v_stress_metric_summary;
DROP VIEW IF EXISTS v_robustness_ranking;

DROP TABLE IF EXISTS robustness_outputs;
DROP TABLE IF EXISTS stress_metrics;
DROP TABLE IF EXISTS model_runs;
DROP TABLE IF EXISTS failure_thresholds;
DROP TABLE IF EXISTS strategy_options;
DROP TABLE IF EXISTS stress_scenarios;

CREATE TABLE stress_scenarios (
  scenario_name TEXT PRIMARY KEY,
  demand_growth REAL NOT NULL,
  initial_capacity REAL NOT NULL,
  capacity_loss REAL NOT NULL,
  recovery_rate REAL NOT NULL,
  shock_time INTEGER NOT NULL,
  stress_duration INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE strategy_options (
  strategy TEXT PRIMARY KEY,
  redundancy REAL NOT NULL,
  adaptive_response REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE failure_thresholds (
  threshold_id TEXT PRIMARY KEY,
  metric TEXT NOT NULL,
  threshold_value REAL NOT NULL,
  direction TEXT NOT NULL,
  interpretation TEXT NOT NULL
);

CREATE TABLE model_runs (
  run_id INTEGER PRIMARY KEY,
  article_slug TEXT NOT NULL,
  run_type TEXT NOT NULL,
  run_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  purpose TEXT NOT NULL,
  notes TEXT
);

CREATE TABLE stress_metrics (
  metric_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  scenario_name TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE robustness_outputs (
  output_id INTEGER PRIMARY KEY,
  strategy TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL
);

INSERT INTO stress_scenarios (
  scenario_name,
  demand_growth,
  initial_capacity,
  capacity_loss,
  recovery_rate,
  shock_time,
  stress_duration,
  description
) VALUES
('baseline', 0.010, 100, 0, 0.18, 40, 1, 'Ordinary baseline without meaningful capacity loss'),
('moderate_capacity_loss', 0.012, 100, 18, 0.16, 35, 8, 'Moderate disruption with recovery'),
('severe_capacity_loss', 0.014, 100, 35, 0.14, 35, 10, 'Severe capacity loss and longer stress period'),
('compound_high_demand_capacity_loss', 0.025, 100, 35, 0.12, 32, 14, 'Compound demand surge and capacity loss'),
('delayed_recovery', 0.018, 100, 30, 0.04, 32, 18, 'Stress case with slow recovery and persistent drag');

INSERT INTO strategy_options (
  strategy,
  redundancy,
  adaptive_response,
  description
) VALUES
('Strategy_A_efficiency', 0.02, 0.02, 'Lean efficiency-oriented strategy with low redundancy'),
('Strategy_B_balanced_resilience', 0.12, 0.06, 'Balanced redundancy and adaptive response'),
('Strategy_C_high_redundancy', 0.25, 0.03, 'High backup capacity with weaker adaptive response'),
('Strategy_D_adaptive_pathway', 0.08, 0.11, 'Adaptive strategy with trigger-ready response capacity');

INSERT INTO failure_thresholds (
  threshold_id,
  metric,
  threshold_value,
  direction,
  interpretation
) VALUES
('T1', 'minimum_service_ratio', 0.85, 'below_is_failure', 'Service below 85 percent is unacceptable'),
('T2', 'p05_minimum_service_ratio', 0.80, 'below_is_failure', 'Lower-tail service below 80 percent indicates severe fragility'),
('T3', 'failure_share', 0.15, 'above_is_failure', 'More than 15 percent failed futures indicates poor robustness'),
('T4', 'maximum_regret', 35.0, 'above_is_failure', 'High maximum regret indicates decision fragility');

INSERT INTO model_runs (
  run_id,
  article_slug,
  run_type,
  purpose,
  notes
) VALUES
(1, 'stress-testing-and-robustness-analysis', 'stress_scenario_analysis', 'evaluate dynamic capacity under stress', 'Synthetic illustrative stress scenarios'),
(2, 'stress-testing-and-robustness-analysis', 'strategy_robustness_analysis', 'compare strategies under stress futures', 'Synthetic robustness and regret analysis');

INSERT INTO stress_metrics (
  run_id,
  scenario_name,
  metric_name,
  metric_value
) VALUES
(1, 'baseline', 'illustrative_minimum_service_ratio', 0.96),
(1, 'moderate_capacity_loss', 'illustrative_minimum_service_ratio', 0.88),
(1, 'severe_capacity_loss', 'illustrative_minimum_service_ratio', 0.72),
(1, 'compound_high_demand_capacity_loss', 'illustrative_minimum_service_ratio', 0.58),
(1, 'delayed_recovery', 'illustrative_minimum_service_ratio', 0.64),
(1, 'baseline', 'illustrative_failure_frequency', 0.00),
(1, 'moderate_capacity_loss', 'illustrative_failure_frequency', 0.05),
(1, 'severe_capacity_loss', 'illustrative_failure_frequency', 0.24),
(1, 'compound_high_demand_capacity_loss', 'illustrative_failure_frequency', 0.41),
(1, 'delayed_recovery', 'illustrative_failure_frequency', 0.36);

INSERT INTO robustness_outputs (
  strategy,
  metric_name,
  metric_value
) VALUES
('Strategy_A_efficiency', 'illustrative_mean_regret', 18.5),
('Strategy_B_balanced_resilience', 'illustrative_mean_regret', 5.8),
('Strategy_C_high_redundancy', 'illustrative_mean_regret', 9.4),
('Strategy_D_adaptive_pathway', 'illustrative_mean_regret', 4.2),
('Strategy_A_efficiency', 'illustrative_failure_share', 0.42),
('Strategy_B_balanced_resilience', 'illustrative_failure_share', 0.12),
('Strategy_C_high_redundancy', 'illustrative_failure_share', 0.10),
('Strategy_D_adaptive_pathway', 'illustrative_failure_share', 0.09);

CREATE VIEW v_stress_scenarios AS
SELECT
  scenario_name,
  demand_growth,
  initial_capacity,
  capacity_loss,
  recovery_rate,
  shock_time,
  stress_duration,
  description
FROM stress_scenarios
ORDER BY scenario_name;

CREATE VIEW v_strategy_options AS
SELECT
  strategy,
  redundancy,
  adaptive_response,
  description
FROM strategy_options
ORDER BY strategy;

CREATE VIEW v_thresholds AS
SELECT
  threshold_id,
  metric,
  threshold_value,
  direction,
  interpretation
FROM failure_thresholds
ORDER BY threshold_id;

CREATE VIEW v_stress_metric_summary AS
SELECT
  scenario_name,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM stress_metrics
GROUP BY scenario_name, metric_name
ORDER BY metric_name, average_value;

CREATE VIEW v_robustness_ranking AS
SELECT
  strategy,
  metric_name,
  ROUND(metric_value, 3) AS metric_value
FROM robustness_outputs
ORDER BY metric_name, metric_value;

.headers on
.mode column

SELECT * FROM v_stress_scenarios;
SELECT * FROM v_strategy_options;
SELECT * FROM v_thresholds;
SELECT * FROM v_stress_metric_summary;
SELECT * FROM v_robustness_ranking;
