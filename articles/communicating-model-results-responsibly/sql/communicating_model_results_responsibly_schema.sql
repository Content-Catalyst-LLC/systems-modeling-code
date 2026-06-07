-- communicating_model_results_responsibly_schema.sql
-- SQLite schema and analysis queries for responsible model result communication.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_model_result_communication_diagnostics;
DROP VIEW IF EXISTS v_communication_controls;
DROP VIEW IF EXISTS v_communication_control_summary;
DROP VIEW IF EXISTS v_valid_use_register;
DROP VIEW IF EXISTS v_audience_briefing_needs;
DROP VIEW IF EXISTS v_visualization_safeguards;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS visualization_safeguards;
DROP TABLE IF EXISTS audience_briefing_needs;
DROP TABLE IF EXISTS valid_use_register;
DROP TABLE IF EXISTS communication_controls;
DROP TABLE IF EXISTS model_results;

CREATE TABLE model_results (
  result_id TEXT PRIMARY KEY,
  result_type TEXT NOT NULL,
  point_estimate REAL NOT NULL,
  lower_bound REAL NOT NULL,
  upper_bound REAL NOT NULL,
  assumption_disclosure REAL NOT NULL,
  uncertainty_disclosure REAL NOT NULL,
  boundary_disclosure REAL NOT NULL,
  misuse_warning REAL NOT NULL,
  plain_language_result TEXT NOT NULL
);

CREATE TABLE communication_controls (
  control_id TEXT PRIMARY KEY,
  control TEXT NOT NULL,
  present TEXT NOT NULL,
  risk_if_absent TEXT NOT NULL
);

CREATE TABLE valid_use_register (
  result_type TEXT PRIMARY KEY,
  valid_use TEXT NOT NULL,
  misuse_warning TEXT NOT NULL
);

CREATE TABLE audience_briefing_needs (
  audience TEXT PRIMARY KEY,
  needs TEXT NOT NULL,
  communication_risk TEXT NOT NULL
);

CREATE TABLE visualization_safeguards (
  visualization_type TEXT PRIMARY KEY,
  useful_for TEXT NOT NULL,
  responsible_requirement TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

INSERT INTO model_results VALUES
('R1','scenario',0.72,0.55,0.88,0.80,0.85,0.70,0.75,'Scenario A improves modeled reliability under stated assumptions'),
('R2','forecast',12000,9000,16000,0.60,0.75,0.55,0.60,'Demand is forecast to rise but the plausible range is wide'),
('R3','ranking',0.84,0.75,0.89,0.70,0.55,0.65,0.45,'Option B ranks highest under selected weights'),
('R4','map',0.67,0.40,0.82,0.45,0.40,0.50,0.40,'Mapped exposure is uneven but data coverage varies by location'),
('R5','optimization',0.91,0.80,0.96,0.65,0.60,0.60,0.55,'The optimized option performs best under the stated objective function'),
('R6','dashboard',0.78,0.62,0.86,0.55,0.50,0.55,0.35,'Dashboard indicators show current monitored state but not unmonitored conditions');

INSERT INTO communication_controls VALUES
('C1','state_model_purpose','true','Users may not understand what question the model answers'),
('C2','show_uncertainty_range','true','Point estimates may appear certain'),
('C3','summarize_key_assumptions','true','Conditional results may appear unconditional'),
('C4','label_scenarios_as_conditional','true','Scenarios may be mistaken for forecasts'),
('C5','publish_valid_use_statement','false','Model may be used beyond scope'),
('C6','attach_misuse_warning','false','Likely misuse may go unchallenged'),
('C7','show_data_age_and_quality','false','Dashboard polish may overstate credibility'),
('C8','report_distributional_effects','true','Average results may hide unequal burden');

INSERT INTO valid_use_register VALUES
('scenario','Compare conditional outcomes under stated assumptions','Do not present scenarios as predictions'),
('forecast','Estimate expected conditions within the validated operating domain','Do not ignore uncertainty ranges or structural change'),
('ranking','Support prioritization for review','Do not treat small score differences as decisive without sensitivity analysis'),
('map','Show spatial patterns at the stated resolution','Do not infer precision below the data resolution'),
('optimization','Compare options under stated objectives and constraints','Do not treat the objective function as a complete value judgment'),
('dashboard','Monitor current conditions and flag anomalies','Do not assume unmonitored conditions are safe or irrelevant');

INSERT INTO audience_briefing_needs VALUES
('modeling_team','technical documentation assumptions validation code data sensitivity uncertainty','technical detail may obscure decision relevance'),
('decision_makers','purpose options tradeoffs uncertainty limitations valid uses implementation risks','caveats may be compressed into an overly simple recommendation'),
('stakeholders','plain language assumptions boundaries consequences contestability distributional effects','communication may become symbolic rather than meaningful'),
('public_audiences','what the model says what it does not say why it matters and who remains accountable','headlines may turn conditional results into certainty'),
('auditors_and_reviewers','data provenance reproducibility validation governance versioning misuse controls','documentation may be incomplete or inaccessible'),
('operators_and_implementers','action thresholds exceptions monitoring rules update conditions escalation procedures','users may apply outputs mechanically without judgment');

INSERT INTO visualization_safeguards VALUES
('line_chart','time trends forecasts scenarios oscillations accumulation','show uncertainty bands scenario labels and time horizon'),
('fan_chart','increasing uncertainty over time','explain what the bands represent and what is excluded'),
('scenario_comparison','comparing interventions or futures','state assumptions defining each scenario'),
('sensitivity_tornado','showing which assumptions drive outputs','use clear parameter labels and explain tested ranges'),
('map','spatial exposure access risk vulnerability service gaps','show resolution missing data uncertainty and aggregation limits'),
('network_diagram','dependencies flows contagion centrality cascading risk','explain what edges mean and what relationships are missing'),
('ranking_table','prioritization and comparison','show confidence ties score differences and sensitivity to weights'),
('dashboard','monitoring and repeated use','attach data age update frequency validation status and misuse warnings');

INSERT INTO validation_targets VALUES
('communication_quality_score', 0, 1, 'Communication quality score should remain normalized between zero and one'),
('uncertainty_width', 0, 1000000, 'Uncertainty width should be nonnegative'),
('result_count', 1, 1000000, 'Workflow should include at least one model result'),
('control_count', 1, 1000000, 'Communication controls should include at least one control'),
('valid_use_count', 1, 1000000, 'Valid-use register should include at least one result type'),
('visualization_safeguard_count', 1, 1000000, 'Visualization safeguards should include at least one safeguard');

CREATE VIEW v_model_result_communication_diagnostics AS
SELECT
  result_id,
  result_type,
  point_estimate,
  lower_bound,
  upper_bound,
  ROUND(upper_bound - lower_bound, 6) AS uncertainty_width,
  ROUND(
    0.30 * assumption_disclosure +
    0.30 * uncertainty_disclosure +
    0.20 * boundary_disclosure +
    0.20 * misuse_warning,
    6
  ) AS communication_quality_score,
  CASE
    WHEN uncertainty_disclosure < 0.60 AND (upper_bound - lower_bound) > 0.20 THEN 'high_false_precision_risk'
    WHEN uncertainty_disclosure < 0.70 THEN 'moderate_false_precision_risk'
    ELSE 'lower_false_precision_risk'
  END AS false_precision_risk,
  plain_language_result
FROM model_results
ORDER BY communication_quality_score ASC;

CREATE VIEW v_communication_controls AS
SELECT control_id, control, present, risk_if_absent
FROM communication_controls
ORDER BY control_id;

CREATE VIEW v_communication_control_summary AS
SELECT 'communication_controls' AS metric, COUNT(*) AS value FROM communication_controls
UNION ALL
SELECT 'present_controls', SUM(CASE WHEN present = 'true' THEN 1 ELSE 0 END) FROM communication_controls
UNION ALL
SELECT 'missing_controls', SUM(CASE WHEN present != 'true' THEN 1 ELSE 0 END) FROM communication_controls;

CREATE VIEW v_valid_use_register AS
SELECT result_type, valid_use, misuse_warning
FROM valid_use_register
ORDER BY result_type;

CREATE VIEW v_audience_briefing_needs AS
SELECT audience, needs, communication_risk
FROM audience_briefing_needs
ORDER BY audience;

CREATE VIEW v_visualization_safeguards AS
SELECT visualization_type, useful_for, responsible_requirement
FROM visualization_safeguards
ORDER BY visualization_type;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_model_result_communication_diagnostics;
SELECT * FROM v_communication_controls;
SELECT * FROM v_communication_control_summary;
SELECT * FROM v_valid_use_register;
SELECT * FROM v_audience_briefing_needs;
SELECT * FROM v_visualization_safeguards;
SELECT * FROM v_validation_targets;
