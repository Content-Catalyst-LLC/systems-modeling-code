-- ethics_power_systems_modeling_schema.sql
-- SQLite schema and analysis queries for ethics, power, and systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_stakeholder_diagnostics;
DROP VIEW IF EXISTS v_stakeholder_coverage_summary;
DROP VIEW IF EXISTS v_governance_register;
DROP VIEW IF EXISTS v_governance_status_summary;
DROP VIEW IF EXISTS v_model_use_risk_register;
DROP VIEW IF EXISTS v_boundary_power_questions;
DROP VIEW IF EXISTS v_model_safeguards;
DROP VIEW IF EXISTS v_misuse_patterns;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS misuse_patterns;
DROP TABLE IF EXISTS model_safeguards;
DROP TABLE IF EXISTS boundary_power_questions;
DROP TABLE IF EXISTS model_use_risks;
DROP TABLE IF EXISTS governance_register;
DROP TABLE IF EXISTS stakeholders;

CREATE TABLE stakeholders (
  stakeholder_group TEXT PRIMARY KEY,
  affected REAL NOT NULL,
  represented INTEGER NOT NULL,
  influence REAL NOT NULL,
  expected_benefit REAL NOT NULL,
  expected_burden REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE governance_register (
  item_id TEXT PRIMARY KEY,
  governance_item TEXT NOT NULL,
  status TEXT NOT NULL,
  ethical_risk_if_missing TEXT NOT NULL,
  responsible_practice TEXT NOT NULL
);

CREATE TABLE model_use_risks (
  risk_id TEXT PRIMARY KEY,
  risk_type TEXT NOT NULL,
  uncertainty REAL NOT NULL,
  consequence REAL NOT NULL,
  representation_gap REAL NOT NULL,
  misuse_potential REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE boundary_power_questions (
  question_id TEXT PRIMARY KEY,
  question TEXT NOT NULL,
  why_it_matters TEXT NOT NULL,
  review_output TEXT NOT NULL
);

CREATE TABLE model_safeguards (
  safeguard_id TEXT PRIMARY KEY,
  safeguard TEXT NOT NULL,
  purpose TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE misuse_patterns (
  pattern_id TEXT PRIMARY KEY,
  misuse_pattern TEXT NOT NULL,
  institutional_incentive TEXT NOT NULL,
  safeguard TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

INSERT INTO stakeholders VALUES
('public_agency', 0.40, 1, 0.95, 0.80, 0.20, 'High decision influence and institutional benefit'),
('technical_modelers', 0.20, 1, 0.85, 0.65, 0.15, 'High technical influence but lower direct exposure'),
('frontline_workers', 0.70, 1, 0.45, 0.55, 0.35, 'Operational knowledge with moderate influence and burden'),
('affected_residents', 0.95, 1, 0.35, 0.50, 0.60, 'High exposure and burden with limited influence'),
('low_access_households', 1.00, 0, 0.10, 0.35, 0.80, 'High burden and low representation in model governance'),
('future_generations', 0.90, 0, 0.00, 0.40, 0.75, 'Long horizon affected group with no direct representation'),
('local_environment', 0.85, 0, 0.05, 0.30, 0.70, 'Ecological burden represented weakly through institutional proxies');

INSERT INTO governance_register VALUES
('G1', 'boundary_review', 'partial', 'Excluded harms remain invisible', 'Document included and excluded system elements'),
('G2', 'assumption_register', 'complete', 'Hidden assumptions become institutional authority', 'Maintain reviewable assumption register'),
('G3', 'data_provenance_audit', 'partial', 'Data bias and missingness remain unchecked', 'Track sources collection rules missingness and transformations'),
('G4', 'distributional_review', 'needed', 'Aggregate results hide unequal burden', 'Report subgroup place-based and vulnerability outcomes'),
('G5', 'valid_use_statement', 'needed', 'Model outputs are used beyond scope', 'State valid and invalid model uses'),
('G6', 'appeal_and_correction_process', 'missing', 'Affected groups cannot challenge harmful outputs', 'Create review appeal correction and update process'),
('G7', 'stakeholder_review', 'partial', 'Model frame lacks affected knowledge', 'Review framing assumptions and outputs with affected groups'),
('G8', 'public_communication_protocol', 'needed', 'Caveats disappear in public summaries', 'Attach uncertainty and limits to all public outputs');

INSERT INTO model_use_risks VALUES
('R1', 'boundary_power', 0.75, 0.85, 0.60, 0.70, 'Boundary choices exclude affected causes or consequences'),
('R2', 'data_power', 0.65, 0.80, 0.50, 0.65, 'Data systems privilege institutional evidence over missing knowledge'),
('R3', 'proxy_bias', 0.70, 0.75, 0.70, 0.60, 'Measurable proxies fail to represent target concepts'),
('R4', 'false_certainty', 0.60, 0.70, 0.45, 0.80, 'Uncertainty is stripped from model outputs'),
('R5', 'authority_transfer', 0.80, 0.90, 0.65, 0.85, 'Human accountability is displaced onto the model'),
('R6', 'optimization_narrowing', 0.70, 0.80, 0.55, 0.75, 'Objective function hides values and tradeoffs'),
('R7', 'participation_tokenism', 0.75, 0.78, 0.80, 0.70, 'Stakeholders are consulted but cannot change model choices'),
('R8', 'surveillance_asymmetry', 0.68, 0.82, 0.72, 0.78, 'Some groups are measured more intensely than others');

INSERT INTO boundary_power_questions VALUES
('B1', 'who_defines_the_problem', 'Problem framing shapes model purpose and solution space', 'Document sponsor modeler and stakeholder roles'),
('B2', 'what_is_inside_the_model', 'Included variables receive analytical attention', 'List system elements included in scope'),
('B3', 'what_is_excluded', 'Excluded harms may disappear from decisions', 'Create exclusion log and review actions'),
('B4', 'whose_knowledge_counts', 'Formal data may displace lived local or operational knowledge', 'Document evidence sources and missing knowledge'),
('B5', 'what_outcomes_count', 'Metrics define success and failure', 'Publish outcome set and value tradeoffs'),
('B6', 'who_can_challenge_the_model', 'Contestability is required for accountability', 'Create review appeal and correction process');

INSERT INTO model_safeguards VALUES
('S1', 'assumption_register', 'makes model logic reviewable', 'important claims have no documented assumptions'),
('S2', 'exclusion_log', 'keeps boundaries visible', 'public outputs ignore what was excluded'),
('S3', 'data_provenance_record', 'makes data power visible', 'data sources are described only as available data'),
('S4', 'distributional_report', 'prevents average outcomes from hiding harm', 'only systemwide averages are reported'),
('S5', 'valid_use_statement', 'prevents validation overreach', 'model is used for a decision it was not designed for'),
('S6', 'stakeholder_review_log', 'documents how input changed or did not change the model', 'participation has no visible effect'),
('S7', 'uncertainty_attachment', 'prevents false certainty', 'model outputs travel without caveats'),
('S8', 'appeal_and_correction_process', 'preserves accountability after deployment', 'affected people cannot correct errors');

INSERT INTO misuse_patterns VALUES
('M1', 'model_as_justification', 'use technical output to support a decision already made', 'document timeline alternatives and dissent'),
('M2', 'model_as_shield', 'move accountability from decision makers to the model', 'require human decision ownership'),
('M3', 'selective_scenario_use', 'show only scenarios that support preferred policy', 'publish scenario selection criteria'),
('M4', 'uncertainty_suppression', 'create confidence for political or operational action', 'require uncertainty statements'),
('M5', 'metric_gaming', 'optimize what is measured instead of what matters', 'review proxies and unintended consequences'),
('M6', 'validation_overreach', 'use model outside tested scope', 'attach valid use and invalid use statements');

INSERT INTO validation_targets VALUES
('power_burden_gap', 0, 1, 'Power burden gap should remain normalized between zero and one for synthetic data'),
('ethical_risk_score', 0, 10, 'Ethical risk score should remain nonnegative and bounded for this synthetic workflow'),
('stakeholder_count', 1, 1000000, 'Stakeholder table should include at least one group'),
('governance_item_count', 1, 1000000, 'Governance register should include at least one item'),
('model_use_risk_count', 1, 1000000, 'Model use risk register should include at least one item'),
('safeguard_count', 1, 1000000, 'Safeguard table should include at least one safeguard');

CREATE VIEW v_stakeholder_diagnostics AS
SELECT
  stakeholder_group,
  affected,
  represented,
  influence,
  expected_benefit,
  expected_burden,
  ROUND(expected_benefit - expected_burden, 6) AS net_benefit,
  ROUND(expected_burden - expected_benefit, 6) AS burden_gap,
  ROUND(affected * expected_burden * (1 - influence), 6) AS power_burden_gap,
  CASE
    WHEN affected * expected_burden * (1 - influence) >= 0.45 THEN 'high_power_burden_gap'
    WHEN affected * expected_burden * (1 - influence) >= 0.20 THEN 'moderate_power_burden_gap'
    ELSE 'lower_power_burden_gap'
  END AS risk_label,
  description
FROM stakeholders
ORDER BY power_burden_gap DESC;

CREATE VIEW v_stakeholder_coverage_summary AS
SELECT 'stakeholder_groups' AS metric, COUNT(*) AS value FROM stakeholders
UNION ALL
SELECT 'affected_groups', SUM(CASE WHEN affected >= 0.50 THEN 1 ELSE 0 END) FROM stakeholders
UNION ALL
SELECT 'represented_groups', SUM(CASE WHEN represented = 1 THEN 1 ELSE 0 END) FROM stakeholders
UNION ALL
SELECT 'missing_or_unrepresented_groups', SUM(CASE WHEN represented = 0 THEN 1 ELSE 0 END) FROM stakeholders
UNION ALL
SELECT 'high_power_burden_gap_groups', SUM(CASE WHEN affected * expected_burden * (1 - influence) >= 0.45 THEN 1 ELSE 0 END) FROM stakeholders;

CREATE VIEW v_governance_register AS
SELECT item_id, governance_item, status, ethical_risk_if_missing, responsible_practice
FROM governance_register
ORDER BY item_id;

CREATE VIEW v_governance_status_summary AS
SELECT status, COUNT(*) AS governance_item_count
FROM governance_register
GROUP BY status
ORDER BY status;

CREATE VIEW v_model_use_risk_register AS
SELECT
  risk_id,
  risk_type,
  uncertainty,
  consequence,
  representation_gap,
  misuse_potential,
  ROUND(
    uncertainty * consequence * (1 + 0.50 * representation_gap) * (1 + 0.50 * misuse_potential),
    6
  ) AS ethical_risk_score,
  description
FROM model_use_risks
ORDER BY ethical_risk_score DESC;

CREATE VIEW v_boundary_power_questions AS
SELECT question_id, question, why_it_matters, review_output
FROM boundary_power_questions
ORDER BY question_id;

CREATE VIEW v_model_safeguards AS
SELECT safeguard_id, safeguard, purpose, warning_sign
FROM model_safeguards
ORDER BY safeguard_id;

CREATE VIEW v_misuse_patterns AS
SELECT pattern_id, misuse_pattern, institutional_incentive, safeguard
FROM misuse_patterns
ORDER BY pattern_id;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_stakeholder_diagnostics;
SELECT * FROM v_stakeholder_coverage_summary;
SELECT * FROM v_governance_register;
SELECT * FROM v_governance_status_summary;
SELECT * FROM v_model_use_risk_register;
SELECT * FROM v_boundary_power_questions;
SELECT * FROM v_model_safeguards;
SELECT * FROM v_misuse_patterns;
SELECT * FROM v_validation_targets;
