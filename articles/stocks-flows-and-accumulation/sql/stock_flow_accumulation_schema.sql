-- stock_flow_accumulation_schema.sql
-- SQLite schema and analysis queries for stocks, flows, and accumulation.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_stock_flow_taxonomy;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_domain_examples;
DROP VIEW IF EXISTS v_stock_flow_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS stock_flow_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS domain_stock_flow_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS stock_flow_taxonomy;

CREATE TABLE stock_flow_taxonomy (
  stock_type TEXT PRIMARY KEY,
  example_stock TEXT NOT NULL,
  inflow_examples TEXT NOT NULL,
  outflow_examples TEXT NOT NULL,
  modeling_question TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  arrival_multiplier REAL NOT NULL,
  completion_capacity_shift REAL NOT NULL,
  resource_extraction_before REAL NOT NULL,
  resource_extraction_after REAL NOT NULL,
  resource_policy_time INTEGER NOT NULL,
  maintenance_before REAL NOT NULL,
  maintenance_after REAL NOT NULL,
  maintenance_policy_time INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE domain_stock_flow_examples (
  domain TEXT PRIMARY KEY,
  stock TEXT NOT NULL,
  inflow TEXT NOT NULL,
  outflow TEXT NOT NULL,
  governance_issue TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE stock_flow_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  stock TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO stock_flow_taxonomy (
  stock_type,
  example_stock,
  inflow_examples,
  outflow_examples,
  modeling_question
) VALUES
('material_stock', 'inventory', 'production delivery procurement', 'sales consumption spoilage', 'Does replenishment keep pace with demand'),
('population_stock', 'workforce', 'hiring training transfer_in', 'attrition retirement transfer_out', 'Does capability accumulate or decay'),
('environmental_stock', 'resource_stock', 'regeneration recharge restoration', 'extraction pollution mortality', 'Does use exceed regeneration'),
('infrastructure_stock', 'asset_condition', 'maintenance renewal repair', 'wear damage corrosion shocks', 'Does renewal exceed degradation'),
('operational_stock', 'backlog', 'new_cases arrivals defects', 'completed_cases repairs resolutions', 'Does processing capacity exceed arrivals'),
('financial_stock', 'debt', 'borrowing interest accrual', 'repayment forgiveness writeoff', 'Does repayment exceed new accumulation'),
('social_stock', 'trust', 'reliability accountability fairness', 'failures opacity exclusion betrayal', 'Is legitimacy accumulating or eroding'),
('knowledge_stock', 'institutional_memory', 'learning documentation retention', 'turnover forgetting fragmentation', 'Is organizational knowledge retained');

INSERT INTO scenario_definitions (
  scenario,
  arrival_multiplier,
  completion_capacity_shift,
  resource_extraction_before,
  resource_extraction_after,
  resource_policy_time,
  maintenance_before,
  maintenance_after,
  maintenance_policy_time,
  description
) VALUES
('baseline', 1.00, 0.00, 24.0, 24.0, 999, 0.9, 0.9, 999, 'No meaningful correction and persistent accumulation pressure'),
('capacity_and_conservation', 0.85, 2.0, 22.0, 12.0, 70, 1.2, 2.8, 60, 'Earlier capacity conservation and maintenance intervention'),
('delayed_response', 1.00, 1.5, 24.0, 12.0, 85, 0.9, 2.8, 85, 'Late intervention after stock pressure has accumulated'),
('high_demand_stress', 1.25, 0.0, 28.0, 18.0, 80, 0.7, 2.2, 80, 'Adverse stress scenario with higher arrivals extraction and wear'),
('adaptive_recovery', 0.90, 3.0, 22.0, 10.0, 55, 1.4, 3.4, 50, 'Stronger adaptive intervention with earlier corrective flows');

INSERT INTO domain_stock_flow_examples (
  domain,
  stock,
  inflow,
  outflow,
  governance_issue
) VALUES
('climate_policy', 'atmospheric_greenhouse_gases', 'emissions', 'removals_and_absorption', 'Annual emissions can fall while the stock still rises'),
('infrastructure', 'asset_condition', 'maintenance_and_renewal', 'wear_and_damage', 'Budget flows may be too small to reverse accumulated degradation'),
('health_systems', 'care_backlog', 'new_cases', 'completed_cases', 'Capacity increases only help if completions exceed arrivals'),
('housing', 'housing_stock', 'new_units', 'demolition_conversion_loss', 'Affordability depends on stock distribution not only new construction'),
('organizations', 'institutional_memory', 'learning_documentation', 'turnover_forgetting', 'Capability can decay despite ongoing activity'),
('water_systems', 'groundwater_storage', 'recharge', 'pumping_evaporation', 'Extraction can exceed recharge for long periods before crisis appears'),
('public_finance', 'outstanding_debt', 'borrowing_interest', 'repayment', 'Payments do not reduce debt if interest and new borrowing exceed repayment');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('backlog', 0, 1000000, 'Backlog should remain nonnegative and finite'),
('resource', 0, 1000000, 'Resource stock should remain nonnegative and finite'),
('infrastructure_condition', 0, 100, 'Condition index should remain bounded'),
('net_flow', -1000000, 1000000, 'Net flow should remain finite'),
('recovery_time', 0, 1000000, 'Recovery time should be nonnegative when present'),
('mean_net_flow', -1000000, 1000000, 'Mean net flow should remain finite');

INSERT INTO stock_flow_metrics (
  scenario,
  stock,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline', 'backlog', 'illustrative_final_value', 180.0, 'Backlog accumulates when arrivals exceed completions'),
('baseline', 'resource', 'illustrative_final_value', 340.0, 'Resource declines when extraction exceeds regeneration'),
('baseline', 'infrastructure_condition', 'illustrative_final_value', 35.0, 'Condition declines when wear exceeds maintenance'),
('capacity_and_conservation', 'backlog', 'illustrative_final_value', 70.0, 'Capacity intervention can reverse backlog accumulation'),
('capacity_and_conservation', 'resource', 'illustrative_final_value', 520.0, 'Lower extraction supports resource stabilization'),
('capacity_and_conservation', 'infrastructure_condition', 'illustrative_final_value', 76.0, 'Maintenance intervention supports condition recovery'),
('delayed_response', 'backlog', 'illustrative_final_value', 125.0, 'Late response leaves more accumulated burden'),
('adaptive_recovery', 'infrastructure_condition', 'illustrative_final_value', 88.0, 'Early and stronger maintenance improves recovery trajectory');

CREATE VIEW v_stock_flow_taxonomy AS
SELECT
  stock_type,
  example_stock,
  inflow_examples,
  outflow_examples,
  modeling_question
FROM stock_flow_taxonomy
ORDER BY stock_type;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  arrival_multiplier,
  completion_capacity_shift,
  resource_extraction_before,
  resource_extraction_after,
  resource_policy_time,
  maintenance_before,
  maintenance_after,
  maintenance_policy_time,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_domain_examples AS
SELECT
  domain,
  stock,
  inflow,
  outflow,
  governance_issue
FROM domain_stock_flow_examples
ORDER BY domain;

CREATE VIEW v_stock_flow_metric_summary AS
SELECT
  scenario,
  stock,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM stock_flow_metrics
GROUP BY scenario, stock, metric_name
ORDER BY scenario, stock, metric_name;

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

SELECT * FROM v_stock_flow_taxonomy;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_domain_examples;
SELECT * FROM v_stock_flow_metric_summary;
SELECT * FROM v_validation_targets;
