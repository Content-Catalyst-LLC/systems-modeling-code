-- public_policy_modeling_schema.sql
-- SQLite schema and analysis queries for public policy modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_policy_system_components;
DROP VIEW IF EXISTS v_policy_feedback_loops;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_equity_dimensions;
DROP VIEW IF EXISTS v_policy_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS policy_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS equity_dimensions;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS policy_feedback_loops;
DROP TABLE IF EXISTS policy_system_components;

CREATE TABLE policy_system_components (
  component TEXT PRIMARY KEY,
  system_role TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE policy_feedback_loops (
  feedback_loop TEXT PRIMARY KEY,
  loop_type TEXT NOT NULL,
  policy_mechanism TEXT NOT NULL,
  system_risk TEXT NOT NULL
);

CREATE TABLE modeling_approaches (
  approach TEXT PRIMARY KEY,
  best_suited_for TEXT NOT NULL,
  key_diagnostic TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  n_steps INTEGER NOT NULL,
  target_state REAL NOT NULL,
  initial_state REAL NOT NULL,
  initial_capacity REAL NOT NULL,
  initial_trust REAL NOT NULL,
  initial_burden REAL NOT NULL,
  starting_policy REAL NOT NULL,
  max_policy REAL NOT NULL,
  min_policy REAL NOT NULL,
  policy_increase_rate REAL NOT NULL,
  policy_decrease_rate REAL NOT NULL,
  policy_effect REAL NOT NULL,
  capacity_learning_rate REAL NOT NULL,
  burden_growth REAL NOT NULL,
  burden_relief REAL NOT NULL,
  side_effect_rate REAL NOT NULL,
  seed INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE equity_dimensions (
  dimension TEXT PRIMARY KEY,
  policy_system_issue TEXT NOT NULL,
  modeling_implication TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE policy_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO policy_system_components (
  component,
  system_role,
  modeling_representation,
  diagnostic_question
) VALUES
('policy_lever', 'the_intervention_used_to_change_system_behavior', 'tax_subsidy_regulation_mandate_service_investment_standard_information_rule_or_institutional_reform', 'Which_policy_lever_is_expected_to_change_behavior_or_capacity'),
('target_population', 'people_firms_institutions_places_or_sectors_affected_by_policy', 'population_group_agent_class_sector_geography_or_eligibility_category', 'Who_is_formally_eligible_and_who_can_practically_access_the_policy'),
('institutional_capacity', 'ability_to_implement_enforce_monitor_adapt_and_learn', 'staffing_budget_administrative_load_compliance_capacity_service_capacity_or_data_systems', 'Can_the_governance_system_deliver_the_policy'),
('behavioral_response', 'how_affected_actors_adapt_to_policy_incentives_and_constraints', 'elasticity_decision_rule_adoption_curve_compliance_rate_or_strategic_response', 'How_do_people_firms_and_institutions_respond'),
('outcome_measure', 'the_policy_relevant_result_being_tracked', 'poverty_emissions_access_health_affordability_safety_service_quality_or_resilience', 'Which_outcome_defines_success_or_failure'),
('side_effect', 'unintended_or_secondary_consequence_generated_by_policy', 'displacement_rebound_effect_administrative_burden_market_distortion_or_fiscal_strain', 'What_costs_or_risks_accumulate_elsewhere'),
('feedback_loop', 'recursive_relationship_between_policy_behavior_institutions_and_outcomes', 'causal_loop_stock_flow_relationship_adaptive_rule_or_learning_process', 'Which_feedbacks_amplify_weaken_or_reverse_policy_effect'),
('equity_dimension', 'distribution_of_benefits_burdens_risks_and_voice', 'disaggregated_outcomes_by_income_race_geography_age_disability_tenure_or_exposure', 'Who_benefits_who_pays_who_waits_and_who_is_harmed');

INSERT INTO policy_feedback_loops (
  feedback_loop,
  loop_type,
  policy_mechanism,
  system_risk
) VALUES
('trust_uptake', 'reinforcing', 'reliable_service_builds_trust_which_increases_participation_and_policy_effectiveness', 'failure_can_create_low_trust_low_uptake_and_weak_impact'),
('capacity_performance', 'reinforcing', 'better_capacity_improves_delivery_which_supports_funding_and_institutional_learning', 'under_capacity_can_produce_failure_and_further_resource_loss'),
('administrative_burden', 'reinforcing', 'complex_rules_reduce_access_generating_poor_outcomes_that_justify_more_oversight', 'programs_can_become_harder_to_use_over_time'),
('subsidy_adoption', 'reinforcing', 'subsidies_increase_adoption_adoption_lowers_cost_and_lower_cost_increases_adoption', 'can_create_dependency_or_unequal_access_if_poorly_designed'),
('regulation_compliance', 'balancing_or_reinforcing', 'clear_enforcement_improves_compliance_while_weak_enforcement_invites_evasion', 'formal_rules_may_not_change_real_behavior'),
('policy_backlash', 'reinforcing', 'perceived_unfairness_increases_opposition_which_weakens_implementation_and_legitimacy', 'policy_can_become_unstable_or_reversed'),
('learning_adaptation', 'balancing', 'monitoring_and_evaluation_update_policy_design_implementation_and_resource_allocation', 'learning_fails_if_evidence_is_not_linked_to_authority');

INSERT INTO modeling_approaches (
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('system_dynamics', 'feedback_delay_capacity_public_finance_institutional_performance_and_long_term_policy_effects', 'stock_trajectories_loop_dominance_delay_effects_and_capacity_gaps', 'aggregate_models_can_hide_distributional_and_implementation_variation'),
('agent_based_modeling', 'heterogeneous_response_behavior_compliance_adoption_mobility_sorting_and_strategic_action', 'distribution_of_outcomes_emergent_patterns_and_group_level_effects', 'decision_rules_can_encode_weak_or_biased_assumptions'),
('scenario_modeling', 'uncertain_futures_stress_testing_adaptive_pathways_and_robustness', 'performance_across_futures_failure_conditions_and_signposts', 'scenario_selection_can_bias_conclusions'),
('network_modeling', 'infrastructure_contagion_interdependence_service_systems_and_institutional_coordination', 'connectivity_centrality_cascade_pathways_and_service_disruption', 'missing_links_can_understate_systemic_risk'),
('multi_criteria_decision_analysis', 'policies_with_multiple_goals_and_contested_tradeoffs', 'score_sensitivity_value_weights_and_tradeoff_transparency', 'weights_are_value_judgments_not_neutral_facts'),
('participatory_modeling', 'contested_policy_systems_local_knowledge_legitimacy_justice_and_implementation_reality', 'assumption_review_stakeholder_priorities_and_shared_learning', 'participation_must_be_meaningful_not_symbolic'),
('integrated_assessment', 'economy_energy_environment_climate_and_technology_policy_pathways', 'emissions_costs_damages_prices_adoption_and_transition_pathways', 'damage_functions_discounting_and_values_must_be_explicit');

INSERT INTO scenario_definitions (
  scenario,
  n_steps,
  target_state,
  initial_state,
  initial_capacity,
  initial_trust,
  initial_burden,
  starting_policy,
  max_policy,
  min_policy,
  policy_increase_rate,
  policy_decrease_rate,
  policy_effect,
  capacity_learning_rate,
  burden_growth,
  burden_relief,
  side_effect_rate,
  seed,
  description
) VALUES
('baseline_adaptive_policy', 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08, 42, 'Baseline adaptive policy response with capacity burden and side effects'),
('aggressive_policy_rule', 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.4, 0.25, 0.14, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08, 43, 'More aggressive adaptive policy response'),
('low_capacity_learning', 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.035, 0.05, 0.025, 0.08, 44, 'Lower institutional learning slows capacity response'),
('high_burden_design', 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.10, 0.025, 0.08, 45, 'High administrative burden weakens access and trust'),
('trust_centered_design', 100, 16, 12, 7, 0.72, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.025, 0.025, 0.045, 46, 'Higher trust and lower burden improve uptake'),
('low_side_effect_policy', 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.48, 0.09, 0.05, 0.025, 0.035, 47, 'Lower side effects but weaker direct effect'),
('short_policy_window', 100, 16, 12, 7, 0.58, 0.25, 1.0, 1.6, 0.25, 0.05, 0.08, 0.45, 0.08, 0.04, 0.025, 0.055, 48, 'Shorter and less intense policy cycle'),
('capacity_first_policy', 100, 16, 12, 9, 0.64, 0.20, 0.8, 1.8, 0.25, 0.06, 0.05, 0.50, 0.13, 0.030, 0.035, 0.055, 49, 'Capacity-first approach reduces burden and improves delivery');

INSERT INTO equity_dimensions (
  dimension,
  policy_system_issue,
  modeling_implication,
  professional_caution
) VALUES
('access', 'eligible_people_may_not_be_able_to_use_the_policy', 'model_practical_access_administrative_burden_language_digital_access_and_geography', 'formal_eligibility_does_not_guarantee_real_access'),
('distribution', 'benefits_and_burdens_differ_by_group_and_place', 'disaggregate_outcomes_by_income_race_geography_age_disability_tenure_and_exposure', 'average_effects_can_hide_harm'),
('affordability', 'fees_taxes_prices_or_compliance_costs_burden_groups_differently', 'track_household_firm_and_community_cost_burden', 'cost_pass_through_can_change_policy_equity'),
('exposure', 'some_communities_face_greater_environmental_health_infrastructure_or_economic_risk', 'include_cumulative_burden_and_vulnerability', 'policy_can_reduce_average_risk_while_leaving_hotspots'),
('voice', 'affected_communities_may_be_excluded_from_design_and_interpretation', 'use_participatory_modeling_and_transparent_assumptions', 'models_should_not_replace_public_reasoning'),
('durability', 'policies_can_become_unstable_if_legitimacy_is_weak', 'model_trust_backlash_compliance_and_political_support', 'technically_plausible_policies_can_fail_without_legitimacy'),
('administrative_justice', 'complexity_documentation_and_verification_can_exclude_intended_beneficiaries', 'represent_friction_time_cost_navigation_and_appeals', 'anti_fraud_design_can_create_exclusion');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('system_state', 0, 1000000, 'System state should remain nonnegative and finite'),
('policy_intensity', 0, 1000000, 'Policy intensity should remain nonnegative and finite'),
('institutional_capacity', 0, 1000000, 'Institutional capacity should remain nonnegative and finite'),
('trust', 0, 1, 'Trust should remain bounded between 0 and 1'),
('administrative_burden', 0, 1000000, 'Administrative burden should remain nonnegative and finite'),
('uptake', 0, 1, 'Uptake should remain bounded between 0 and 1'),
('side_effect', 0, 1000000, 'Side effects should remain nonnegative and finite'),
('average_policy_intensity', 0, 1000000, 'Average policy intensity should remain nonnegative and finite');

INSERT INTO policy_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_adaptive_policy', 'illustrative_policy_increase_rate', 0.08, 'Baseline adaptive policy adjustment'),
('aggressive_policy_rule', 'illustrative_policy_increase_rate', 0.14, 'More aggressive policy adjustment'),
('low_capacity_learning', 'illustrative_capacity_learning_rate', 0.035, 'Lower institutional learning'),
('high_burden_design', 'illustrative_burden_growth', 0.10, 'Higher administrative burden'),
('trust_centered_design', 'illustrative_initial_trust', 0.72, 'Higher trust at launch'),
('low_side_effect_policy', 'illustrative_side_effect_rate', 0.035, 'Lower side effect accumulation'),
('short_policy_window', 'illustrative_max_policy', 1.60, 'Shorter and less intense policy cycle'),
('capacity_first_policy', 'illustrative_initial_capacity', 9.00, 'Higher initial implementation capacity');

CREATE VIEW v_policy_system_components AS
SELECT component, system_role, modeling_representation, diagnostic_question
FROM policy_system_components
ORDER BY component;

CREATE VIEW v_policy_feedback_loops AS
SELECT feedback_loop, loop_type, policy_mechanism, system_risk
FROM policy_feedback_loops
ORDER BY feedback_loop;

CREATE VIEW v_modeling_approaches AS
SELECT approach, best_suited_for, key_diagnostic, professional_caution
FROM modeling_approaches
ORDER BY approach;

CREATE VIEW v_scenario_definitions AS
SELECT *
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_equity_dimensions AS
SELECT dimension, policy_system_issue, modeling_implication, professional_caution
FROM equity_dimensions
ORDER BY dimension;

CREATE VIEW v_policy_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM policy_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_policy_system_components;
SELECT * FROM v_policy_feedback_loops;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_equity_dimensions;
SELECT * FROM v_policy_metric_summary;
SELECT * FROM v_validation_targets;
