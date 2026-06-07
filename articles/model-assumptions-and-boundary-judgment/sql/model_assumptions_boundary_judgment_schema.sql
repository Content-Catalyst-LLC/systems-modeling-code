-- model_assumptions_boundary_judgment_schema.sql
-- SQLite schema and analysis queries for model assumptions and boundary judgment.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_assumption_register;
DROP VIEW IF EXISTS v_assumption_risk_summary;
DROP VIEW IF EXISTS v_boundary_scenario_comparison;
DROP VIEW IF EXISTS v_exclusion_log;
DROP VIEW IF EXISTS v_boundary_critique_questions;
DROP VIEW IF EXISTS v_evidence_strength;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS evidence_strength;
DROP TABLE IF EXISTS boundary_critique_questions;
DROP TABLE IF EXISTS exclusion_log;
DROP TABLE IF EXISTS boundary_scenarios;
DROP TABLE IF EXISTS assumption_register;

CREATE TABLE assumption_register (
  assumption_id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  assumption TEXT NOT NULL,
  source TEXT NOT NULL,
  uncertainty REAL NOT NULL,
  sensitivity REAL NOT NULL,
  consequence REAL NOT NULL,
  review_status TEXT NOT NULL
);

CREATE TABLE boundary_scenarios (
  boundary TEXT PRIMARY KEY,
  capital_cost REAL NOT NULL,
  service_reliability REAL NOT NULL,
  equity_performance REAL NOT NULL,
  long_term_resilience REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE exclusion_log (
  exclusion_id TEXT PRIMARY KEY,
  excluded_element TEXT NOT NULL,
  reason_for_exclusion TEXT NOT NULL,
  risk_if_exclusion_is_wrong TEXT NOT NULL,
  review_action TEXT NOT NULL
);

CREATE TABLE boundary_critique_questions (
  question_id TEXT PRIMARY KEY,
  boundary_question TEXT NOT NULL,
  why_it_matters TEXT NOT NULL,
  example TEXT NOT NULL
);

CREATE TABLE evidence_strength (
  evidence_level TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  appropriate_use TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

INSERT INTO assumption_register VALUES
('A1', 'boundary', 'Community disruption is outside the core infrastructure boundary', 'model_scope_choice', 0.80, 0.75, 0.90, 'needs_stakeholder_review'),
('A2', 'data', 'Inspection records are representative of true asset condition', 'administrative_data', 0.55, 0.60, 0.70, 'needs_data_audit'),
('A3', 'parameter', 'Annual degradation rate remains stable', 'historical_calibration', 0.40, 0.85, 0.65, 'documented'),
('A4', 'behavioral', 'Users comply with service changes after implementation', 'implementation_assumption', 0.70, 0.50, 0.60, 'contested'),
('A5', 'scenario', 'Extreme rainfall increases by twenty percent', 'stress_scenario', 0.65, 0.80, 0.85, 'documented'),
('A6', 'normative', 'Cost minimization is weighted more heavily than distributional equity', 'objective_function_choice', 0.75, 0.90, 0.95, 'contested'),
('A7', 'scale', 'Annual time steps adequately represent disruption and recovery', 'time_resolution_choice', 0.50, 0.65, 0.75, 'needs_review'),
('A8', 'causal', 'Deferred maintenance increases failure probability nonlinearly', 'expert_judgment', 0.45, 0.80, 0.80, 'documented'),
('A9', 'measurement', 'Service reliability can stand in for lived service continuity', 'proxy_variable_choice', 0.70, 0.70, 0.85, 'needs_stakeholder_review');

INSERT INTO boundary_scenarios VALUES
('narrow_asset_boundary', 0.80, 0.60, 0.35, 0.50, 'Focuses on asset condition cost and reliability while excluding community disruption'),
('expanded_service_boundary', 0.72, 0.75, 0.55, 0.65, 'Adds service continuity and operational disruption to the modeled boundary'),
('community_resilience_boundary', 0.65, 0.78, 0.85, 0.78, 'Adds distributional impacts access barriers and community recovery to the model'),
('long_horizon_boundary', 0.60, 0.82, 0.70, 0.90, 'Extends time horizon to include delayed degradation adaptation and resilience effects'),
('multi_stakeholder_boundary', 0.62, 0.76, 0.88, 0.82, 'Includes stakeholder-defined outcomes and contested assumptions');

INSERT INTO exclusion_log VALUES
('E1', 'informal_care_and_unpaid_labor', 'no_consistent_quantitative_dataset', 'understates_household_burden_and_recovery_constraints', 'review_with_affected_groups'),
('E2', 'political_delay_in_implementation', 'scenario_scope_simplification', 'overstates_speed_and_feasibility_of_intervention', 'test_with_delayed_implementation_scenario'),
('E3', 'localized_neighborhood_hotspots', 'aggregate_spatial_resolution', 'misses_distributional_risk_and_place_based_harm', 'compare_with_finer_spatial_boundary'),
('E4', 'trust_and_institutional_legitimacy', 'difficult_to_quantify', 'overstates_compliance_and_public_acceptance', 'include_qualitative_boundary_review'),
('E5', 'long_term_ecological_externalities', 'outside_current_project_scope', 'understates_delayed_environmental_consequences', 'add_expanded_boundary_scenario');

INSERT INTO boundary_critique_questions VALUES
('BQ1', 'Who_is_the_model_for', 'the_sponsor_purpose_may_not_match_public_or_stakeholder_needs', 'a_utility_model_prioritizes_asset_protection_over_household_service_continuity'),
('BQ2', 'Who_is_affected', 'affected_groups_may_not_have_decision_authority', 'residents_bear_flood_risk_from_infrastructure_choices_they_did_not_shape'),
('BQ3', 'Whose_knowledge_counts', 'formal_data_may_exclude_lived_local_or_indigenous_knowledge', 'community_flood_observations_are_absent_from_official_datasets'),
('BQ4', 'What_outcomes_count', 'metrics_shape_what_success_means', 'a_transit_model_optimizes_speed_but_ignores_affordability_and_accessibility'),
('BQ5', 'What_is_treated_as_external', 'externalizing_harms_can_make_an_option_look_better_than_it_is', 'industrial_cost_models_exclude_pollution_exposure_or_ecosystem_damage'),
('BQ6', 'Who_can_challenge_the_model', 'models_can_become_tools_of_authority_if_assumptions_are_not_contestable', 'communities_are_told_the_model_proves_an_outcome_without_inspection_rights');

INSERT INTO evidence_strength VALUES
('strong', 'multiple_independent_sources_support_the_assumption', 'use_for_core_model_structure_with_documented_uncertainty', 'still_requires_context_and_boundary_review'),
('moderate', 'some_empirical_or_expert_support_but_context_limits_remain', 'use_with_sensitivity_testing_and_documentation', 'treated_as_settled_fact_without_review'),
('weak', 'limited_evidence_or_high_transfer_uncertainty', 'use_only_with_explicit_caveats_and_stress_testing', 'drives_decision_without_alternative_scenarios'),
('contested', 'stakeholders_or_sources_disagree_about_the_assumption', 'represent_as_alternative_scenarios_or_contested_boundary', 'forced_consensus_hides_disagreement'),
('unknown', 'insufficient_evidence_to_assess_confidence', 'use_as_research_gap_not_decision_anchor', 'presented_with_false_precision');

INSERT INTO validation_targets VALUES
('risk_score', 0, 1, 'Assumption risk should remain in the unit interval'),
('composite_score', 0, 1, 'Boundary scenario score should remain in the unit interval'),
('assumption_count', 1, 1000000, 'Assumption register should include at least one assumption'),
('boundary_count', 1, 1000000, 'Boundary scenario comparison should include at least one boundary'),
('high_risk_count', 0, 1000000, 'High risk assumption count should be nonnegative'),
('exclusion_count', 1, 1000000, 'Exclusion log should include at least one entry');

CREATE VIEW v_assumption_register AS
SELECT
  assumption_id,
  category,
  assumption,
  source,
  uncertainty,
  sensitivity,
  consequence,
  ROUND(uncertainty * sensitivity * consequence, 6) AS risk_score,
  CASE
    WHEN uncertainty * sensitivity * consequence >= 0.45 THEN 'high'
    WHEN uncertainty * sensitivity * consequence >= 0.25 THEN 'moderate'
    ELSE 'lower'
  END AS risk_label,
  review_status
FROM assumption_register
ORDER BY risk_score DESC;

CREATE VIEW v_assumption_risk_summary AS
SELECT
  category,
  COUNT(*) AS assumption_count,
  ROUND(AVG(uncertainty * sensitivity * consequence), 6) AS average_risk_score,
  SUM(CASE WHEN uncertainty * sensitivity * consequence >= 0.45 THEN 1 ELSE 0 END) AS high_risk_count
FROM assumption_register
GROUP BY category
ORDER BY average_risk_score DESC;

CREATE VIEW v_boundary_scenario_comparison AS
SELECT
  boundary,
  capital_cost,
  service_reliability,
  equity_performance,
  long_term_resilience,
  ROUND(
    0.20 * capital_cost +
    0.30 * service_reliability +
    0.25 * equity_performance +
    0.25 * long_term_resilience,
    6
  ) AS composite_score,
  description
FROM boundary_scenarios
ORDER BY composite_score DESC;

CREATE VIEW v_exclusion_log AS
SELECT exclusion_id, excluded_element, reason_for_exclusion, risk_if_exclusion_is_wrong, review_action
FROM exclusion_log
ORDER BY exclusion_id;

CREATE VIEW v_boundary_critique_questions AS
SELECT question_id, boundary_question, why_it_matters, example
FROM boundary_critique_questions
ORDER BY question_id;

CREATE VIEW v_evidence_strength AS
SELECT evidence_level, description, appropriate_use, warning_sign
FROM evidence_strength
ORDER BY
  CASE evidence_level
    WHEN 'strong' THEN 1
    WHEN 'moderate' THEN 2
    WHEN 'weak' THEN 3
    WHEN 'contested' THEN 4
    WHEN 'unknown' THEN 5
    ELSE 99
  END;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_assumption_register;
SELECT * FROM v_assumption_risk_summary;
SELECT * FROM v_boundary_scenario_comparison;
SELECT * FROM v_exclusion_log;
SELECT * FROM v_boundary_critique_questions;
SELECT * FROM v_evidence_strength;
SELECT * FROM v_validation_targets;
