-- public_policy_scenario_modeling_schema.sql
-- SQLite schema and review queries for public policy scenario modeling.

DROP VIEW IF EXISTS v_policy_options;
DROP VIEW IF EXISTS v_future_scenarios;
DROP VIEW IF EXISTS v_metric_weights;
DROP VIEW IF EXISTS v_policy_base_ranking;
DROP VIEW IF EXISTS v_scenario_stress_ranking;
DROP VIEW IF EXISTS v_model_assumptions;
DROP VIEW IF EXISTS v_diagnostic_definitions;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS diagnostic_definitions;
DROP TABLE IF EXISTS model_assumptions;
DROP TABLE IF EXISTS metric_weights;
DROP TABLE IF EXISTS future_scenarios;
DROP TABLE IF EXISTS policy_options;

CREATE TABLE policy_options (
  policy TEXT PRIMARY KEY,
  base_benefit REAL NOT NULL,
  base_cost REAL NOT NULL,
  base_equity REAL NOT NULL,
  base_resilience REAL NOT NULL,
  base_feasibility REAL NOT NULL,
  base_legitimacy REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE future_scenarios (
  scenario TEXT PRIMARY KEY,
  cost_multiplier REAL NOT NULL,
  benefit_multiplier REAL NOT NULL,
  equity_multiplier REAL NOT NULL,
  resilience_multiplier REAL NOT NULL,
  feasibility_multiplier REAL NOT NULL,
  legitimacy_multiplier REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE metric_weights (
  metric TEXT PRIMARY KEY,
  weight REAL NOT NULL,
  direction TEXT NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE model_assumptions (
  assumption_id TEXT PRIMARY KEY,
  assumption TEXT NOT NULL,
  category TEXT NOT NULL,
  risk_if_wrong TEXT NOT NULL,
  review_action TEXT NOT NULL
);

CREATE TABLE diagnostic_definitions (
  diagnostic TEXT PRIMARY KEY,
  definition TEXT NOT NULL,
  why_it_matters TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

INSERT INTO policy_options VALUES
('status_quo_maintenance',0.45,0.25,0.35,0.30,0.88,0.50,'Continue current policy with incremental maintenance'),
('targeted_intervention',0.68,0.48,0.72,0.62,0.70,0.68,'Focus resources on high risk groups places or bottlenecks'),
('universal_program',0.78,0.82,0.80,0.66,0.52,0.74,'Provide broad coverage through a larger public program'),
('adaptive_pathway',0.72,0.58,0.76,0.86,0.68,0.78,'Use staged action triggers monitoring and escalation');

INSERT INTO future_scenarios VALUES
('baseline_future',1.00,1.00,1.00,1.00,1.00,1.00,'Moderate demand stable budget and normal implementation'),
('fiscal_stress',1.35,0.90,0.92,0.95,0.86,0.92,'Budget pressure and higher costs stress policy feasibility'),
('demand_surge',1.12,1.20,0.96,1.10,0.78,0.90,'Service need rises faster than expected'),
('implementation_delay',1.10,0.82,0.95,0.90,0.62,0.88,'Administrative capacity and delivery constraints slow rollout'),
('compound_risk',1.30,0.88,0.90,1.30,0.72,0.82,'Fiscal pressure demand stress risk severity and implementation difficulty combine'),
('equity_legitimacy_pressure',1.08,0.95,1.25,1.05,0.82,1.20,'Distributional fairness and public trust become decisive');

INSERT INTO metric_weights VALUES
('benefit',0.24,'positive','Public benefit improves the score'),
('cost',0.18,'negative','Fiscal cost reduces the score'),
('equity',0.20,'positive','Distributional performance improves the score'),
('resilience',0.18,'positive','Robustness under shocks improves the score'),
('feasibility',0.10,'positive','Implementation feasibility improves the score'),
('legitimacy',0.10,'positive','Public legitimacy improves the score');

INSERT INTO model_assumptions VALUES
('A1','Policy options are treated as separate choices','boundary','Real policy portfolios may combine options','Test hybrid portfolios and staged packages'),
('A2','Metrics are normalized between zero and one','measurement','Normalization can hide scale and distributional stakes','Show raw metrics where available'),
('A3','Metric weights are explicit and fixed for the base run','values','Weights encode contested public values','Run sensitivity tests and stakeholder weighting'),
('A4','Scenario multipliers are synthetic','uncertainty','Future stress could be misrepresented','Use evidence expert review and participatory scenario design'),
('A5','Legitimacy is represented as a score','governance','Public trust cannot be reduced to one number','Pair model output with qualitative review'),
('A6','Implementation feasibility is simplified','implementation','Delivery constraints may dominate outcomes','Add staffing procurement and operational timelines'),
('A7','Composite score is not a decision rule','interpretation','Model output may be mistaken for an automatic answer','Use decision records and public reasoning');

INSERT INTO diagnostic_definitions VALUES
('composite_score','Weighted policy score in one scenario','Supports transparent scenario comparison'),
('average_score','Mean policy score across scenarios','Summarizes overall performance but can hide downside risk'),
('worst_case_score','Lowest policy score across scenarios','Shows downside vulnerability'),
('best_case_score','Highest policy score across scenarios','Shows upside potential'),
('regret','Gap between a policy and the best policy in that scenario','Shows missed opportunity under a future'),
('maximum_regret','Largest regret across scenarios','Identifies worst scenario specific underperformance'),
('acceptable_scenario_share','Share of scenarios where score clears the acceptability threshold','Shows satisficing performance'),
('scenario_failure_count','Number of scenarios where policy fails the acceptability threshold','Shows unacceptable downside count'),
('robustness_score','Combined average worst case and regret adjusted score','Supports decision making under uncertainty');

INSERT INTO validation_targets VALUES
('policy_count',1,1000000,'Workflow should include at least one policy'),
('scenario_count',1,1000000,'Workflow should include at least one scenario'),
('metric_weight_sum',1,1,'Metric weights should sum to one'),
('composite_score',-1,1,'Composite score should remain bounded for this synthetic model'),
('regret',0,1000000,'Regret should remain nonnegative'),
('acceptable_scenario_share',0,1,'Acceptability share should remain normalized between zero and one');

CREATE VIEW v_policy_options AS
SELECT * FROM policy_options ORDER BY policy;

CREATE VIEW v_future_scenarios AS
SELECT * FROM future_scenarios ORDER BY scenario;

CREATE VIEW v_metric_weights AS
SELECT * FROM metric_weights ORDER BY metric;

CREATE VIEW v_policy_base_ranking AS
SELECT
  policy,
  ROUND(0.24 * base_benefit - 0.18 * base_cost + 0.20 * base_equity + 0.18 * base_resilience + 0.10 * base_feasibility + 0.10 * base_legitimacy, 6) AS base_composite_score,
  base_benefit,
  base_cost,
  base_equity,
  base_resilience,
  base_feasibility,
  base_legitimacy
FROM policy_options
ORDER BY base_composite_score DESC;

CREATE VIEW v_scenario_stress_ranking AS
SELECT
  scenario,
  ROUND(cost_multiplier + (1 - benefit_multiplier) + (1 - feasibility_multiplier) + (1 - legitimacy_multiplier), 6) AS simple_stress_index,
  description
FROM future_scenarios
ORDER BY simple_stress_index DESC;

CREATE VIEW v_model_assumptions AS
SELECT * FROM model_assumptions ORDER BY assumption_id;

CREATE VIEW v_diagnostic_definitions AS
SELECT * FROM diagnostic_definitions ORDER BY diagnostic;

CREATE VIEW v_validation_targets AS
SELECT * FROM validation_targets ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_policy_options;
SELECT * FROM v_future_scenarios;
SELECT * FROM v_metric_weights;
SELECT * FROM v_policy_base_ranking;
SELECT * FROM v_scenario_stress_ranking;
SELECT * FROM v_model_assumptions;
SELECT * FROM v_diagnostic_definitions;
SELECT * FROM v_validation_targets;
