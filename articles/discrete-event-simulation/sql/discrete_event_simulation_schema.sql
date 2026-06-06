-- discrete_event_simulation_schema.sql
-- SQLite schema and analysis queries for DES workflows.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS model_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS process_routes;
DROP TABLE IF EXISTS resources;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE process_routes (
  step_id INTEGER PRIMARY KEY,
  process_step TEXT NOT NULL,
  event_start TEXT NOT NULL,
  event_end TEXT NOT NULL,
  required_resource TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  performance_metric TEXT NOT NULL
);

CREATE TABLE resources (
  resource_id TEXT PRIMARY KEY,
  resource_name TEXT NOT NULL,
  capacity INTEGER NOT NULL,
  shift_start REAL NOT NULL,
  shift_end REAL NOT NULL,
  notes TEXT
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
  time_step REAL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT INTO process_routes (
  step_id,
  process_step,
  event_start,
  event_end,
  required_resource,
  queue_name,
  performance_metric
) VALUES
(1, 'arrival_to_triage', 'arrival', 'triage_start', 'triage_staff', 'triage_queue', 'triage_wait'),
(2, 'triage_to_service', 'triage_complete', 'service_start', 'service_staff', 'service_queue', 'service_wait'),
(3, 'service_to_departure', 'service_start', 'service_complete', 'service_staff', 'none', 'time_in_service'),
(4, 'repair_cycle', 'failure', 'repair_complete', 'repair_crew', 'repair_backlog', 'downtime'),
(5, 'loading_cycle', 'truck_arrival', 'loading_complete', 'dock', 'loading_queue', 'dock_turnaround');

INSERT INTO resources (
  resource_id,
  resource_name,
  capacity,
  shift_start,
  shift_end,
  notes
) VALUES
('R1', 'single_server', 1, 0, 600, 'Baseline single-server queue'),
('R2', 'pooled_service_staff', 2, 0, 600, 'Two-server pooled capacity scenario'),
('R3', 'triage_staff', 1, 0, 600, 'Illustrative first-stage resource'),
('R4', 'repair_crew', 1, 0, 600, 'Illustrative maintenance resource'),
('R5', 'loading_dock', 2, 0, 600, 'Illustrative logistics resource');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'discrete-event-simulation', 'event_calendar_queue', 'baseline_single_server', 'workflow demonstration', 'Reference DES queue'),
(2, 'discrete-event-simulation', 'event_calendar_queue', 'higher_arrival_pressure', 'stress test', 'Higher arrival pressure'),
(3, 'discrete-event-simulation', 'event_calendar_queue', 'two_servers', 'capacity test', 'Two-server pooled capacity'),
(4, 'discrete-event-simulation', 'event_calendar_queue', 'faster_service', 'service-rate test', 'Faster service rate');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units
) VALUES
(1, 'arrival_rate', 0.18, 'entities per time unit'),
(1, 'service_rate', 0.22, 'entities per time unit'),
(1, 'servers', 1, 'resources'),
(2, 'arrival_rate', 0.21, 'entities per time unit'),
(2, 'service_rate', 0.22, 'entities per time unit'),
(2, 'servers', 1, 'resources'),
(3, 'arrival_rate', 0.30, 'entities per time unit'),
(3, 'service_rate', 0.22, 'entities per time unit'),
(3, 'servers', 2, 'resources'),
(4, 'arrival_rate', 0.18, 'entities per time unit'),
(4, 'service_rate', 0.30, 'entities per time unit'),
(4, 'servers', 1, 'resources');

INSERT INTO model_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 600, 'illustrative_average_waiting_time', 14.2),
(1, 600, 'illustrative_utilization', 0.82),
(2, 600, 'illustrative_average_waiting_time', 28.7),
(2, 600, 'illustrative_utilization', 0.95),
(3, 600, 'illustrative_average_waiting_time', 6.1),
(3, 600, 'illustrative_utilization', 0.70),
(4, 600, 'illustrative_average_waiting_time', 5.5),
(4, 600, 'illustrative_utilization', 0.60);

CREATE VIEW v_process_route_inventory AS
SELECT
  step_id,
  process_step,
  event_start,
  event_end,
  required_resource,
  queue_name,
  performance_metric
FROM process_routes
ORDER BY step_id;

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

SELECT * FROM v_process_route_inventory;
SELECT * FROM v_scenario_parameter_inventory;
SELECT * FROM v_output_metric_summary;
