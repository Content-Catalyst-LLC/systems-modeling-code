-- cascading_failure_contagion_schema.sql
-- SQLite schema and analysis queries for cascading failure and contagion.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_cascade_mechanisms;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_domain_cascade_examples;
DROP VIEW IF EXISTS v_containment_strategies;
DROP VIEW IF EXISTS v_cascade_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS cascade_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS containment_strategies;
DROP TABLE IF EXISTS domain_cascade_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS cascade_mechanisms;

CREATE TABLE cascade_mechanisms (
  mechanism TEXT PRIMARY KEY,
  system_meaning TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  node_count INTEGER NOT NULL,
  link_probability REAL NOT NULL,
  threshold REAL NOT NULL,
  seed_count INTEGER NOT NULL,
  max_steps INTEGER NOT NULL,
  seed INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE domain_cascade_examples (
  domain TEXT PRIMARY KEY,
  what_spreads TEXT NOT NULL,
  propagation_pathway TEXT NOT NULL,
  systemic_risk TEXT NOT NULL,
  modeling_concern TEXT NOT NULL
);

CREATE TABLE containment_strategies (
  strategy TEXT PRIMARY KEY,
  what_it_prevents TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  tradeoff TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE cascade_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO cascade_mechanisms (
  mechanism,
  system_meaning,
  modeling_representation,
  diagnostic_question
) VALUES
('load_redistribution', 'failed components shift load to remaining components', 'load-capacity network model', 'Where does load go after failure'),
('dependency_failure', 'components fail when required inputs or services are unavailable', 'directed dependency graph', 'Which upstream failures disable downstream function'),
('exposure_transmission', 'loss infection or stress moves through contact or exposure links', 'weighted exposure network', 'Which exposures transmit risk across the system'),
('threshold_contagion', 'nodes change state when affected-neighbor share exceeds tolerance', 'neighbor threshold rule', 'When does local exposure trigger state change'),
('behavioral_response', 'actors amplify disruption through panic withdrawal rerouting or noncompliance', 'agent rule or response function', 'How do decisions change propagation'),
('information_propagation', 'signals rumors warnings or narratives change expectations', 'communication diffusion network', 'How does information alter behavior and trust'),
('recovery_delay', 'slow repair allows disruption to spread before containment', 'response-time or repair-rate process', 'Can the system recover before spread accelerates'),
('common_exposure', 'many nodes are hit by the same external pressure', 'shared shock or factor exposure model', 'Is apparent contagion actually shared cause');

INSERT INTO scenario_definitions (
  scenario,
  node_count,
  link_probability,
  threshold,
  seed_count,
  max_steps,
  seed,
  description
) VALUES
('baseline_threshold', 90, 0.055, 0.25, 4, 40, 42, 'Moderate connectivity and threshold with targeted seed failures'),
('lower_threshold', 90, 0.055, 0.18, 4, 40, 43, 'Lower tolerance makes contagion easier'),
('higher_connectivity', 90, 0.075, 0.25, 4, 40, 44, 'More links create additional propagation pathways'),
('larger_initial_shock', 90, 0.055, 0.25, 8, 40, 45, 'Larger seed failure tests shock-size sensitivity'),
('high_threshold_containment', 90, 0.055, 0.35, 4, 40, 46, 'Higher threshold improves containment'),
('sparse_network', 90, 0.035, 0.25, 4, 40, 47, 'Sparser network reduces exposure pathways'),
('dense_low_threshold', 90, 0.085, 0.18, 5, 40, 48, 'Dense low-threshold case tests systemic cascade risk'),
('small_containment_test', 60, 0.050, 0.30, 3, 35, 49, 'Smaller network containment comparison');

INSERT INTO domain_cascade_examples (
  domain,
  what_spreads,
  propagation_pathway,
  systemic_risk,
  modeling_concern
) VALUES
('power_grid', 'load_and_outage_state', 'transmission_lines_and_protection_rules', 'cascading_blackout', 'load_redistribution_and_reserve_margin'),
('transportation', 'delay_and_congestion', 'roads_rails_ports_and_rerouting_paths', 'regional_gridlock_or_delivery_failure', 'capacity_bottlenecks_and_rerouting_behavior'),
('supply_chain', 'shortage_delay_and_backlog', 'supplier_customer_and_logistics_links', 'production_disruption_and_downstream_shortage', 'inventory_buffers_and_supplier_concentration'),
('finance', 'loss_liquidity_stress_and_confidence', 'counterparty_exposure_asset_overlap_and_funding_links', 'market_panic_or_institutional_default', 'common_exposure_versus_direct_contagion'),
('public_health', 'infection_demand_and_capacity_stress', 'contact_networks_facilities_staffing_and_supplies', 'disease_spread_and_health_system_overload', 'transmission_capacity_and_behavior_feedback'),
('ecology', 'species_loss_disturbance_or_habitat_change', 'food_web_mutualism_and_spatial_connections', 'trophic_cascade_or_regime_shift', 'indirect_effects_and_functional_redundancy'),
('digital_platforms', 'outage_latency_or_security_failure', 'service_dependencies_apis_and_data_centers', 'systemwide_platform_degradation', 'hidden_dependencies_and_failover_capacity'),
('public_institutions', 'trust_loss_noncompliance_and_legitimacy_decline', 'communication_networks_policy_response_and_service_outcomes', 'governance_failure_or_resistance', 'measurement_validity_and_power_relations');

INSERT INTO containment_strategies (
  strategy,
  what_it_prevents,
  modeling_representation,
  tradeoff
) VALUES
('redundancy', 'single_point_failure', 'alternate paths reserve capacity or substitute nodes', 'higher cost or apparent inefficiency'),
('modularity', 'systemwide_propagation', 'community boundaries or segmented subnetworks', 'less integration or slower coordination'),
('buffers', 'immediate_threshold_crossing', 'inventory slack capital reserve or spare capacity', 'carrying cost or lower efficiency'),
('firebreaks', 'transmission_across_critical_links', 'edge removal isolation quarantine or circuit breaker', 'temporary reduction in flow or access'),
('adaptive_rerouting', 'local_service_loss', 'path reassignment under capacity constraints', 'rerouting can overload substitutes'),
('rapid_recovery', 'long_propagation_window', 'repair rate response time and restoration capacity', 'requires sustained institutional capability'),
('monitoring', 'delayed_detection', 'early warning indicators and escalation triggers', 'false alarms and data burden'),
('targeted_hardening', 'hub_or_bridge_failure', 'protect high-centrality nodes and dependencies', 'may neglect peripheral vulnerability');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('affected_share', 0, 1, 'Affected share should remain between zero and one'),
('affected_count', 0, 1000000, 'Affected count should remain nonnegative'),
('new_failures', 0, 1000000, 'New failures should remain nonnegative'),
('cascade_duration', 0, 1000000, 'Cascade duration should remain nonnegative'),
('mean_degree', 0, 1000000, 'Mean degree should remain nonnegative'),
('maximum_degree', 0, 1000000, 'Maximum degree should remain nonnegative'),
('threshold', 0, 1, 'Threshold share should remain between zero and one'),
('link_probability', 0, 1, 'Link probability should remain between zero and one');

INSERT INTO cascade_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_threshold', 'illustrative_threshold', 0.25, 'Moderate threshold for baseline cascade behavior'),
('lower_threshold', 'illustrative_threshold', 0.18, 'Lower threshold increases susceptibility'),
('higher_connectivity', 'illustrative_link_probability', 0.075, 'Higher connectivity creates more propagation pathways'),
('larger_initial_shock', 'illustrative_seed_count', 8, 'Larger initial shock increases cascade pressure'),
('high_threshold_containment', 'illustrative_threshold', 0.35, 'Higher threshold improves containment'),
('sparse_network', 'illustrative_link_probability', 0.035, 'Sparse network limits exposure pathways'),
('dense_low_threshold', 'illustrative_link_probability', 0.085, 'Dense low-threshold case increases systemic cascade risk'),
('small_containment_test', 'illustrative_node_count', 60, 'Small network containment comparison');

CREATE VIEW v_cascade_mechanisms AS
SELECT
  mechanism,
  system_meaning,
  modeling_representation,
  diagnostic_question
FROM cascade_mechanisms
ORDER BY mechanism;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  node_count,
  link_probability,
  threshold,
  seed_count,
  max_steps,
  seed,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_domain_cascade_examples AS
SELECT
  domain,
  what_spreads,
  propagation_pathway,
  systemic_risk,
  modeling_concern
FROM domain_cascade_examples
ORDER BY domain;

CREATE VIEW v_containment_strategies AS
SELECT
  strategy,
  what_it_prevents,
  modeling_representation,
  tradeoff
FROM containment_strategies
ORDER BY strategy;

CREATE VIEW v_cascade_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM cascade_metrics
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

SELECT * FROM v_cascade_mechanisms;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_domain_cascade_examples;
SELECT * FROM v_containment_strategies;
SELECT * FROM v_cascade_metric_summary;
SELECT * FROM v_validation_targets;
