-- future_directions_systems_modeling_schema.sql
-- SQLite schema and diagnostics for future-facing adaptive systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_adaptive_monitoring_seed;
DROP VIEW IF EXISTS v_model_governance_controls;
DROP VIEW IF EXISTS v_future_capability_register;
DROP VIEW IF EXISTS v_adaptive_triggers;
DROP VIEW IF EXISTS v_validation_targets;
DROP VIEW IF EXISTS v_seed_diagnostics;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS adaptive_triggers;
DROP TABLE IF EXISTS future_capability_register;
DROP TABLE IF EXISTS model_governance_controls;
DROP TABLE IF EXISTS adaptive_monitoring_seed;

CREATE TABLE adaptive_monitoring_seed (
  time INTEGER PRIMARY KEY,
  baseline_load REAL NOT NULL,
  observed_load REAL NOT NULL,
  capacity REAL NOT NULL,
  shock_flag INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE model_governance_controls (
  control_id TEXT PRIMARY KEY,
  control TEXT NOT NULL,
  purpose TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE future_capability_register (
  capability_id TEXT PRIMARY KEY,
  capability TEXT NOT NULL,
  systems_modeling_role TEXT NOT NULL,
  governance_requirement TEXT NOT NULL
);

CREATE TABLE adaptive_triggers (
  trigger_id TEXT PRIMARY KEY,
  trigger_condition TEXT NOT NULL,
  action TEXT NOT NULL,
  governance_note TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

INSERT INTO adaptive_monitoring_seed VALUES
(0,12.0,12.2,18.0,0,'Initial monitored system state'),
(1,11.7,12.4,18.0,0,'Normal operating condition'),
(2,11.3,11.9,18.0,0,'Normal operating condition'),
(3,10.9,11.6,18.0,0,'Normal operating condition'),
(4,10.5,11.2,18.0,0,'Normal operating condition'),
(5,10.1,10.7,18.0,0,'Normal operating condition'),
(6,9.7,10.5,18.0,0,'Normal operating condition'),
(7,9.4,9.9,18.0,0,'Normal operating condition'),
(8,9.1,9.6,18.0,0,'Normal operating condition'),
(9,8.8,9.2,18.0,0,'Normal operating condition'),
(10,8.6,14.4,18.0,1,'Shock observation requiring monitoring review'),
(11,8.4,12.7,18.0,1,'Post shock elevated observation'),
(12,8.2,10.8,18.0,0,'Recovery observation');

INSERT INTO model_governance_controls VALUES
('G1','data_provenance_record','tracks source and transformation of data streams','observations appear without source or quality metadata'),
('G2','drift_monitoring','detects model performance degradation','error rises without review trigger'),
('G3','valid_use_statement','limits unsupported model use','operational outputs are reused for policy decisions without review'),
('G4','security_review','protects connected model infrastructure','model connects to operational systems without access controls'),
('G5','uncertainty_display','prevents false precision','dashboard shows point estimates without range or confidence'),
('G6','human_override_log','preserves accountability','automated recommendations cannot be challenged or overridden'),
('G7','stakeholder_review','checks boundary and consequence assumptions','affected groups cannot inspect model purpose or outputs'),
('G8','model_retirement_rule','defines when the model should be suspended or replaced','known model drift does not change model use');

INSERT INTO future_capability_register VALUES
('C1','streaming_state_estimation','updates beliefs about current system state','data quality and drift monitoring'),
('C2','digital_twin_monitoring','connects model outputs to live system observations','security validation and operational safeguards'),
('C3','hybrid_ai_simulation','combines mechanistic models with data-driven residual learning','interpretability and validation by operating domain'),
('C4','model_ensembles','compares outputs across structures and assumptions','transparent uncertainty and disagreement reporting'),
('C5','adaptive_governance','links monitoring to policy revision','decision records and stakeholder accountability'),
('C6','scenario_stress_testing','tests futures shocks and boundary conditions','clear scenario framing and misuse warnings'),
('C7','interoperable_model_ecosystems','links submodels across domains','version control standards and provenance'),
('C8','public_facing_model_communication','makes assumptions and uncertainty legible','plain language documentation and appeal pathways');

INSERT INTO adaptive_triggers VALUES
('T1','residual_greater_than_3','flag anomaly and require review','avoid automatic intervention without human review'),
('T2','rolling_error_greater_than_2','open model drift investigation','check data pipeline and parameter assumptions'),
('T3','capacity_margin_below_2','stress test immediate intervention pathways','include uncertainty and service consequences'),
('T4','shock_flag_equals_1','run post shock validation check','compare model forecast with observed recovery'),
('T5','three_consecutive_interventions','escalate to governance board','review whether model is controlling too much operational behavior'),
('T6','missing_data_rate_above_10_percent','suspend automated recommendations','document data gaps and restore data integrity');

INSERT INTO validation_targets VALUES
('absolute_error_observed',0,1000000,'Observed absolute error should be nonnegative'),
('absolute_error_estimated',0,1000000,'Estimated absolute error should be nonnegative'),
('drift_indicator',0,1000000,'Drift indicator should be nonnegative'),
('intervention_flag',0,1,'Intervention flag should remain binary'),
('time_steps',1,1000000,'Workflow should include at least one time step'),
('governance_controls',1,1000000,'Governance table should include at least one control');

CREATE VIEW v_adaptive_monitoring_seed AS
SELECT
  time,
  baseline_load,
  observed_load,
  capacity,
  ROUND(capacity - observed_load, 6) AS capacity_margin,
  ROUND(ABS(observed_load - baseline_load), 6) AS residual,
  CASE
    WHEN ABS(observed_load - baseline_load) > 3 THEN 1
    ELSE 0
  END AS anomaly_flag,
  shock_flag,
  description
FROM adaptive_monitoring_seed
ORDER BY time;

CREATE VIEW v_seed_diagnostics AS
SELECT
  COUNT(*) AS time_steps,
  ROUND(AVG(ABS(observed_load - baseline_load)), 6) AS average_residual,
  ROUND(MAX(ABS(observed_load - baseline_load)), 6) AS max_residual,
  SUM(CASE WHEN ABS(observed_load - baseline_load) > 3 THEN 1 ELSE 0 END) AS anomaly_count,
  SUM(shock_flag) AS shock_count,
  ROUND(MIN(capacity - observed_load), 6) AS minimum_capacity_margin
FROM adaptive_monitoring_seed;

CREATE VIEW v_model_governance_controls AS
SELECT control_id, control, purpose, warning_sign
FROM model_governance_controls
ORDER BY control_id;

CREATE VIEW v_future_capability_register AS
SELECT capability_id, capability, systems_modeling_role, governance_requirement
FROM future_capability_register
ORDER BY capability_id;

CREATE VIEW v_adaptive_triggers AS
SELECT trigger_id, trigger_condition, action, governance_note
FROM adaptive_triggers
ORDER BY trigger_id;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_adaptive_monitoring_seed;
SELECT * FROM v_seed_diagnostics;
SELECT * FROM v_model_governance_controls;
SELECT * FROM v_future_capability_register;
SELECT * FROM v_adaptive_triggers;
SELECT * FROM v_validation_targets;
