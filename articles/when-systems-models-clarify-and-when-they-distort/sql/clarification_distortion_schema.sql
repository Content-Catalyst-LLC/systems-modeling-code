-- clarification_distortion_schema.sql
-- SQLite schema and analysis queries for when systems models clarify and when they distort.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_model_cases_scored;
DROP VIEW IF EXISTS v_use_label_summary;
DROP VIEW IF EXISTS v_risk_register;
DROP VIEW IF EXISTS v_communication_controls;
DROP VIEW IF EXISTS v_use_scope_register;
DROP VIEW IF EXISTS v_distortion_patterns;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS distortion_patterns;
DROP TABLE IF EXISTS use_scope_register;
DROP TABLE IF EXISTS communication_controls;
DROP TABLE IF EXISTS risk_register;
DROP TABLE IF EXISTS model_cases;

CREATE TABLE model_cases (
  model_case TEXT PRIMARY KEY,
  structural_clarity REAL NOT NULL,
  dynamic_clarity REAL NOT NULL,
  scenario_clarity REAL NOT NULL,
  assumption_transparency REAL NOT NULL,
  false_precision_risk REAL NOT NULL,
  boundary_risk REAL NOT NULL,
  proxy_risk REAL NOT NULL,
  misuse_risk REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE risk_register (
  risk_id TEXT PRIMARY KEY,
  risk_type TEXT NOT NULL,
  description TEXT NOT NULL,
  mitigation TEXT NOT NULL
);

CREATE TABLE communication_controls (
  control_id TEXT PRIMARY KEY,
  communication_control TEXT NOT NULL,
  purpose TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE use_scope_register (
  scope_id TEXT PRIMARY KEY,
  use_case TEXT NOT NULL,
  valid_use TEXT NOT NULL,
  invalid_use TEXT NOT NULL,
  review_requirement TEXT NOT NULL
);

CREATE TABLE distortion_patterns (
  pattern_id TEXT PRIMARY KEY,
  distortion_pattern TEXT NOT NULL,
  how_it_distorts TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

INSERT INTO model_cases VALUES
('infrastructure_resilience_model', 0.85, 0.70, 0.80, 0.65, 0.45, 0.65, 0.45, 0.50, 'Clarifies asset condition failure risk and maintenance priorities but may understate community disruption'),
('public_health_capacity_model', 0.75, 0.85, 0.70, 0.60, 0.55, 0.70, 0.55, 0.65, 'Clarifies capacity demand staffing and intervention timing but may miss access barriers and trust'),
('urban_accessibility_model', 0.70, 0.50, 0.60, 0.70, 0.60, 0.75, 0.70, 0.55, 'Clarifies location and service reach but can distort lived accessibility with weak proxies'),
('energy_transition_pathway_model', 0.80, 0.80, 0.85, 0.55, 0.50, 0.65, 0.50, 0.60, 'Clarifies emissions technology and cost pathways but may hide justice land and political constraints'),
('machine_learning_risk_model', 0.45, 0.40, 0.35, 0.35, 0.85, 0.70, 0.85, 0.90, 'Clarifies predictive patterns but may distort causality explanation and accountability'),
('digital_twin_operations_model', 0.75, 0.65, 0.70, 0.50, 0.70, 0.60, 0.50, 0.75, 'Clarifies live operations and anomalies but may overstate monitored reality and operational authority');

INSERT INTO risk_register VALUES
('R1', 'false_precision', 'Outputs appear more precise than evidence supports', 'Report ranges sensitivity uncertainty and scenario conditions'),
('R2', 'boundary_error', 'Important consequences are outside the model boundary', 'Test expanded boundaries and maintain exclusion logs'),
('R3', 'proxy_distortion', 'Measured variables do not adequately represent target concepts', 'Document proxies and compare alternative measures'),
('R4', 'scenario_framing', 'Scenario choices narrow the range of imaginable futures', 'Include stakeholder generated adverse and structurally different scenarios'),
('R5', 'optimization_narrowing', 'Objective function hides values and tradeoffs', 'Use multi criteria review and distributional diagnostics'),
('R6', 'authority_transfer', 'Decision responsibility is displaced onto the model', 'State human judgment values and accountability explicitly'),
('R7', 'communication_collapse', 'Caveats disappear when model results move into slides dashboards or executive summaries', 'Keep uncertainty and valid use statements attached to outputs'),
('R8', 'validation_overreach', 'A model validated for one use is applied to another use', 'Publish a scope of use statement and prohibit unsupported uses');

INSERT INTO communication_controls VALUES
('C1', 'show_uncertainty_ranges', 'prevents_single_number_false_precision', 'headline_contains_one_exact_prediction'),
('C2', 'label_scenarios_as_conditional', 'prevents_scenarios_from_becoming_forecasts', 'scenario_output_is_described_as_what_will_happen'),
('C3', 'include_valid_use_statement', 'keeps_interpretation_within_scope', 'model_is_used_for_a_decision_it_was_not_designed_for'),
('C4', 'show_component_scores', 'prevents_composite_index_opacity', 'one_score_hides_weights_and_proxies'),
('C5', 'document_data_age_and_quality', 'prevents_dashboard_polish_from_overstating_credibility', 'users_assume_live_display_means_complete_truth'),
('C6', 'identify_human_decision_authority', 'prevents_authority_transfer_to_the_model', 'decision_makers_say_the_model_decided');

INSERT INTO use_scope_register VALUES
('S1', 'scenario_exploration', 'compare_conditional_outcomes_under_explicit_assumptions', 'predict_exact_future_outcomes', 'review_scenario_assumptions_and_uncertainty'),
('S2', 'operational_monitoring', 'flag_anomalies_and_support_operator_attention', 'automatically_assign_accountability_or_blame', 'review_sensor_quality_and_procedure'),
('S3', 'policy_screening', 'identify_promising_options_for_further_review', 'make_final_policy_decisions_without_deliberation', 'review_boundary_equity_and_distributional_effects'),
('S4', 'risk_ranking', 'prioritize_cases_for_human_review', 'deny_services_or_resources_without_appeal', 'review_bias_uncertainty_and_appeal_process'),
('S5', 'optimization', 'compare_tradeoffs_under_stated_objectives', 'treat_objective_function_as_public_value_consensus', 'review_weights_constraints_and_stakeholder_values');

INSERT INTO distortion_patterns VALUES
('D1', 'false_precision', 'turns_conditional_estimates_into_apparent_certainty', 'are_uncertainty_ranges_visible'),
('D2', 'boundary_error', 'excludes_relevant_causes_consequences_or_groups', 'what_is_outside_the_model_boundary'),
('D3', 'proxy_substitution', 'treats_a_measurable_proxy_as_the_target_concept', 'what_does_the_proxy_fail_to_measure'),
('D4', 'mechanism_loss', 'removes_the_process_that_drives_system_behavior', 'does_the_model_preserve_the_driver_of_the_problem'),
('D5', 'scenario_narrowing', 'limits_imagination_to_sponsor_preferred_futures', 'who_selected_the_scenarios'),
('D6', 'optimization_tunnel_vision', 'turns_a_value_choice_into_a_technical_target', 'what_outcomes_are_not_in_the_objective_function'),
('D7', 'validation_overreach', 'applies_a_model_beyond_its_tested_purpose', 'valid_for_what_use'),
('D8', 'communication_collapse', 'strips_caveats_when_results_are_summarized', 'do_caveats_travel_with_outputs');

INSERT INTO validation_targets VALUES
('clarification_score', 0, 1, 'Clarification score should remain normalized between zero and one'),
('distortion_risk_score', 0, 1, 'Distortion risk score should remain normalized between zero and one'),
('net_interpretive_value', -1, 1, 'Net interpretive value can be negative when distortion risk exceeds clarification value'),
('model_case_count', 1, 1000000, 'Workflow should include at least one model case'),
('risk_register_count', 1, 1000000, 'Risk register should include at least one risk'),
('communication_control_count', 1, 1000000, 'Communication controls should include at least one control');

CREATE VIEW v_model_cases_scored AS
SELECT
  model_case,
  ROUND(
    0.30 * structural_clarity +
    0.25 * dynamic_clarity +
    0.25 * scenario_clarity +
    0.20 * assumption_transparency,
    6
  ) AS clarification_score,
  ROUND(
    0.25 * false_precision_risk +
    0.30 * boundary_risk +
    0.20 * proxy_risk +
    0.25 * misuse_risk,
    6
  ) AS distortion_risk_score,
  ROUND(
    (0.30 * structural_clarity + 0.25 * dynamic_clarity + 0.25 * scenario_clarity + 0.20 * assumption_transparency) -
    (0.25 * false_precision_risk + 0.30 * boundary_risk + 0.20 * proxy_risk + 0.25 * misuse_risk),
    6
  ) AS net_interpretive_value,
  CASE
    WHEN
      (0.30 * structural_clarity + 0.25 * dynamic_clarity + 0.25 * scenario_clarity + 0.20 * assumption_transparency) -
      (0.25 * false_precision_risk + 0.30 * boundary_risk + 0.20 * proxy_risk + 0.25 * misuse_risk) >= 0.20
    THEN 'strong_clarification_with_managed_risk'
    WHEN
      (0.30 * structural_clarity + 0.25 * dynamic_clarity + 0.25 * scenario_clarity + 0.20 * assumption_transparency) -
      (0.25 * false_precision_risk + 0.30 * boundary_risk + 0.20 * proxy_risk + 0.25 * misuse_risk) >= 0
    THEN 'useful_with_strong_caveats'
    ELSE 'high_distortion_risk_without_revision'
  END AS use_label,
  description
FROM model_cases
ORDER BY net_interpretive_value DESC;

CREATE VIEW v_use_label_summary AS
SELECT
  use_label,
  COUNT(*) AS model_case_count,
  ROUND(AVG(clarification_score), 6) AS average_clarification_score,
  ROUND(AVG(distortion_risk_score), 6) AS average_distortion_risk_score,
  ROUND(AVG(net_interpretive_value), 6) AS average_net_interpretive_value
FROM v_model_cases_scored
GROUP BY use_label
ORDER BY use_label;

CREATE VIEW v_risk_register AS
SELECT risk_id, risk_type, description, mitigation
FROM risk_register
ORDER BY risk_id;

CREATE VIEW v_communication_controls AS
SELECT control_id, communication_control, purpose, warning_sign
FROM communication_controls
ORDER BY control_id;

CREATE VIEW v_use_scope_register AS
SELECT scope_id, use_case, valid_use, invalid_use, review_requirement
FROM use_scope_register
ORDER BY scope_id;

CREATE VIEW v_distortion_patterns AS
SELECT pattern_id, distortion_pattern, how_it_distorts, diagnostic_question
FROM distortion_patterns
ORDER BY pattern_id;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_model_cases_scored;
SELECT * FROM v_use_label_summary;
SELECT * FROM v_risk_register;
SELECT * FROM v_communication_controls;
SELECT * FROM v_use_scope_register;
SELECT * FROM v_distortion_patterns;
SELECT * FROM v_validation_targets;
