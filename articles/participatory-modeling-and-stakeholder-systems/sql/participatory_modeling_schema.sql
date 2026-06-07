-- participatory_modeling_schema.sql
-- SQLite schema and analysis queries for participatory modeling and stakeholder systems.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_stakeholder_weights;
DROP VIEW IF EXISTS v_scenarios;
DROP VIEW IF EXISTS v_assumption_register;
DROP VIEW IF EXISTS v_participation_levels;
DROP VIEW IF EXISTS v_facilitation_risks;
DROP VIEW IF EXISTS v_evidence_sources;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_stakeholder_scenario_scores;
DROP VIEW IF EXISTS v_scenario_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS stakeholder_scenario_scores;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS evidence_sources;
DROP TABLE IF EXISTS facilitation_risks;
DROP TABLE IF EXISTS participation_levels;
DROP TABLE IF EXISTS assumption_register;
DROP TABLE IF EXISTS scenarios;
DROP TABLE IF EXISTS stakeholder_weights;

CREATE TABLE stakeholder_weights (
  stakeholder_group TEXT PRIMARY KEY,
  access REAL NOT NULL,
  cost REAL NOT NULL,
  resilience REAL NOT NULL,
  equity REAL NOT NULL,
  feasibility REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE scenarios (
  scenario TEXT PRIMARY KEY,
  access REAL NOT NULL,
  cost REAL NOT NULL,
  resilience REAL NOT NULL,
  equity REAL NOT NULL,
  feasibility REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE assumption_register (
  assumption_id TEXT PRIMARY KEY,
  assumption TEXT NOT NULL,
  source TEXT NOT NULL,
  status TEXT NOT NULL,
  risk_if_wrong TEXT NOT NULL
);

CREATE TABLE participation_levels (
  participation_level TEXT PRIMARY KEY,
  stakeholder_role TEXT NOT NULL,
  modeling_implication TEXT NOT NULL,
  risk TEXT NOT NULL
);

CREATE TABLE facilitation_risks (
  risk_area TEXT PRIMARY KEY,
  modeling_risk TEXT NOT NULL,
  responsible_practice TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE evidence_sources (
  evidence_source TEXT PRIMARY KEY,
  strength TEXT NOT NULL,
  risk TEXT NOT NULL,
  governance_practice TEXT NOT NULL
);

CREATE TABLE modeling_approaches (
  approach TEXT PRIMARY KEY,
  typical_model_form TEXT NOT NULL,
  best_suited_for TEXT NOT NULL,
  main_risk TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE stakeholder_scenario_scores (
  score_id INTEGER PRIMARY KEY,
  stakeholder_group TEXT NOT NULL,
  scenario TEXT NOT NULL,
  score REAL NOT NULL,
  FOREIGN KEY (stakeholder_group) REFERENCES stakeholder_weights(stakeholder_group),
  FOREIGN KEY (scenario) REFERENCES scenarios(scenario)
);

INSERT INTO stakeholder_weights VALUES
('community_residents', 0.30, 0.10, 0.20, 0.30, 0.10, 'Residents emphasize access equity and practical service impact'),
('frontline_staff', 0.20, 0.15, 0.25, 0.20, 0.20, 'Frontline staff emphasize resilience feasibility and operational constraints'),
('technical_experts', 0.15, 0.20, 0.30, 0.15, 0.20, 'Technical experts emphasize resilience cost and implementation feasibility'),
('public_agency', 0.20, 0.25, 0.25, 0.15, 0.15, 'Public agency emphasizes cost resilience access and feasible implementation'),
('service_users', 0.35, 0.10, 0.15, 0.30, 0.10, 'Service users emphasize access equity and lived service burden'),
('resource_managers', 0.15, 0.20, 0.30, 0.15, 0.20, 'Resource managers emphasize resilience cost and long-term feasibility');

INSERT INTO scenarios VALUES
('targeted_service_expansion', 0.85, 0.55, 0.65, 0.90, 0.60, 'Expands access in high-need areas with strong equity value but moderate cost and feasibility'),
('infrastructure_repair_priority', 0.55, 0.65, 0.85, 0.50, 0.75, 'Prioritizes repair of critical infrastructure with high resilience and implementation feasibility'),
('digital_monitoring_platform', 0.60, 0.50, 0.70, 0.45, 0.70, 'Adds monitoring and analytics but raises equity and access concerns'),
('community_led_resilience', 0.75, 0.70, 0.80, 0.85, 0.55, 'Invests in community-led adaptation with strong equity and resilience but harder implementation'),
('baseline_policy_continuation', 0.40, 0.90, 0.35, 0.30, 0.85, 'Maintains current policy with low cost burden and high feasibility but weak system outcomes');

INSERT INTO assumption_register VALUES
('A1', 'Stakeholder outcome weights sum to one within each group', 'workshop_elicitation', 'documented', 'Scenario rankings may overstate consensus'),
('A2', 'Scenario performance values are normalized from zero to one', 'modeler_translation', 'needs_review', 'Scores may compare unlike quantities'),
('A3', 'Disagreement is represented as score dispersion across stakeholder groups', 'model_design', 'documented', 'Important qualitative disagreement may be hidden'),
('A4', 'Legitimacy-adjusted score penalizes high disagreement', 'participatory_design_choice', 'contested', 'The process may overvalue consensus or undervalue principled disagreement'),
('A5', 'All relevant stakeholder groups are represented in the scoring table', 'stakeholder_mapping', 'needs_review', 'Missing groups may invalidate the participatory claim'),
('A6', 'Scenario definitions are understandable to nontechnical participants', 'facilitation_design', 'needs_review', 'Participants may not be able to meaningfully evaluate model outputs'),
('A7', 'Workshop evidence can be linked to model structure without losing context', 'knowledge_translation', 'contested', 'Local knowledge may be oversimplified or extracted');

INSERT INTO participation_levels VALUES
('information', 'stakeholders_receive_model_outputs_or_explanations', 'useful_for_transparency_but_does_not_shape_the_model', 'can_be_mistaken_for_participation'),
('consultation', 'stakeholders_provide_feedback_on_model_assumptions_or_results', 'can_improve_relevance_but_may_occur_too_late_to_affect_structure', 'feedback_may_not_change_decisions'),
('collaboration', 'stakeholders_help_define_variables_boundaries_scenarios_and_validation_criteria', 'improves_shared_understanding_and_model_legitimacy', 'requires_time_facilitation_and_documentation'),
('co_design', 'stakeholders_and_modelers_jointly_design_modeling_process_and_outputs', 'requires_stronger_facilitation_governance_and_accountability', 'can_fail_if_authority_is_not_real'),
('shared_governance', 'stakeholders_help_decide_how_model_is_maintained_interpreted_and_used', 'appropriate_for_high_stakes_contested_public_or_community_facing_models', 'requires_long_term_institutional_commitment');

INSERT INTO facilitation_risks VALUES
('dominant_voices', 'powerful_participants_shape_the_model_more_than_quieter_or_affected_groups', 'use_structured_facilitation_small_groups_anonymous_input_and_equity_checks', 'one_or_two_actors_define_most_model_elements'),
('technical_intimidation', 'stakeholders_defer_to_modelers_even_when_assumptions_are_wrong', 'use_plain_language_visual_aids_model_walkthroughs_and_assumption_logs', 'participants_say_the_model_is_too_technical_to_question'),
('token_participation', 'stakeholders_are_invited_but_cannot_influence_decisions', 'clarify_what_is_open_to_change_and_what_is_fixed', 'model_boundaries_are_fixed_before_engagement'),
('institutional_capture', 'the_model_reflects_priorities_of_the_sponsoring_institution', 'document_sponsor_interests_and_include_independent_review_where_needed', 'sponsor_preferences_become_default_scenarios'),
('consensus_pressure', 'important_disagreement_is_suppressed_to_produce_a_clean_model', 'preserve_contested_assumptions_and_alternative_scenarios', 'dissent_disappears_from_the_final_outputs'),
('representation_gaps', 'absent_groups_are_treated_as_if_they_consented_or_were_irrelevant', 'identify_missing_stakeholders_and_explain_implications', 'key_affected_groups_are_not_present'),
('extractive_knowledge_use', 'stakeholder_knowledge_is_used_without_benefit_credit_or_control', 'define_data_rights_attribution_benefit_and_model_use_agreements', 'participants_do_not_receive_usable_results');

INSERT INTO evidence_sources VALUES
('administrative_data', 'structured_repeated_and_often_available_over_time', 'reflects_institutional_categories_eligibility_rules_and_reporting_bias', 'document_how_data_were_produced_and_who_is_missing'),
('sensor_data', 'frequent_precise_and_operationally_useful', 'coverage_gaps_sensor_drift_calibration_error_and_cybersecurity_risk', 'track_provenance_quality_access_and_maintenance'),
('community_knowledge', 'context_rich_understanding_of_lived_conditions_and_informal_systems', 'can_be_extracted_or_selectively_interpreted_by_institutions', 'use_consent_reciprocity_attribution_and_shared_review'),
('expert_judgment', 'specialized_knowledge_of_mechanisms_constraints_and_methods', 'may_overemphasize_disciplinary_assumptions', 'expose_assumptions_and_compare_across_expertise_types'),
('geospatial_data', 'reveals_location_exposure_access_and_spatial_inequality', 'privacy_risk_scale_effects_boundary_bias_and_false_precision', 'apply_privacy_review_and_uncertainty_communication'),
('workshop_outputs', 'capture_stakeholder_framing_causal_assumptions_and_scenario_priorities', 'may_reflect_group_dynamics_and_participation_gaps', 'document_facilitation_attendance_dissent_and_missing_voices');

INSERT INTO modeling_approaches VALUES
('group_model_building', 'causal_loop_diagrams_stock_and_flow_models_and_system_dynamics_simulations', 'shared_problem_framing_feedback_analysis_and_organizational_learning', 'dominant_voices_may_shape_the_model_without_strong_facilitation'),
('participatory_system_dynamics', 'feedback_loop_diagrams_stock_and_flow_models_simulations_and_policy_experiments', 'community_health_workforce_burnout_water_management_and_housing_dynamics', 'stakeholder_input_may_be_translated_too_quickly_into_formal_structure'),
('companion_modeling', 'agent_based_models_role_playing_games_and_social_ecological_simulations', 'natural_resource_management_land_use_commons_adaptation_and_stakeholder_learning', 'game_or_model_dynamics_may_be_mistaken_for_reality'),
('mediated_modeling', 'system_dynamics_or_integrated_models_built_through_facilitated_negotiation', 'environmental_conflict_policy_tradeoffs_and_resource_planning', 'consensus_pressure_may_suppress_important_disagreement'),
('participatory_agent_based_modeling', 'agent_rules_behaviors_environments_interactions_and_emergent_patterns', 'adoption_mobility_land_use_public_health_and_community_behavior', 'stakeholder_narratives_may_be_hard_to_translate_into_formal_rules'),
('participatory_scenario_modeling', 'scenario_sets_pathway_models_spatial_models_and_policy_simulations', 'planning_under_uncertainty_futures_thinking_public_policy_and_climate_adaptation', 'scenarios_may_reflect_institutional_preferences_more_than_plausible_alternatives'),
('community_based_system_dynamics', 'participatory_feedback_maps_and_simulations_grounded_in_community_experience', 'public_health_social_services_violence_prevention_housing_and_local_resilience', 'extractive_engagement_if_communities_do_not_control_use_or_benefit');

INSERT INTO validation_targets VALUES
('stakeholder_weight_sum', 1, 1, 'Weights should sum to one for each stakeholder group'),
('scenario_score', 0, 1, 'Scenario scores should remain normalized between zero and one'),
('mean_score', 0, 1, 'Mean scenario score should remain normalized between zero and one'),
('disagreement_sd', 0, 1, 'Disagreement should be nonnegative'),
('legitimacy_adjusted_score', -1, 1, 'Legitimacy adjusted score can be lower than mean if disagreement is high'),
('assumption_count', 1, 1000000, 'Assumption register should include at least one assumption'),
('stakeholder_group_count', 1, 1000000, 'Workflow should include at least one stakeholder group'),
('scenario_count', 1, 1000000, 'Workflow should include at least one scenario');

INSERT INTO stakeholder_scenario_scores
(stakeholder_group, scenario, score)
SELECT
  sw.stakeholder_group,
  sc.scenario,
  ROUND(
    sw.access * sc.access +
    sw.cost * sc.cost +
    sw.resilience * sc.resilience +
    sw.equity * sc.equity +
    sw.feasibility * sc.feasibility,
    6
  ) AS score
FROM stakeholder_weights sw
CROSS JOIN scenarios sc;

CREATE VIEW v_stakeholder_weights AS
SELECT *, ROUND(access + cost + resilience + equity + feasibility, 6) AS weight_sum
FROM stakeholder_weights
ORDER BY stakeholder_group;

CREATE VIEW v_scenarios AS
SELECT *
FROM scenarios
ORDER BY scenario;

CREATE VIEW v_assumption_register AS
SELECT assumption_id, assumption, source, status, risk_if_wrong
FROM assumption_register
ORDER BY assumption_id;

CREATE VIEW v_participation_levels AS
SELECT participation_level, stakeholder_role, modeling_implication, risk
FROM participation_levels
ORDER BY
  CASE participation_level
    WHEN 'information' THEN 1
    WHEN 'consultation' THEN 2
    WHEN 'collaboration' THEN 3
    WHEN 'co_design' THEN 4
    WHEN 'shared_governance' THEN 5
    ELSE 99
  END;

CREATE VIEW v_facilitation_risks AS
SELECT risk_area, modeling_risk, responsible_practice, warning_sign
FROM facilitation_risks
ORDER BY risk_area;

CREATE VIEW v_evidence_sources AS
SELECT evidence_source, strength, risk, governance_practice
FROM evidence_sources
ORDER BY evidence_source;

CREATE VIEW v_modeling_approaches AS
SELECT approach, typical_model_form, best_suited_for, main_risk
FROM modeling_approaches
ORDER BY approach;

CREATE VIEW v_stakeholder_scenario_scores AS
SELECT stakeholder_group, scenario, score
FROM stakeholder_scenario_scores
ORDER BY scenario, stakeholder_group;

CREATE VIEW v_scenario_summary AS
SELECT
  scenario,
  ROUND(AVG(score), 6) AS mean_score,
  ROUND(
    CASE
      WHEN COUNT(*) > 1 THEN
        SQRT(AVG(score * score) - AVG(score) * AVG(score))
      ELSE 0
    END,
    6
  ) AS disagreement_sd,
  ROUND(MIN(score), 6) AS minimum_score,
  ROUND(MAX(score), 6) AS maximum_score,
  ROUND(MAX(score) - MIN(score), 6) AS score_range,
  ROUND(
    AVG(score) - 0.50 *
    CASE
      WHEN COUNT(*) > 1 THEN
        SQRT(AVG(score * score) - AVG(score) * AVG(score))
      ELSE 0
    END,
    6
  ) AS legitimacy_adjusted_score
FROM stakeholder_scenario_scores
GROUP BY scenario
ORDER BY legitimacy_adjusted_score DESC;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_stakeholder_weights;
SELECT * FROM v_scenarios;
SELECT * FROM v_assumption_register;
SELECT * FROM v_participation_levels;
SELECT * FROM v_facilitation_risks;
SELECT * FROM v_evidence_sources;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_stakeholder_scenario_scores;
SELECT * FROM v_scenario_summary;
SELECT * FROM v_validation_targets;
