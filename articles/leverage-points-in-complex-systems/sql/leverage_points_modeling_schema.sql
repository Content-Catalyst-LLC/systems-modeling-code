-- leverage_points_modeling_schema.sql
-- SQLite schema and analysis queries for leverage points in complex systems.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_leverage_point_hierarchy;
DROP VIEW IF EXISTS v_intervention_scenarios;
DROP VIEW IF EXISTS v_domain_examples;
DROP VIEW IF EXISTS v_leverage_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS leverage_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS domain_examples;
DROP TABLE IF EXISTS intervention_scenarios;
DROP TABLE IF EXISTS leverage_point_hierarchy;

CREATE TABLE leverage_point_hierarchy (
  rank_from_shallow_to_deep INTEGER PRIMARY KEY,
  leverage_level TEXT NOT NULL,
  intervention_type TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  interpretation TEXT NOT NULL
);

CREATE TABLE intervention_scenarios (
  scenario TEXT PRIMARY KEY,
  feedback_gain REAL NOT NULL,
  external_correction REAL NOT NULL,
  information_delay INTEGER NOT NULL,
  information_quality REAL NOT NULL,
  buffer_capacity REAL NOT NULL,
  rule_threshold REAL,
  rule_feedback_gain REAL NOT NULL,
  self_organization_rate REAL NOT NULL,
  goal_weight_resilience REAL NOT NULL,
  implementation_delay INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE domain_examples (
  domain TEXT PRIMARY KEY,
  shallow_intervention TEXT NOT NULL,
  deeper_leverage_point TEXT NOT NULL,
  primary_risk_if_misread TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE leverage_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  intervention_depth TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO leverage_point_hierarchy (
  rank_from_shallow_to_deep,
  leverage_level,
  intervention_type,
  modeling_representation,
  interpretation
) VALUES
(1, 'parameters', 'Change numbers inside the existing system', 'external correction or coefficient change', 'Often visible but structurally shallow'),
(2, 'buffers', 'Change stabilizing stock or reserve capacity', 'buffer capacity or reserve stock', 'Can improve resilience without changing behavior drivers'),
(3, 'stock_flow_structure', 'Change accumulation pathways', 'inflow outflow or stock equation redesign', 'Changes how pressure or capability accumulates'),
(4, 'delays', 'Change signal response or implementation timing', 'information delay or implementation delay', 'Can reduce overshoot or improve timely correction'),
(5, 'balancing_feedback', 'Strengthen or retarget correction', 'feedback gain or target-seeking rule', 'Improves regulation when correction is legitimate and timely'),
(6, 'reinforcing_feedback', 'Weaken harmful self-amplification or strengthen beneficial learning', 'feedback gain or reinforcing multiplier', 'Can alter growth decline lock-in or diffusion'),
(7, 'information_flows', 'Change who knows what and when', 'information delay quality or monitoring rule', 'Can change perception accountability and action'),
(8, 'rules', 'Change incentives constraints rights and authority', 'threshold rule or conditional feedback change', 'Redirects behavior through institutional design'),
(9, 'self_organization', 'Enable learning adaptation and redesign', 'learning rate or adaptive capacity', 'Changes capacity to change later'),
(10, 'goals', 'Change what the system optimizes', 'objective weights or target priorities', 'Reorders measurement rules feedback and investment'),
(11, 'paradigms', 'Change underlying assumptions about value and possibility', 'scenario frame or model objective redesign', 'Transforms design logic and interpretation'),
(12, 'transcending_paradigms', 'Maintain capacity to question fixed frames', 'multiple objectives and reflexive governance', 'Prevents any single model frame becoming absolute');

INSERT INTO intervention_scenarios (
  scenario,
  feedback_gain,
  external_correction,
  information_delay,
  information_quality,
  buffer_capacity,
  rule_threshold,
  rule_feedback_gain,
  self_organization_rate,
  goal_weight_resilience,
  implementation_delay,
  description
) VALUES
('baseline', 0.96, 2.0, 6, 0.70, 0.0, NULL, 0.96, 0.00, 0.00, 1, 'Existing structure with delayed information and weak correction'),
('parameter_intervention', 0.96, 5.0, 6, 0.70, 0.0, NULL, 0.96, 0.00, 0.00, 1, 'Shallow intervention increases external correction only'),
('buffer_intervention', 0.96, 2.0, 6, 0.70, 18.0, NULL, 0.96, 0.00, 0.00, 1, 'Moderate intervention adds reserve capacity'),
('delay_intervention', 0.96, 2.0, 1, 0.85, 0.0, NULL, 0.96, 0.00, 0.00, 1, 'Moderate intervention improves information timing'),
('feedback_intervention', 0.78, 2.0, 6, 0.70, 0.0, NULL, 0.78, 0.00, 0.00, 1, 'Structural intervention changes feedback gain'),
('information_flow_intervention', 0.92, 2.0, 1, 0.95, 0.0, NULL, 0.92, 0.00, 0.00, 1, 'Structural intervention improves signal quality and timing'),
('rule_intervention', 0.96, 2.0, 2, 0.85, 0.0, 45.0, 0.70, 0.00, 0.00, 1, 'Deep institutional rule changes feedback when stress is high'),
('self_organization_intervention', 0.92, 2.0, 2, 0.85, 8.0, 45.0, 0.72, 0.18, 0.04, 1, 'Deep adaptive capacity supports learning and redesign'),
('goal_intervention', 0.90, 2.0, 2, 0.90, 10.0, 45.0, 0.72, 0.12, 0.10, 1, 'Deep goal shift invests in resilience and changes system priority');

INSERT INTO domain_examples (
  domain,
  shallow_intervention,
  deeper_leverage_point,
  primary_risk_if_misread
) VALUES
('infrastructure', 'Add emergency repair funds', 'Change maintenance rules inspection timing asset data and capital planning', 'Temporary improvement while degradation loop remains'),
('climate_policy', 'Adjust subsidy level', 'Change carbon accounting investment rules infrastructure standards and energy-market incentives', 'Rebound or lock-in if infrastructure rules remain unchanged'),
('public_health', 'Add temporary service capacity', 'Change surveillance trust feedback staffing pipelines and prevention incentives', 'Capacity increase absorbed by unmet need'),
('organizations', 'Raise performance targets', 'Change incentives workload design learning loops and accountability rules', 'Metric gaming and burnout'),
('urban_systems', 'Widen roads', 'Change land use pricing transit accessibility housing and mobility goals', 'Induced demand and displacement'),
('ai_governance', 'Adjust model threshold', 'Change data collection audit rules appeals accountability and system purpose', 'Automated feedback reinforces bias or opacity');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('state', 0, 1000000, 'System burden should remain nonnegative and finite'),
('pressure', 0, 1000000, 'System pressure should remain nonnegative and finite'),
('resilience', 0, 100, 'Resilience index should remain bounded'),
('learning_capacity', 0, 100, 'Learning capacity should remain bounded'),
('intervention', 0, 1000000, 'Intervention effort should remain nonnegative and finite'),
('leverage_ratio', -1000000, 1000000, 'Leverage ratio should remain finite');

INSERT INTO leverage_metrics (
  scenario,
  intervention_depth,
  metric_name,
  metric_value,
  interpretation
) VALUES
('parameter_intervention', 'shallow', 'illustrative_leverage_ratio', 0.020, 'Shallow correction changes effort but not structure'),
('buffer_intervention', 'moderate', 'illustrative_leverage_ratio', 0.035, 'Buffer improves absorption without changing goals'),
('delay_intervention', 'moderate', 'illustrative_leverage_ratio', 0.050, 'Improved timing increases responsiveness'),
('feedback_intervention', 'structural', 'illustrative_leverage_ratio', 0.110, 'Feedback gain change alters recursive behavior'),
('information_flow_intervention', 'structural', 'illustrative_leverage_ratio', 0.085, 'Information flow improves perception and action'),
('rule_intervention', 'structural', 'illustrative_leverage_ratio', 0.125, 'Rule changes feedback under stress'),
('self_organization_intervention', 'deep', 'illustrative_leverage_ratio', 0.140, 'Learning capacity changes capacity to change later'),
('goal_intervention', 'deep', 'illustrative_leverage_ratio', 0.160, 'Goal shift changes investment and evaluation logic');

CREATE VIEW v_leverage_point_hierarchy AS
SELECT
  rank_from_shallow_to_deep,
  leverage_level,
  intervention_type,
  modeling_representation,
  interpretation
FROM leverage_point_hierarchy
ORDER BY rank_from_shallow_to_deep;

CREATE VIEW v_intervention_scenarios AS
SELECT
  scenario,
  feedback_gain,
  external_correction,
  information_delay,
  information_quality,
  buffer_capacity,
  rule_threshold,
  rule_feedback_gain,
  self_organization_rate,
  goal_weight_resilience,
  implementation_delay,
  description
FROM intervention_scenarios
ORDER BY scenario;

CREATE VIEW v_domain_examples AS
SELECT
  domain,
  shallow_intervention,
  deeper_leverage_point,
  primary_risk_if_misread
FROM domain_examples
ORDER BY domain;

CREATE VIEW v_leverage_metric_summary AS
SELECT
  intervention_depth,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM leverage_metrics
GROUP BY intervention_depth, metric_name
ORDER BY intervention_depth, metric_name;

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

SELECT * FROM v_leverage_point_hierarchy;
SELECT * FROM v_intervention_scenarios;
SELECT * FROM v_domain_examples;
SELECT * FROM v_leverage_metric_summary;
SELECT * FROM v_validation_targets;
