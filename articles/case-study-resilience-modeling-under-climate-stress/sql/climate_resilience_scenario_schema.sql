-- climate_resilience_scenario_schema.sql
-- SQLite schema and review queries for climate resilience scenario modeling.

DROP VIEW IF EXISTS v_climate_resilience_scenarios;
DROP VIEW IF EXISTS v_scenario_vulnerability_index;
DROP VIEW IF EXISTS v_adaptation_timing;
DROP VIEW IF EXISTS v_model_assumptions;
DROP VIEW IF EXISTS v_diagnostic_definitions;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS diagnostic_definitions;
DROP TABLE IF EXISTS model_assumptions;
DROP TABLE IF EXISTS climate_resilience_scenarios;

CREATE TABLE climate_resilience_scenarios (
  scenario TEXT PRIMARY KEY,
  exposure REAL NOT NULL,
  sensitivity REAL NOT NULL,
  initial_capacity REAL NOT NULL,
  recovery_rate REAL NOT NULL,
  investment_start INTEGER NOT NULL,
  investment_rate REAL NOT NULL,
  degradation_rate REAL NOT NULL,
  transformation_trigger INTEGER NOT NULL,
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

INSERT INTO climate_resilience_scenarios VALUES
('moderate_climate_stress',0.55,0.42,0.58,0.11,8,0.006,0.020,0,'Gradual stress increase with manageable shocks'),
('repeated_shocks',0.65,0.50,0.52,0.08,12,0.008,0.030,0,'Several climate shocks occur before full recovery'),
('delayed_adaptation',0.65,0.52,0.48,0.07,24,0.012,0.035,0,'Adaptation investment begins after significant stress'),
('targeted_resilience_investment',0.62,0.46,0.54,0.12,6,0.018,0.020,0,'Early targeted investment improves adaptive capacity'),
('compound_climate_stress',0.78,0.62,0.46,0.06,12,0.012,0.045,0,'Multiple climate stressors interact and amplify damage'),
('transformation_pathway',0.74,0.58,0.45,0.08,16,0.020,0.040,1,'Structural transformation is triggered after severe stress');

INSERT INTO model_assumptions VALUES
('A1','Service level is normalized between zero and one','measurement','Normalization can hide real service thresholds and uneven consequences','Show raw service metrics where available'),
('A2','Climate stress trajectories are synthetic','uncertainty','Real hazards may be spatially uneven correlated or more severe','Use local hazard data and scenario ranges'),
('A3','Adaptive capacity reduces effective stress','capacity','Formal capacity may fail under compound shocks or institutional breakdown','Validate with observed response capacity'),
('A4','Recovery is modeled as a rate','recovery','Real recovery depends on logistics finance staffing access and governance','Add operational recovery model where needed'),
('A5','Repeated stress can degrade capacity','degradation','Degradation may be nonlinear hidden or irreversible','Test nonlinear and irreversible degradation rules'),
('A6','Adaptation investment improves capacity after timing threshold','adaptation','Investment may underperform maladapt or shift risk','Test weak delayed and maladaptive investment cases'),
('A7','Threshold risk uses a critical service level','threshold','Real thresholds may be contested uncertain or domain-specific','Define thresholds with domain evidence and stakeholder review'),
('A8','Transformation is represented with a simplified trigger','transformation','Transformation is institutional political ethical and place-specific','Use participatory pathway design and governance review');

INSERT INTO diagnostic_definitions VALUES
('average_service','Mean service level across the simulation','Summarizes overall performance but can hide severe dips'),
('minimum_service','Lowest service level reached','Shows worst-case disruption'),
('time_below_threshold','Number of periods where service falls below the critical threshold','Measures severe risk exposure'),
('threshold_crossings','Number of times service newly falls below threshold','Shows repeated severe-risk episodes'),
('final_adaptive_capacity','Adaptive capacity at the end of the simulation','Shows whether capacity improved or eroded'),
('final_degradation','Cumulative degradation at the end of the simulation','Shows long-run erosion of system function'),
('transformed','Whether transformation trigger was activated','Shows when restoration became insufficient in the simplified model'),
('resilience_score','Average service penalized by threshold exposure and degradation','Supports scenario comparison when disaggregated metrics are also shown');

INSERT INTO validation_targets VALUES
('scenario_count',1,1000000,'Workflow should include at least one scenario'),
('service_level',0,1,'Service level should remain normalized between zero and one'),
('adaptive_capacity',0,1,'Adaptive capacity should remain normalized between zero and one'),
('degradation',0,1,'Degradation should remain normalized between zero and one'),
('climate_stress',0,1000000,'Climate stress should remain nonnegative'),
('time_below_threshold',0,1000000,'Time below threshold should remain nonnegative');

CREATE VIEW v_climate_resilience_scenarios AS
SELECT * FROM climate_resilience_scenarios
ORDER BY scenario;

CREATE VIEW v_scenario_vulnerability_index AS
SELECT
  scenario,
  ROUND(exposure * sensitivity * (1.0 - initial_capacity), 6) AS simple_vulnerability_index,
  exposure,
  sensitivity,
  initial_capacity,
  recovery_rate,
  degradation_rate,
  description
FROM climate_resilience_scenarios
ORDER BY simple_vulnerability_index DESC;

CREATE VIEW v_adaptation_timing AS
SELECT
  scenario,
  investment_start,
  investment_rate,
  transformation_trigger,
  recovery_rate,
  description
FROM climate_resilience_scenarios
ORDER BY investment_start ASC, investment_rate DESC;

CREATE VIEW v_model_assumptions AS
SELECT * FROM model_assumptions ORDER BY assumption_id;

CREATE VIEW v_diagnostic_definitions AS
SELECT * FROM diagnostic_definitions ORDER BY diagnostic;

CREATE VIEW v_validation_targets AS
SELECT * FROM validation_targets ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_climate_resilience_scenarios;
SELECT * FROM v_scenario_vulnerability_index;
SELECT * FROM v_adaptation_timing;
SELECT * FROM v_model_assumptions;
SELECT * FROM v_diagnostic_definitions;
SELECT * FROM v_validation_targets;
