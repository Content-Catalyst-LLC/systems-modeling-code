-- schema_model_outputs.sql
-- SQLite-compatible output tables for systems modeling diagnostics.

CREATE TABLE IF NOT EXISTS model_outputs (
  output_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  time_step INTEGER,
  entity_name TEXT,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

CREATE TABLE IF NOT EXISTS validation_diagnostics (
  diagnostic_id INTEGER PRIMARY KEY,
  run_id INTEGER,
  metric_name TEXT NOT NULL,
  observed_value REAL,
  target_low REAL,
  target_high REAL,
  passed INTEGER,
  notes TEXT,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT OR IGNORE INTO model_outputs (
  output_id,
  run_id,
  time_step,
  entity_name,
  metric_name,
  metric_value
) VALUES
(1, 1, 42, 'system', 'shock_time', 42),
(2, 1, 140, 'system', 'illustrative_final_performance', 0.94),
(3, 2, 140, 'system', 'illustrative_final_performance', 0.88),
(4, 3, 180, 'ensemble', 'illustrative_median_recovery_ratio', 1.07);
