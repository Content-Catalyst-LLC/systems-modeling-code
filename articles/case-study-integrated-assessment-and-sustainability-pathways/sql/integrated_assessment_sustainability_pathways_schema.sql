-- integrated_assessment_sustainability_pathways_schema.sql
-- SQLite schema and review queries for integrated assessment and sustainability pathways.

DROP VIEW IF EXISTS v_sustainability_pathways;
DROP VIEW IF EXISTS v_transition_intensity;
DROP VIEW IF EXISTS v_pathway_risk_profile;
DROP VIEW IF EXISTS v_model_assumptions;
DROP VIEW IF EXISTS v_diagnostic_definitions;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS diagnostic_definitions;
DROP TABLE IF EXISTS model_assumptions;
DROP TABLE IF EXISTS sustainability_pathways;

CREATE TABLE sustainability_pathways (
  pathway TEXT PRIMARY KEY,
  demand_growth REAL NOT NULL,
  efficiency_gain REAL NOT NULL,
  clean_growth_early REAL NOT NULL,
  clean_growth_late REAL NOT NULL,
  adaptation_investment REAL NOT NULL,
  transition_cost_factor REAL NOT NULL,
  equity_support REAL NOT NULL,
  ecological_constraint REAL NOT NULL,
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

INSERT INTO sustainability_pathways VALUES
('baseline_continuation',0.018,0.004,0.010,0.014,0.004,0.30,0.20,0.20,'Slow transition and limited adaptation'),
('delayed_transition',0.017,0.006,0.006,0.032,0.006,0.55,0.30,0.25,'Mitigation starts late and accelerates later'),
('rapid_decarbonization',0.012,0.012,0.035,0.028,0.010,0.85,0.50,0.35,'Clean energy and efficiency scale quickly'),
('adaptation_heavy',0.015,0.007,0.014,0.018,0.022,0.62,0.48,0.30,'Adaptation investment is emphasized'),
('equity_centered_transition',0.013,0.010,0.026,0.026,0.016,0.78,0.88,0.40,'Transition includes affordability access and vulnerability support'),
('ecological_constraint',0.010,0.011,0.020,0.022,0.014,0.70,0.62,0.85,'Land water and ecological limits constrain pathway choices');

INSERT INTO model_assumptions VALUES
('A1','Energy demand changes through growth and efficiency','demand','Rebound sectoral shifts or electrification could change demand trajectories','Test demand sensitivity and sector-specific demand modules'),
('A2','Clean energy share reduces emissions intensity','energy','Life-cycle emissions reliability and supply-chain constraints may be hidden','Add sector-specific technology and life-cycle accounting'),
('A3','Cumulative emissions increase climate stress','climate','Real climate response is nonlinear uncertain and regionally uneven','Use climate scenarios and uncertainty ranges'),
('A4','Adaptation capacity reduces climate damages','adaptation','Adaptation may be delayed maladaptive unequal or insufficient','Test weak delayed and equity-targeted adaptation cases'),
('A5','Land pressure and water stress are simplified resource indicators','resources','Spatial ecological and hydrological dynamics may be misrepresented','Use geospatial land water and biodiversity modules where needed'),
('A6','Equity is represented as a normalized diagnostic','equity','Justice rights vulnerability and legitimacy cannot be reduced to one number','Use distributional metrics and participatory review'),
('A7','Sustainability score is a diagnostic not a decision rule','interpretation','Weights can hide contested values and tradeoffs','Publish weights and test alternative weighting schemes'),
('A8','Pathways are conditional futures not predictions','communication','Users may mistake scenarios for forecasts','Communicate assumptions uncertainty and valid use clearly');

INSERT INTO diagnostic_definitions VALUES
('final_clean_energy_share','Clean energy share at the end of the pathway','Shows structural energy transition progress'),
('cumulative_emissions','Total emissions accumulated across the pathway','Shows long-term climate pressure'),
('average_climate_damages','Mean modeled climate damages over the pathway','Connects emissions climate stress and adaptation'),
('average_transition_cost','Mean modeled transition cost','Shows implementation and affordability pressure'),
('average_land_pressure','Mean modeled pressure on land systems','Reveals ecological food and land-use tradeoffs'),
('average_water_stress','Mean modeled pressure on water systems','Connects energy climate adaptation and resource constraints'),
('average_equity_score','Mean modeled distributional performance','Shows affordability access and vulnerability support'),
('final_adaptation_capacity','Adaptation capacity at the end of the pathway','Shows readiness for residual climate stress'),
('constraint_breach_count','Number of periods where land water or equity limits are breached','Shows unacceptable or fragile pathway conditions'),
('average_sustainability_score','Composite diagnostic score across pathway indicators','Supports comparison when disaggregated metrics remain visible');

INSERT INTO validation_targets VALUES
('pathway_count',1,1000000,'Workflow should include at least one pathway'),
('clean_energy_share',0,1,'Clean energy share should remain normalized between zero and one'),
('adaptation_capacity',0,1,'Adaptation capacity should remain normalized between zero and one'),
('equity_score',0,1,'Equity score should remain normalized between zero and one'),
('annual_emissions',0,1000000,'Annual emissions should remain nonnegative'),
('land_pressure',0,1,'Land pressure should remain normalized between zero and one'),
('water_stress',0,1,'Water stress should remain normalized between zero and one'),
('constraint_breach_count',0,1000000,'Constraint breach count should remain nonnegative');

CREATE VIEW v_sustainability_pathways AS
SELECT * FROM sustainability_pathways
ORDER BY pathway;

CREATE VIEW v_transition_intensity AS
SELECT
  pathway,
  ROUND(clean_growth_early + clean_growth_late + efficiency_gain + adaptation_investment, 6) AS transition_intensity_index,
  clean_growth_early,
  clean_growth_late,
  efficiency_gain,
  adaptation_investment,
  transition_cost_factor,
  description
FROM sustainability_pathways
ORDER BY transition_intensity_index DESC;

CREATE VIEW v_pathway_risk_profile AS
SELECT
  pathway,
  ROUND(demand_growth - efficiency_gain + transition_cost_factor - equity_support - ecological_constraint, 6) AS simple_risk_profile,
  demand_growth,
  efficiency_gain,
  transition_cost_factor,
  equity_support,
  ecological_constraint,
  description
FROM sustainability_pathways
ORDER BY simple_risk_profile DESC;

CREATE VIEW v_model_assumptions AS
SELECT * FROM model_assumptions ORDER BY assumption_id;

CREATE VIEW v_diagnostic_definitions AS
SELECT * FROM diagnostic_definitions ORDER BY diagnostic;

CREATE VIEW v_validation_targets AS
SELECT * FROM validation_targets ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_sustainability_pathways;
SELECT * FROM v_transition_intensity;
SELECT * FROM v_pathway_risk_profile;
SELECT * FROM v_model_assumptions;
SELECT * FROM v_diagnostic_definitions;
SELECT * FROM v_validation_targets;
