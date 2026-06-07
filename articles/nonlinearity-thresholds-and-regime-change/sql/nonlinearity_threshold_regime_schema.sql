-- nonlinearity_threshold_regime_schema.sql
-- SQLite schema and analysis queries for nonlinearity, thresholds, and regime change.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_nonlinearity_taxonomy;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_domain_threshold_examples;
DROP VIEW IF EXISTS v_regime_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS regime_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS domain_threshold_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS nonlinearity_taxonomy;

CREATE TABLE nonlinearity_taxonomy (
  nonlinearity_type TEXT PRIMARY KEY,
  system_meaning TEXT NOT NULL,
  example TEXT NOT NULL,
  modeling_representation TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  collapse_threshold REAL NOT NULL,
  recovery_threshold REAL NOT NULL,
  intervention_time INTEGER NOT NULL,
  pressure_growth REAL NOT NULL,
  recovery_effort REAL NOT NULL,
  initial_state REAL NOT NULL,
  initial_pressure REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE domain_threshold_examples (
  domain TEXT PRIMARY KEY,
  threshold_type TEXT NOT NULL,
  pre_threshold_behavior TEXT NOT NULL,
  post_threshold_behavior TEXT NOT NULL,
  modeling_question TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE regime_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO nonlinearity_taxonomy (
  nonlinearity_type,
  system_meaning,
  example,
  modeling_representation
) VALUES
('saturation', 'response approaches a maximum capacity', 'service completions capped by workforce', 'capacity-limited flow'),
('threshold_response', 'relationship changes after a boundary', 'infrastructure failures accelerate below condition threshold', 'piecewise rule'),
('positive_feedback', 'change amplifies itself', 'adoption contagion erosion burnout', 'reinforcing loop'),
('diminishing_returns', 'marginal benefit declines', 'additional funding constrained by implementation capacity', 'concave function'),
('capacity_overload', 'performance deteriorates near utilization limit', 'hospital or queue delay near full capacity', 'utilization-sensitive delay'),
('regeneration_limit', 'recovery depends on remaining stock', 'fish forest soil trust recovery', 'stock-dependent growth'),
('interaction_effect', 'two pressures combine non-additively', 'heat plus drought or debt plus interest', 'multiplicative or conditional term'),
('hysteresis', 'recovery path differs from damage path', 'ecosystem or trust recovery after collapse', 'separate collapse and recovery thresholds'),
('multiple_stable_states', 'system can persist in more than one regime', 'clear lake vs turbid lake', 'bistable regime model'),
('cascade_threshold', 'local threshold crossing propagates', 'network failure load redistribution', 'network threshold rule');

INSERT INTO scenario_definitions (
  scenario,
  collapse_threshold,
  recovery_threshold,
  intervention_time,
  pressure_growth,
  recovery_effort,
  initial_state,
  initial_pressure,
  description
) VALUES
('early_intervention', 70.0, 45.0, 55, 0.85, 1.20, 82.0, 20.0, 'Intervention begins before collapse threshold is reached'),
('late_intervention', 70.0, 45.0, 85, 0.85, 1.20, 82.0, 20.0, 'Intervention begins after degradation has accumulated'),
('strong_recovery', 70.0, 45.0, 85, 0.85, 2.00, 82.0, 20.0, 'Late intervention but stronger recovery effort'),
('lower_threshold_stress', 58.0, 38.0, 70, 0.95, 1.20, 82.0, 20.0, 'Lower collapse threshold and faster pressure growth'),
('high_resilience_buffer', 82.0, 52.0, 80, 0.80, 1.30, 88.0, 18.0, 'Higher threshold and stronger initial condition'),
('hysteresis_trap', 66.0, 30.0, 88, 0.90, 1.30, 82.0, 20.0, 'Large gap between collapse and recovery threshold makes return difficult'),
('compound_pressure', 62.0, 42.0, 75, 1.10, 1.40, 82.0, 20.0, 'Compound stress pushes system quickly toward threshold'),
('rapid_prevention', 70.0, 45.0, 40, 0.85, 1.80, 82.0, 20.0, 'Early and stronger intervention prevents regime shift');

INSERT INTO domain_threshold_examples (
  domain,
  threshold_type,
  pre_threshold_behavior,
  post_threshold_behavior,
  modeling_question
) VALUES
('ecology', 'regime_shift', 'ecosystem absorbs pressure', 'degraded state reinforces itself', 'Does restoration require crossing a separate recovery threshold'),
('infrastructure', 'failure_threshold', 'asset condition declines gradually', 'failure risk accelerates', 'When does preventive maintenance stop being sufficient'),
('health_systems', 'capacity_threshold', 'service delay remains manageable', 'overload produces triage burnout and quality loss', 'How close is the system to surge overload'),
('finance', 'liquidity_threshold', 'markets clear under stress', 'confidence loss causes withdrawal and fire sales', 'When do losses become self-reinforcing'),
('public_trust', 'social_threshold', 'communication and compliance remain effective', 'mistrust undermines cooperation', 'When does legitimacy loss alter policy response'),
('supply_chains', 'cascade_threshold', 'local disruption is absorbed', 'shortages propagate through dependencies', 'Which nodes trigger systemic disruption'),
('climate', 'critical_transition', 'system remains within operating range', 'feedbacks alter state or recovery dynamics', 'Which thresholds dominate long-horizon risk');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('system_state', 0, 100, 'System state should remain bounded between 0 and 100'),
('pressure', 0, 1000000, 'Pressure should remain nonnegative and finite'),
('damage_flow', 0, 1000000, 'Damage flow should remain nonnegative and finite'),
('recovery_flow', 0, 1000000, 'Recovery flow should remain nonnegative and finite'),
('net_flow', -1000000, 1000000, 'Net flow should remain finite'),
('degraded_periods', 0, 1000000, 'Degraded-period count should be nonnegative'),
('rolling_variance_12', 0, 1000000, 'Rolling variance should remain nonnegative and finite'),
('rolling_autocorrelation_12', -1, 1, 'Autocorrelation should remain bounded when available');

INSERT INTO regime_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('early_intervention', 'illustrative_degraded_periods', 0, 'Early intervention avoids degraded regime'),
('late_intervention', 'illustrative_degraded_periods', 35, 'Late intervention allows degradation to persist'),
('strong_recovery', 'illustrative_degraded_periods', 18, 'Stronger recovery shortens degraded period'),
('lower_threshold_stress', 'illustrative_degraded_periods', 70, 'Lower threshold and faster pressure growth increase transition risk'),
('hysteresis_trap', 'illustrative_hysteresis_gap', 36, 'Large gap makes recovery difficult'),
('rapid_prevention', 'illustrative_degraded_periods', 0, 'Early and strong prevention avoids threshold crossing');

CREATE VIEW v_nonlinearity_taxonomy AS
SELECT
  nonlinearity_type,
  system_meaning,
  example,
  modeling_representation
FROM nonlinearity_taxonomy
ORDER BY nonlinearity_type;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  collapse_threshold,
  recovery_threshold,
  intervention_time,
  pressure_growth,
  recovery_effort,
  initial_state,
  initial_pressure,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_domain_threshold_examples AS
SELECT
  domain,
  threshold_type,
  pre_threshold_behavior,
  post_threshold_behavior,
  modeling_question
FROM domain_threshold_examples
ORDER BY domain;

CREATE VIEW v_regime_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM regime_metrics
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

SELECT * FROM v_nonlinearity_taxonomy;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_domain_threshold_examples;
SELECT * FROM v_regime_metric_summary;
SELECT * FROM v_validation_targets;
