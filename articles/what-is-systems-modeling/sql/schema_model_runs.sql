-- schema_model_runs.sql
-- SQLite-compatible schema for systems modeling runs.

CREATE TABLE IF NOT EXISTS model_runs (
  run_id INTEGER PRIMARY KEY,
  article_slug TEXT NOT NULL,
  model_name TEXT NOT NULL,
  scenario_name TEXT NOT NULL,
  run_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  random_seed INTEGER,
  purpose TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS scenario_parameters (
  parameter_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  parameter_name TEXT NOT NULL,
  parameter_value REAL NOT NULL,
  parameter_units TEXT,
  parameter_source TEXT,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT OR IGNORE INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  random_seed,
  purpose,
  notes
) VALUES
(1, 'what-is-systems-modeling', 'network_shock_propagation', 'baseline', 42, 'workflow demonstration', 'Synthetic baseline network shock scenario'),
(2, 'what-is-systems-modeling', 'network_shock_propagation', 'high_coupling', 42, 'stress test', 'Synthetic scenario with stronger dependencies'),
(3, 'what-is-systems-modeling', 'stock_flow_monte_carlo', 'uncertainty_ensemble', 2026, 'sensitivity analysis', 'Synthetic stock-flow Monte Carlo ensemble');
