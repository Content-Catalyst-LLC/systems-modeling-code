-- network_models_schema.sql
-- SQLite schema and analysis queries for network modeling workflows.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS network_outputs;
DROP TABLE IF EXISTS scenario_parameters;
DROP TABLE IF EXISTS edge_list;
DROP TABLE IF EXISTS node_attributes;
DROP TABLE IF EXISTS network_concepts;
DROP TABLE IF EXISTS model_runs;

CREATE TABLE network_concepts (
  concept_id INTEGER PRIMARY KEY,
  concept TEXT NOT NULL,
  modeling_question TEXT NOT NULL,
  formal_representation TEXT NOT NULL,
  diagnostic TEXT NOT NULL
);

CREATE TABLE node_attributes (
  node_id INTEGER PRIMARY KEY,
  node_label TEXT NOT NULL,
  layer TEXT NOT NULL,
  region TEXT NOT NULL,
  criticality TEXT NOT NULL
);

CREATE TABLE edge_list (
  edge_id INTEGER PRIMARY KEY,
  source INTEGER NOT NULL,
  target INTEGER NOT NULL,
  weight REAL NOT NULL,
  capacity REAL NOT NULL,
  edge_type TEXT NOT NULL
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

CREATE TABLE network_outputs (
  output_id INTEGER PRIMARY KEY,
  run_id INTEGER NOT NULL,
  time_step INTEGER,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  FOREIGN KEY (run_id) REFERENCES model_runs(run_id)
);

INSERT INTO network_concepts (
  concept,
  modeling_question,
  formal_representation,
  diagnostic
) VALUES
('node', 'what system components are represented', 'vertex set', 'node inventory'),
('edge', 'what relationships or dependencies matter', 'edge list or adjacency matrix', 'edge audit'),
('weight', 'how strong is a relationship', 'weighted edge value', 'weight distribution'),
('centrality', 'which nodes are structurally important', 'degree betweenness closeness eigenvector', 'centrality ranking'),
('diffusion', 'how states spread through ties', 'state update over edges', 'spread curve'),
('cascade', 'how failures propagate', 'threshold or overload rule', 'cascade size'),
('robustness', 'how structure survives disruption', 'node or edge removal test', 'largest component share');

INSERT INTO node_attributes (
  node_id,
  node_label,
  layer,
  region,
  criticality
) VALUES
(0, 'N0', 'infrastructure', 'north', 'high'),
(1, 'N1', 'infrastructure', 'north', 'medium'),
(2, 'N2', 'infrastructure', 'north', 'high'),
(3, 'N3', 'infrastructure', 'north', 'medium'),
(4, 'N4', 'infrastructure', 'north', 'low'),
(16, 'N16', 'logistics', 'central', 'medium'),
(18, 'N18', 'logistics', 'central', 'high'),
(19, 'N19', 'logistics', 'central', 'medium'),
(32, 'N32', 'digital', 'south', 'medium'),
(34, 'N34', 'digital', 'south', 'high'),
(35, 'N35', 'digital', 'south', 'medium');

INSERT INTO edge_list (
  source,
  target,
  weight,
  capacity,
  edge_type
) VALUES
(0, 1, 0.80, 12, 'local'),
(0, 2, 0.85, 15, 'local'),
(1, 3, 0.60, 10, 'local'),
(2, 3, 0.70, 12, 'local'),
(3, 19, 0.70, 10, 'bridge'),
(18, 19, 0.80, 14, 'local'),
(21, 35, 0.70, 10, 'bridge'),
(32, 34, 0.85, 15, 'local'),
(34, 35, 0.80, 14, 'local'),
(2, 18, 0.75, 11, 'cross_layer'),
(18, 34, 0.75, 11, 'cross_layer');

INSERT INTO model_runs (
  run_id,
  article_slug,
  model_name,
  scenario_name,
  purpose,
  notes
) VALUES
(1, 'network-models', 'synthetic_network_diagnostics', 'baseline_network', 'workflow demonstration', 'Reference network diagnostics'),
(2, 'network-models', 'network_contagion', 'baseline_contagion', 'contagion demonstration', 'Simple contagion over synthetic graph'),
(3, 'network-models', 'network_robustness', 'random_removal_10', 'robustness test', 'Random removal of ten percent of nodes'),
(4, 'network-models', 'network_robustness', 'targeted_removal_10', 'robustness test', 'High degree removal of ten percent of nodes');

INSERT INTO scenario_parameters (
  run_id,
  parameter_name,
  parameter_value,
  parameter_units
) VALUES
(1, 'node_count', 48, 'nodes'),
(1, 'edge_count', 56, 'edges'),
(2, 'contagion_probability', 0.18, 'probability'),
(3, 'removal_fraction', 0.10, 'share'),
(4, 'removal_fraction', 0.10, 'share');

INSERT INTO network_outputs (
  run_id,
  time_step,
  metric_name,
  metric_value
) VALUES
(1, 0, 'illustrative_density', 0.050),
(1, 0, 'illustrative_average_degree', 2.33),
(2, 24, 'illustrative_infected_share', 0.62),
(3, 0, 'illustrative_largest_component_share', 0.89),
(4, 0, 'illustrative_largest_component_share', 0.71);

CREATE VIEW v_network_concept_inventory AS
SELECT
  concept,
  modeling_question,
  formal_representation,
  diagnostic
FROM network_concepts
ORDER BY concept_id;

CREATE VIEW v_edge_type_summary AS
SELECT
  edge_type,
  COUNT(*) AS edge_count,
  ROUND(AVG(weight), 3) AS average_weight,
  ROUND(AVG(capacity), 3) AS average_capacity
FROM edge_list
GROUP BY edge_type;

CREATE VIEW v_output_metric_summary AS
SELECT
  r.scenario_name,
  o.metric_name,
  COUNT(*) AS observation_count,
  ROUND(MIN(o.metric_value), 3) AS minimum_value,
  ROUND(AVG(o.metric_value), 3) AS average_value,
  ROUND(MAX(o.metric_value), 3) AS maximum_value
FROM network_outputs o
JOIN model_runs r
  ON o.run_id = r.run_id
GROUP BY r.scenario_name, o.metric_name;

.headers on
.mode column

SELECT * FROM v_network_concept_inventory;
SELECT * FROM v_edge_type_summary;
SELECT * FROM v_output_metric_summary;
