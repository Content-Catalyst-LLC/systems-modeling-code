-- phase_transitions_schema.sql
-- SQLite schema and analysis queries for phase transitions in complex systems.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_phase_transition_concepts;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_domain_phase_transition_examples;
DROP VIEW IF EXISTS v_modeling_strategies;
DROP VIEW IF EXISTS v_phase_transition_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS phase_transition_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS modeling_strategies;
DROP TABLE IF EXISTS domain_phase_transition_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS phase_transition_concepts;

CREATE TABLE phase_transition_concepts (
  concept TEXT PRIMARY KEY,
  system_meaning TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  node_count INTEGER NOT NULL,
  probability_start REAL NOT NULL,
  probability_end REAL NOT NULL,
  probability_steps INTEGER NOT NULL,
  seed INTEGER NOT NULL,
  giant_component_threshold REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE domain_phase_transition_examples (
  domain TEXT PRIMARY KEY,
  control_parameter TEXT NOT NULL,
  order_parameter TEXT NOT NULL,
  phase_a TEXT NOT NULL,
  phase_b TEXT NOT NULL,
  modeling_concern TEXT NOT NULL
);

CREATE TABLE modeling_strategies (
  strategy TEXT PRIMARY KEY,
  best_suited_for TEXT NOT NULL,
  key_diagnostic TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE phase_transition_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO phase_transition_concepts (
  concept,
  system_meaning,
  modeling_representation,
  diagnostic_question
) VALUES
('phase', 'macroscopic system regime or collective state', 'state label or regime class', 'Which large-scale state describes the system'),
('order_parameter', 'variable summarizing collective organization', 'system-level state metric', 'Which variable reveals the macroscopic transition'),
('control_parameter', 'variable that drives the transition', 'parameter sweep or forcing variable', 'What pressure changes the stability of the system'),
('critical_point', 'threshold region where qualitative behavior changes', 'critical parameter value or range', 'Where does the system reorganize'),
('criticality', 'behavior near a critical point', 'sensitivity fluctuation and correlation diagnostics', 'Is the system near a region of heightened sensitivity'),
('bifurcation', 'qualitative change in equilibrium structure', 'equilibrium branch analysis', 'Do stable states appear disappear or change stability'),
('percolation', 'connectivity transition in networks', 'largest component and average degree', 'Does local connectivity become system-wide reachability'),
('giant_component', 'large connected cluster in a network', 'largest connected component fraction', 'When does system-wide connectivity emerge'),
('hysteresis', 'different forward and recovery paths', 'separate collapse and recovery thresholds', 'Does reversal require stronger action than prevention'),
('universality', 'shared transition patterns across different systems', 'comparison of transition structure', 'Do different systems share similar critical behavior');

INSERT INTO scenario_definitions (
  scenario,
  node_count,
  probability_start,
  probability_end,
  probability_steps,
  seed,
  giant_component_threshold,
  description
) VALUES
('small_network', 60, 0.000, 0.100, 45, 42, 0.50, 'Small random network connectivity transition'),
('medium_network', 120, 0.000, 0.080, 45, 84, 0.50, 'Medium random network connectivity transition'),
('larger_network', 240, 0.000, 0.050, 45, 126, 0.50, 'Larger random network connectivity transition'),
('high_resolution_medium', 120, 0.000, 0.080, 80, 168, 0.50, 'Medium network with finer probability sweep'),
('low_connectivity_scan', 120, 0.000, 0.030, 45, 210, 0.50, 'Scan that may remain below giant component region'),
('fragmentation_test', 160, 0.080, 0.000, 45, 252, 0.50, 'Reverse connectivity scan as fragmentation analogue'),
('dense_scan', 120, 0.000, 0.120, 60, 294, 0.50, 'Dense scan beyond the expected connectivity transition'),
('threshold_sensitive', 100, 0.000, 0.070, 70, 336, 0.40, 'Alternative threshold definition for earlier detection');

INSERT INTO domain_phase_transition_examples (
  domain,
  control_parameter,
  order_parameter,
  phase_a,
  phase_b,
  modeling_concern
) VALUES
('physical_system', 'temperature_or_pressure', 'density_or_magnetization', 'disordered_or_fluid_state', 'ordered_or_solid_state', 'critical_point_and_scaling_behavior'),
('ecology', 'nutrient_loading_or_drought_pressure', 'vegetation_cover_or_water_clarity', 'regenerative_ecological_regime', 'degraded_ecological_regime', 'hysteresis_and_recovery_thresholds'),
('climate', 'warming_or_freshwater_forcing', 'ice_volume_or_circulation_strength', 'current_component_state', 'alternative_component_state', 'long_time_horizons_and_threshold_uncertainty'),
('infrastructure', 'load_or_redundancy_loss', 'functioning_service_fraction', 'stable_service_regime', 'cascading_failure_regime', 'capacity_thresholds_and_network_dependency'),
('finance', 'leverage_liquidity_or_confidence', 'liquidity_or_withdrawal_share', 'orderly_market_regime', 'panic_or_contagion_regime', 'expectation_feedback_and_counterparty_exposure'),
('technology_adoption', 'network_effect_strength_or_cost', 'adoption_share', 'niche_use', 'dominant_standard', 'lock_in_and_switching_costs'),
('public_institutions', 'trust_legitimacy_or_service_failure', 'cooperation_share', 'compliance_and_legitimacy', 'noncompliance_and_resistance', 'social_thresholds_and_power_relations'),
('organizations', 'workload_turnover_or_capability_loss', 'functioning_capacity', 'learning_organization', 'burnout_and_defensive_routines', 'slow_capacity_erosion_and_measurement_validity');

INSERT INTO modeling_strategies (
  strategy,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('bifurcation_model', 'continuous state systems with changing stability', 'equilibrium branches and stability', 'do not infer exact thresholds without evidence'),
('percolation_model', 'connectivity accessibility and fragmentation', 'largest connected component fraction', 'topology alone may not capture behavior'),
('network_cascade_model', 'infrastructure finance and supply chains', 'failed-node fraction or cascade size', 'capacity and repair rules strongly affect results'),
('agent_based_threshold_model', 'adoption norms and social contagion', 'adoption fraction and threshold distribution', 'include heterogeneity and social context'),
('system_dynamics_model', 'feedback delays stocks and hysteresis', 'regime state and recovery path', 'parameter uncertainty can dominate conclusions'),
('scenario_ensemble', 'uncertain thresholds and contested futures', 'transition frequency across assumptions', 'scenario selection can bias interpretation');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('largest_component_fraction', 0, 1, 'Largest connected component fraction should remain between zero and one'),
('component_count', 0, 1000000, 'Component count should remain nonnegative'),
('edge_count', 0, 1000000, 'Edge count should remain nonnegative'),
('average_degree', 0, 1000000, 'Average degree should remain nonnegative'),
('order_parameter_magnitude', 0, 1000000, 'Order parameter magnitude should remain nonnegative'),
('control_parameter', -1000000, 1000000, 'Control parameter should remain finite'),
('giant_component_probability', 0, 1, 'Approximate giant component probability should be bounded when detected'),
('critical_threshold', -1000000, 1000000, 'Critical threshold should remain finite');

INSERT INTO phase_transition_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('small_network', 'illustrative_node_count', 60, 'Small network scan tests finite-size connectivity behavior'),
('medium_network', 'illustrative_node_count', 120, 'Medium network scan tests giant component emergence'),
('larger_network', 'illustrative_node_count', 240, 'Larger network scan tests connectivity threshold behavior'),
('high_resolution_medium', 'illustrative_probability_steps', 80, 'Finer scan improves transition-region resolution'),
('low_connectivity_scan', 'illustrative_probability_end', 0.030, 'Low connectivity scan may remain below giant component region'),
('fragmentation_test', 'illustrative_reverse_scan', 1, 'Reverse scan analogizes fragmentation under link loss'),
('dense_scan', 'illustrative_probability_end', 0.120, 'Dense scan extends beyond expected transition region'),
('threshold_sensitive', 'illustrative_giant_component_threshold', 0.400, 'Alternative threshold detects earlier large-component emergence');

CREATE VIEW v_phase_transition_concepts AS
SELECT
  concept,
  system_meaning,
  modeling_representation,
  diagnostic_question
FROM phase_transition_concepts
ORDER BY concept;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  node_count,
  probability_start,
  probability_end,
  probability_steps,
  seed,
  giant_component_threshold,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_domain_phase_transition_examples AS
SELECT
  domain,
  control_parameter,
  order_parameter,
  phase_a,
  phase_b,
  modeling_concern
FROM domain_phase_transition_examples
ORDER BY domain;

CREATE VIEW v_modeling_strategies AS
SELECT
  strategy,
  best_suited_for,
  key_diagnostic,
  professional_caution
FROM modeling_strategies
ORDER BY strategy;

CREATE VIEW v_phase_transition_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM phase_transition_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

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

SELECT * FROM v_phase_transition_concepts;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_domain_phase_transition_examples;
SELECT * FROM v_modeling_strategies;
SELECT * FROM v_phase_transition_metric_summary;
SELECT * FROM v_validation_targets;
