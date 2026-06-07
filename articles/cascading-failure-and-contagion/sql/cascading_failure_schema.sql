DROP TABLE IF EXISTS cascade_nodes;
DROP TABLE IF EXISTS cascade_edges;
DROP TABLE IF EXISTS cascade_scenarios;

CREATE TABLE cascade_nodes (
  node_id INTEGER PRIMARY KEY,
  sector TEXT NOT NULL,
  capacity REAL NOT NULL,
  threshold REAL NOT NULL,
  recovery_rate REAL NOT NULL,
  criticality TEXT NOT NULL
);

CREATE TABLE cascade_edges (
  source_node INTEGER NOT NULL,
  target_node INTEGER NOT NULL,
  dependency_weight REAL NOT NULL,
  dependency_type TEXT NOT NULL,
  FOREIGN KEY (source_node) REFERENCES cascade_nodes(node_id),
  FOREIGN KEY (target_node) REFERENCES cascade_nodes(node_id)
);

CREATE TABLE cascade_scenarios (
  scenario TEXT NOT NULL,
  initiating_failure TEXT NOT NULL,
  threshold_multiplier REAL NOT NULL,
  recovery_multiplier REAL NOT NULL
);

INSERT INTO cascade_nodes VALUES
(1, 'energy', 100, 0.75, 0.08, 'high'),
(2, 'water', 85, 0.70, 0.07, 'high'),
(3, 'telecom', 90, 0.72, 0.06, 'high'),
(4, 'transport', 80, 0.68, 0.05, 'medium'),
(5, 'health', 95, 0.78, 0.04, 'high'),
(6, 'finance', 88, 0.73, 0.06, 'medium'),
(7, 'logistics', 76, 0.66, 0.05, 'medium'),
(8, 'public_services', 70, 0.64, 0.05, 'medium');

INSERT INTO cascade_edges VALUES
(1, 2, 0.62, 'physical'),
(1, 3, 0.58, 'physical'),
(3, 5, 0.55, 'digital'),
(4, 7, 0.50, 'transport'),
(7, 5, 0.46, 'supply'),
(6, 7, 0.38, 'financial'),
(2, 8, 0.42, 'physical'),
(3, 8, 0.35, 'digital');

INSERT INTO cascade_scenarios VALUES
('random_failure_baseline', 'random two-node failure', 1.00, 1.00),
('targeted_hub_failure', 'highest-dependency node failure', 1.00, 1.00),
('common_mode_failure', 'shared-vulnerability group failure', 1.00, 1.00),
('low_buffer_high_fragility', 'random failure with lower thresholds', 0.70, 0.60),
('resilience_intervention', 'hub failure with stronger buffers and recovery', 1.35, 1.50);

DROP VIEW IF EXISTS node_dependency_exposure;

CREATE VIEW node_dependency_exposure AS
SELECT
  n.node_id,
  n.sector,
  n.capacity,
  n.threshold,
  n.recovery_rate,
  n.criticality,
  COALESCE(SUM(e.dependency_weight), 0) AS incoming_dependency_weight,
  COUNT(e.source_node) AS incoming_dependency_count
FROM cascade_nodes n
LEFT JOIN cascade_edges e
  ON n.node_id = e.target_node
GROUP BY
  n.node_id,
  n.sector,
  n.capacity,
  n.threshold,
  n.recovery_rate,
  n.criticality;

DROP VIEW IF EXISTS high_exposure_nodes;

CREATE VIEW high_exposure_nodes AS
SELECT
  node_id,
  sector,
  criticality,
  incoming_dependency_count,
  ROUND(incoming_dependency_weight, 3) AS incoming_dependency_weight,
  CASE
    WHEN incoming_dependency_weight >= threshold THEN 'threshold_risk'
    WHEN incoming_dependency_weight >= threshold * 0.75 THEN 'watch'
    ELSE 'lower_exposure'
  END AS exposure_status
FROM node_dependency_exposure;

.headers on
.mode csv
.output ../outputs/tables/sql_high_exposure_nodes.csv
SELECT * FROM high_exposure_nodes ORDER BY incoming_dependency_weight DESC;
.output stdout
