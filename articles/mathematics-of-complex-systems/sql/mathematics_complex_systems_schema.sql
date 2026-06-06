-- mathematics_complex_systems_schema.sql
-- SQLite schema and analysis queries for mathematics of complex systems.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_mathematical_frameworks;
DROP VIEW IF EXISTS v_network_summary;
DROP VIEW IF EXISTS v_complexity_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS complexity_metrics;
DROP TABLE IF EXISTS network_edges;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS nonlinear_parameters;
DROP TABLE IF EXISTS mathematical_frameworks;

CREATE TABLE mathematical_frameworks (
  framework TEXT PRIMARY KEY,
  primary_question TEXT NOT NULL,
  formal_objects TEXT NOT NULL,
  systems_modeling_use TEXT NOT NULL
);

CREATE TABLE nonlinear_parameters (
  parameter TEXT PRIMARY KEY,
  value REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE network_edges (
  edge_id INTEGER PRIMARY KEY,
  source TEXT NOT NULL,
  target TEXT NOT NULL,
  edge_type TEXT NOT NULL,
  weight REAL NOT NULL
);

CREATE TABLE complexity_metrics (
  metric_id INTEGER PRIMARY KEY,
  model_component TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO mathematical_frameworks (
  framework,
  primary_question,
  formal_objects,
  systems_modeling_use
) VALUES
('dynamical_systems', 'How does state evolve through time?', 'state vectors differential equations difference equations', 'Equilibria attractors trajectories stability and transition analysis'),
('nonlinear_dynamics', 'How do disproportionate responses emerge?', 'nonlinear functions bifurcation maps recurrence relations', 'Thresholds tipping points saturation chaos and path dependence'),
('network_science', 'How does structure shape flow and failure?', 'graphs adjacency matrices Laplacians centrality measures', 'Diffusion contagion dependency robustness and cascading failure'),
('stochastic_processes', 'How does uncertainty affect trajectories?', 'random variables distributions Markov chains Monte Carlo', 'Shocks variability uncertainty propagation and risk analysis'),
('information_theory', 'How much uncertainty or structure exists?', 'entropy mutual information signal redundancy', 'State diversity predictability monitoring and signal interpretation'),
('statistical_mechanics', 'How do micro interactions create macro patterns?', 'ensembles distributions phase transitions scaling', 'Emergence collective behavior scaling and criticality'),
('optimization_control', 'Which interventions perform under constraints?', 'objective functions constraints feedback rules', 'Policy design control adaptive response and robustness'),
('computational_simulation', 'What behavior emerges under rules?', 'algorithms agents iterations numerical experiments', 'Scenario exploration model comparison and stress testing');

INSERT INTO nonlinear_parameters (
  parameter,
  value,
  description
) VALUES
('logistic_map_r', 3.9, 'Chaotic logistic map parameter used for sensitivity demonstration'),
('initial_state_1', 0.4000, 'First initial condition'),
('initial_state_2', 0.4001, 'Second initial condition for sensitivity test'),
('divergence_threshold', 0.10, 'Absolute trajectory difference used as divergence marker'),
('diffusion_alpha', 0.18, 'Network diffusion coefficient'),
('shock_sigma', 0.035, 'Standard deviation of stochastic node shocks');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('logistic_state', 0, 1, 'Logistic-map states should remain bounded for r in tested range'),
('absolute_difference', 0, 1, 'Trajectory difference should remain bounded'),
('entropy', 0, 10, 'Discrete entropy diagnostic should remain finite'),
('degree', 0, 100, 'Network degree should remain plausible'),
('network_mean_state', -100, 100, 'Network mean state should remain finite'),
('network_state_sd', 0, 100, 'Network state dispersion should remain nonnegative and finite');

INSERT INTO network_edges (
  source,
  target,
  edge_type,
  weight
) VALUES
('N01', 'N02', 'dependency', 1.0),
('N01', 'N03', 'dependency', 0.9),
('N02', 'N04', 'dependency', 0.8),
('N03', 'N04', 'dependency', 1.1),
('N04', 'N05', 'dependency', 1.0),
('N05', 'N06', 'dependency', 0.7),
('N06', 'N07', 'dependency', 0.9),
('N07', 'N08', 'dependency', 0.8),
('N08', 'N09', 'dependency', 1.2),
('N09', 'N10', 'dependency', 0.9),
('N10', 'N11', 'dependency', 1.0),
('N11', 'N12', 'dependency', 0.8),
('N12', 'N13', 'dependency', 0.7),
('N13', 'N14', 'dependency', 0.9),
('N14', 'N15', 'dependency', 1.0),
('N03', 'N08', 'cross_link', 0.6),
('N05', 'N11', 'cross_link', 0.7),
('N02', 'N12', 'cross_link', 0.5),
('N06', 'N14', 'cross_link', 0.6),
('N09', 'N15', 'cross_link', 0.8);

INSERT INTO complexity_metrics (
  model_component,
  metric_name,
  metric_value,
  interpretation
) VALUES
('logistic_map', 'illustrative_maximum_absolute_difference', 0.92, 'Divergence between similar initial conditions'),
('logistic_map', 'illustrative_entropy', 2.07, 'Binned trajectory entropy'),
('network', 'node_count', 15, 'Number of system components'),
('network', 'edge_count', 20, 'Number of undirected dependencies'),
('network', 'mean_degree', 2.667, 'Average local connectivity'),
('network_diffusion', 'illustrative_final_state_dispersion', 0.12, 'Dispersion after diffusion and shocks');

CREATE VIEW v_mathematical_frameworks AS
SELECT
  framework,
  primary_question,
  formal_objects,
  systems_modeling_use
FROM mathematical_frameworks
ORDER BY framework;

CREATE VIEW v_network_summary AS
SELECT
  edge_type,
  COUNT(*) AS edge_count,
  ROUND(AVG(weight), 3) AS average_weight,
  ROUND(MIN(weight), 3) AS minimum_weight,
  ROUND(MAX(weight), 3) AS maximum_weight
FROM network_edges
GROUP BY edge_type
ORDER BY edge_type;

CREATE VIEW v_complexity_metric_summary AS
SELECT
  model_component,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM complexity_metrics
GROUP BY model_component, metric_name
ORDER BY model_component, metric_name;

CREATE VIEW v_validation_targets AS
SELECT
  metric,
  target_low,
  target_high,
  notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_mathematical_frameworks;
SELECT * FROM v_network_summary;
SELECT * FROM v_complexity_metric_summary;
SELECT * FROM v_validation_targets;
