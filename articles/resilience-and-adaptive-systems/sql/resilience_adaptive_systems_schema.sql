PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_resilience_dimensions;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_domain_resilience_examples;
DROP VIEW IF EXISTS v_resilience_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;
DROP TABLE IF EXISTS resilience_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS domain_resilience_examples;
DROP TABLE IF EXISTS shock_schedule;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS resilience_dimensions;

CREATE TABLE resilience_dimensions (dimension TEXT PRIMARY KEY, system_meaning TEXT NOT NULL, modeling_indicator TEXT NOT NULL, common_tradeoff TEXT NOT NULL);
CREATE TABLE scenario_definitions (scenario TEXT PRIMARY KEY, initial_adaptive_capacity REAL NOT NULL, recovery_erosion REAL NOT NULL, learning_gain REAL NOT NULL, shock_multiplier REAL NOT NULL, adaptation_floor REAL NOT NULL, description TEXT NOT NULL);
CREATE TABLE shock_schedule (time INTEGER PRIMARY KEY, baseline_shock REAL NOT NULL, description TEXT NOT NULL);
CREATE TABLE domain_resilience_examples (domain TEXT PRIMARY KEY, focal_function TEXT NOT NULL, disturbance TEXT NOT NULL, resilience_question TEXT NOT NULL, modeling_approach TEXT NOT NULL);
CREATE TABLE validation_targets (metric TEXT PRIMARY KEY, target_low REAL NOT NULL, target_high REAL NOT NULL, notes TEXT NOT NULL);
CREATE TABLE resilience_metrics (metric_id INTEGER PRIMARY KEY, scenario TEXT NOT NULL, metric_name TEXT NOT NULL, metric_value REAL NOT NULL, interpretation TEXT NOT NULL);

INSERT INTO resilience_dimensions VALUES
('absorptive_capacity','ability to absorb disturbance without major function loss','maximum performance loss','buffers may reduce short-term efficiency'),
('recovery_capacity','ability to restore function after disruption','recovery time and downtime','fast restoration may preserve fragile structures'),
('adaptive_capacity','ability to learn and adjust behavior rules or resources','adaptive capacity trajectory','frequent adaptation can reduce stability'),
('transformability','ability to shift to a new viable configuration','transition pathway availability','transformation can impose transition costs'),
('redundancy','backup capacity alternate routes and overlapping functions','backup capacity and alternate paths','redundancy can be expensive or underused'),
('diversity','variation in components strategies and knowledge','component or strategy diversity','diversity can complicate coordination'),
('modularity','ability to contain failure within parts of the system','contained-failure share','too much modularity can reduce integration'),
('learning_memory','ability to retain lessons and update behavior','learning gain and institutional memory','past lessons can become rigid assumptions');

INSERT INTO scenario_definitions VALUES
('baseline_adaptation',0.22,0.0009,0.0007,1.00,0.03,'Moderate adaptive capacity and moderate repeated shocks'),
('weakened_capacity',0.16,0.0014,0.0003,1.00,0.03,'Lower initial capacity and faster erosion'),
('compound_stress',0.18,0.0012,0.0004,1.35,0.03,'Higher shock magnitude with weaker learning'),
('learning_investment',0.24,0.0006,0.0012,1.00,0.03,'Greater learning and slower erosion improve recovery'),
('high_redundancy',0.27,0.0008,0.0008,0.85,0.05,'Redundancy lowers effective disturbance and raises minimum capacity'),
('fragile_efficiency',0.14,0.0018,0.0002,1.20,0.02,'Efficiency-oriented system with little slack and high erosion'),
('transformative_adaptation',0.20,0.0007,0.0016,1.10,0.04,'Learning improves after disturbance and supports structural adaptation'),
('chronic_stress',0.17,0.0015,0.0004,1.05,0.03,'Repeated stress with lower capacity and persistent recovery burden');

INSERT INTO shock_schedule VALUES
(25,1.5,'first disturbance tests absorptive capacity'),
(55,1.7,'second disturbance tests recovery after partial adaptation'),
(90,2.0,'larger disturbance tests cumulative resilience'),
(125,2.2,'late disturbance tests capacity erosion and learning'),
(155,2.5,'largest disturbance tests degraded or adaptive response');

INSERT INTO domain_resilience_examples VALUES
('infrastructure','service_continuity','asset_failure_or_extreme_weather','How quickly can function be restored after disruption','stock_flow_network_model'),
('ecology','ecosystem_function','drought_fire_nutrient_loading','Can the system avoid an undesirable regime shift','threshold_regime_model'),
('health_systems','care_capacity','demand_surge_staff_loss','Can service continue under surge conditions','discrete_event_system_dynamics'),
('supply_chains','material_flow','supplier_failure_transport_disruption','Can flows reroute without cascading shortage','network_simulation'),
('public_trust','cooperation_and_legitimacy','institutional_failure_or_misinformation','Can trust recover after repeated failure','stock_flow_feedback_model'),
('finance','liquidity_and_confidence','losses_or_contagion','Can the system absorb losses without panic','network_threshold_model'),
('organizations','productive_capacity','burnout_turnover_strategy_shock','Can learning offset capacity erosion','adaptive_capacity_model');

INSERT INTO validation_targets VALUES
('state',-1000000,1000000,'System state should remain finite'),
('absolute_state',0,1000000,'Absolute deviation should remain nonnegative and finite'),
('adaptive_capacity',0,100,'Adaptive capacity should remain nonnegative and bounded'),
('performance',0,1,'Performance should remain between 0 and 1'),
('performance_loss',0,1,'Performance loss should remain between 0 and 1'),
('average_recovery_time',0,1000000,'Recovery time should be nonnegative when available'),
('unrecovered_shocks',0,1000,'Unrecovered-shock count should be nonnegative'),
('cumulative_performance_loss',0,1000000,'Cumulative loss should remain nonnegative and finite');

INSERT INTO resilience_metrics (scenario, metric_name, metric_value, interpretation) VALUES
('baseline_adaptation','illustrative_mean_performance',0.86,'Moderate adaptation retains most performance'),
('weakened_capacity','illustrative_mean_performance',0.75,'Lower capacity produces higher cumulative loss'),
('compound_stress','illustrative_minimum_performance',0.42,'Compound stress creates deeper performance loss'),
('learning_investment','illustrative_mean_performance',0.91,'Learning investment improves recovery'),
('high_redundancy','illustrative_minimum_performance',0.78,'Redundancy reduces shock impact'),
('fragile_efficiency','illustrative_minimum_performance',0.35,'Efficiency without slack reduces resilience');

CREATE VIEW v_resilience_dimensions AS SELECT * FROM resilience_dimensions ORDER BY dimension;
CREATE VIEW v_scenario_definitions AS SELECT * FROM scenario_definitions ORDER BY scenario;
CREATE VIEW v_domain_resilience_examples AS SELECT * FROM domain_resilience_examples ORDER BY domain;
CREATE VIEW v_resilience_metric_summary AS SELECT scenario, metric_name, ROUND(MIN(metric_value),3) AS minimum_value, ROUND(AVG(metric_value),3) AS average_value, ROUND(MAX(metric_value),3) AS maximum_value FROM resilience_metrics GROUP BY scenario, metric_name ORDER BY scenario, metric_name;
CREATE VIEW v_validation_targets AS SELECT * FROM validation_targets ORDER BY metric;

.headers on
.mode column
SELECT * FROM v_resilience_dimensions;
SELECT * FROM v_scenario_definitions;
SELECT * FROM shock_schedule;
SELECT * FROM v_domain_resilience_examples;
SELECT * FROM v_resilience_metric_summary;
SELECT * FROM v_validation_targets;
