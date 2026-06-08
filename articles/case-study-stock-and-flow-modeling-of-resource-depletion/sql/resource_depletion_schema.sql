-- resource_depletion_schema.sql
-- SQLite schema and scenario queries for stock-and-flow resource depletion.

DROP VIEW IF EXISTS v_scenario_summary;
DROP VIEW IF EXISTS v_scenarios;
DROP VIEW IF EXISTS v_assumptions;
DROP VIEW IF EXISTS v_diagnostics;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS diagnostic_definitions;
DROP TABLE IF EXISTS model_assumptions;
DROP TABLE IF EXISTS scenario_parameters;

CREATE TABLE scenario_parameters (
  scenario TEXT PRIMARY KEY,
  periods INTEGER NOT NULL,
  carrying_capacity REAL NOT NULL,
  initial_stock REAL NOT NULL,
  regeneration_rate REAL NOT NULL,
  initial_demand REAL NOT NULL,
  demand_growth REAL NOT NULL,
  extraction_efficiency REAL NOT NULL,
  conservation_sensitivity REAL NOT NULL,
  max_conservation REAL NOT NULL,
  reference_stock_fraction REAL NOT NULL,
  critical_threshold_fraction REAL NOT NULL,
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

INSERT INTO scenario_parameters VALUES
('baseline',80,100,80,0.080,4.0,0.015,0.120,0.45,0.35,0.70,0.20,'Moderate demand growth and moderate conservation response'),
('high_demand',80,100,80,0.080,4.0,0.035,0.120,0.45,0.35,0.70,0.20,'Demand growth accelerates extraction pressure'),
('conservation',80,100,80,0.080,4.0,0.015,0.120,0.85,0.55,0.70,0.20,'Scarcity response is stronger and conservation cap is higher'),
('technology_rebound',80,100,80,0.080,4.0,0.030,0.180,0.35,0.30,0.70,0.20,'Efficiency increases extraction capacity while demand rebounds'),
('regeneration_stress',80,100,80,0.045,4.0,0.015,0.120,0.45,0.35,0.70,0.20,'Regeneration rate falls under environmental stress'),
('delayed_governance',80,100,80,0.080,4.0,0.025,0.120,0.20,0.20,0.70,0.20,'Governance response is weak and late under rising demand');

INSERT INTO model_assumptions VALUES
('A1','Resource can be represented as one aggregate stock','boundary','Local depletion may be hidden','Add spatial sub-stocks for applied use'),
('A2','Regeneration follows logistic growth','structure','Recovery may be overestimated or underestimated','Compare alternative regeneration functions'),
('A3','Demand grows exponentially within each scenario','demand','Real demand may shift due to price policy substitution or shocks','Test demand sensitivity and sector-specific demand'),
('A4','Conservation response rises with scarcity','behavior','Policy response may be delayed weak contested or inequitable','Represent implementation delay and governance capacity'),
('A5','Extraction is limited by demand and available stock','flow','Technology may sustain high extraction deeper into depletion','Test extraction efficiency and rebound scenarios'),
('A6','Critical threshold is twenty percent of carrying capacity','threshold','Real collapse threshold may be unknown nonlinear or context-specific','Test multiple threshold values'),
('A7','No equity or livelihood distribution is modeled','boundary','Policy interpretation may hide unequal burden','Add stakeholder groups and distributional metrics');

INSERT INTO diagnostic_definitions VALUES
('final_stock','Resource stock at the end of the simulation','Shows long-run resource condition'),
('minimum_stock','Lowest resource stock reached during the run','Shows near-collapse or severe depletion risk'),
('depletion_ratio','Fraction of initial stock lost by final period','Summarizes stock loss'),
('cumulative_extraction','Total extracted resource across all periods','Shows production or harvest volume'),
('cumulative_regeneration','Total regeneration across all periods','Shows renewal contribution'),
('cumulative_unmet_demand','Total demand not satisfied by extraction','Shows scarcity disruption'),
('threshold_crossing_time','First period when stock falls below critical threshold','Supports early warning and intervention timing'),
('overshoot_periods','Number of periods where extraction exceeds regeneration','Shows persistence of unsustainable imbalance');

INSERT INTO validation_targets VALUES
('resource_stock',0,1000000,'Resource stock should remain nonnegative'),
('extraction',0,1000000,'Extraction should remain nonnegative'),
('regeneration',0,1000000,'Regeneration should remain nonnegative'),
('depletion_ratio',-1000000,1,'Depletion ratio should not exceed one when final stock is nonnegative'),
('scenario_count',1,1000000,'Workflow should include at least one scenario'),
('threshold_crossing_time',0,1000000,'Threshold crossing time should be nonnegative when crossed');

CREATE VIEW v_scenarios AS
SELECT * FROM scenario_parameters ORDER BY scenario;

CREATE VIEW v_scenario_summary AS
SELECT
  scenario,
  initial_stock,
  regeneration_rate,
  demand_growth,
  extraction_efficiency,
  conservation_sensitivity,
  max_conservation,
  ROUND(initial_stock / carrying_capacity, 6) AS initial_stock_fraction,
  ROUND(critical_threshold_fraction * carrying_capacity, 6) AS critical_threshold,
  description
FROM scenario_parameters
ORDER BY scenario;

CREATE VIEW v_assumptions AS
SELECT * FROM model_assumptions ORDER BY assumption_id;

CREATE VIEW v_diagnostics AS
SELECT * FROM diagnostic_definitions ORDER BY diagnostic;

CREATE VIEW v_validation_targets AS
SELECT * FROM validation_targets ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_scenario_summary;
SELECT * FROM v_assumptions;
SELECT * FROM v_diagnostics;
SELECT * FROM v_validation_targets;
