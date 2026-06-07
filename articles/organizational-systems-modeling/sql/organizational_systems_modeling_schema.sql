-- organizational_systems_modeling_schema.sql
-- SQLite schema and analysis queries for organizational systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_organizational_system_components;
DROP VIEW IF EXISTS v_organizational_feedback_loops;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_ethics_dimensions;
DROP VIEW IF EXISTS v_organizational_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS organizational_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS ethics_dimensions;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS organizational_feedback_loops;
DROP TABLE IF EXISTS organizational_system_components;

CREATE TABLE organizational_system_components (
  component TEXT PRIMARY KEY,
  system_role TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE organizational_feedback_loops (
  feedback_loop TEXT PRIMARY KEY,
  loop_type TEXT NOT NULL,
  organizational_mechanism TEXT NOT NULL,
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
  initial_capacity REAL NOT NULL,
  initial_workload REAL NOT NULL,
  initial_trust REAL NOT NULL,
  demand_growth REAL NOT NULL,
  hiring_rate REAL NOT NULL,
  learning_rate REAL NOT NULL,
  burnout_sensitivity REAL NOT NULL,
  recovery_rate REAL NOT NULL,
  attrition_sensitivity REAL NOT NULL,
  coordination_burden_rate REAL NOT NULL,
  trust_loss_rate REAL NOT NULL,
  trust_gain_rate REAL NOT NULL,
  seed INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE ethics_dimensions (
  dimension TEXT PRIMARY KEY,
  organizational_issue TEXT NOT NULL,
  modeling_implication TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE organizational_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO organizational_system_components (
  component,
  system_role,
  modeling_representation,
  diagnostic_question
) VALUES
('people_and_roles', 'carry_work_judgment_knowledge_authority_relationships_and_institutional_memory', 'employees_teams_role_classes_capacity_units_skill_groups_or_agents', 'Which_people_roles_or_capabilities_are_structurally_critical'),
('workload', 'represents_demand_placed_on_people_teams_systems_and_processes', 'task_arrivals_queue_length_service_requests_project_load_or_meeting_load', 'Where_does_demand_exceed_sustainable_capacity'),
('capacity', 'represents_ability_to_perform_work_at_expected_quality_and_speed', 'staffing_skill_available_hours_throughput_decision_capacity_or_automation_support', 'What_capacity_is_actually_available_after_coordination_and_burnout'),
('information_flow', 'determines_who_knows_what_when_and_with_what_confidence', 'communication_network_reporting_delay_signal_quality_or_knowledge_sharing', 'Where_does_information_delay_or_distortion_affect_decisions'),
('decision_rights', 'define_who_can_approve_prioritize_stop_fund_escalate_or_change_work', 'governance_rules_approval_queues_authority_matrix_or_escalation_pathways', 'Where_do_decision_bottlenecks_or_authority_gaps_emerge'),
('incentives_and_metrics', 'shape_attention_behavior_tradeoffs_risk_taking_and_gaming', 'performance_indicators_reward_rules_scorecards_or_budget_constraints', 'Which_metrics_are_shaping_real_behavior'),
('learning_and_capability', 'determine_whether_the_organization_improves_through_experience', 'learning_curves_skill_accumulation_review_loops_or_knowledge_retention', 'Is_the_organization_building_future_capacity'),
('culture_and_trust', 'shape_cooperation_candor_adaptation_conflict_and_psychological_safety', 'trust_index_collaboration_rate_feedback_quality_or_escalation_behavior', 'Can_people_surface_risk_and_learn_safely');

INSERT INTO organizational_feedback_loops (
  feedback_loop,
  loop_type,
  organizational_mechanism,
  system_risk
) VALUES
('workload_burnout_turnover', 'reinforcing', 'high_workload_increases_burnout_turnover_reduces_capacity_lower_capacity_raises_workload', 'self_reinforcing_attrition_spiral'),
('learning_capability', 'reinforcing', 'practice_and_reflection_increase_capability_which_improves_performance_and_frees_time_for_learning', 'without_protected_learning_time_capability_stagnates'),
('quality_rework', 'reinforcing', 'rushed_work_lowers_quality_creating_rework_that_increases_pressure_and_further_reduces_quality', 'hidden_productivity_collapse'),
('trust_candor', 'reinforcing', 'trust_supports_candor_candor_reveals_problems_early_early_correction_builds_trust', 'low_trust_hides_risk_until_failure'),
('metric_gaming', 'reinforcing', 'pressure_on_narrow_metrics_encourages_gaming_which_distorts_information_and_worsens_decisions', 'measured_performance_improves_while_real_performance_declines'),
('centralization_delay', 'balancing_or_reinforcing', 'central_control_improves_consistency_but_can_slow_decisions_and_increase_escalation', 'decision_bottlenecks_and_reduced_local_adaptation'),
('coordination_burden', 'reinforcing', 'cross_team_dependencies_increase_coordination_load_which_reduces_delivery_capacity_and_creates_more_escalation', 'coordination_work_crowds_out_productive_work');

INSERT INTO modeling_approaches (
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('system_dynamics', 'workload_capacity_attrition_learning_burnout_strategy_execution_and_change_delay', 'stock_trajectories_feedback_loops_capacity_gaps_and_delay_effects', 'aggregate_capacity_can_hide_skill_context_and_power_differences'),
('agent_based_modeling', 'behavior_adoption_influence_compliance_collaboration_emergent_culture_and_local_adaptation', 'agent_outcomes_adoption_curves_emergent_patterns_and_group_differences', 'behavior_rules_can_encode_weak_or_biased_assumptions'),
('organizational_network_modeling', 'communication_trust_knowledge_sharing_informal_authority_and_dependency', 'centrality_brokerage_silos_vulnerability_and_connectivity', 'network_data_can_create_privacy_and_surveillance_risk'),
('discrete_event_simulation', 'workflow_queues_approvals_service_delivery_support_operations_and_project_intake', 'cycle_time_waiting_time_utilization_bottlenecks_and_throughput', 'process_models_can_ignore_informal_workarounds'),
('scenario_modeling', 'uncertain_demand_staffing_loss_strategic_shifts_technology_adoption_and_resilience', 'performance_across_futures_failure_points_and_resilience_thresholds', 'scenario_selection_can_bias_leadership_interpretation'),
('participatory_modeling', 'culture_trust_implementation_contested_change_frontline_knowledge_and_legitimacy', 'assumption_review_stakeholder_priorities_and_shared_understanding', 'participation_must_be_meaningful_not_symbolic');

INSERT INTO scenario_definitions (
  scenario,
  n_steps,
  initial_capacity,
  initial_workload,
  initial_trust,
  demand_growth,
  hiring_rate,
  learning_rate,
  burnout_sensitivity,
  recovery_rate,
  attrition_sensitivity,
  coordination_burden_rate,
  trust_loss_rate,
  trust_gain_rate,
  seed,
  description
) VALUES
('baseline_organization', 100, 100, 95, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010, 42, 'Baseline workload capacity and learning pathway'),
('high_demand_growth', 100, 100, 95, 0.62, 0.85, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010, 43, 'Higher demand growth increases pressure and backlog'),
('faster_hiring', 100, 100, 95, 0.62, 0.45, 1.25, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010, 44, 'Higher hiring rate improves capacity after transition'),
('learning_investment', 100, 100, 95, 0.62, 0.45, 0.65, 0.070, 0.090, 0.040, 0.035, 0.10, 0.030, 0.018, 45, 'Learning investment improves capability and trust'),
('high_coordination_burden', 100, 100, 95, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.22, 0.030, 0.010, 46, 'Cross_team_dependency burden reduces effective capacity'),
('low_trust_environment', 100, 100, 95, 0.38, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.050, 0.010, 47, 'Low trust weakens learning and resilience'),
('burnout_sensitive', 100, 100, 95, 0.62, 0.55, 0.65, 0.035, 0.140, 0.025, 0.050, 0.12, 0.040, 0.010, 48, 'Greater burnout sensitivity creates attrition spiral'),
('resilient_learning_system', 100, 105, 92, 0.72, 0.38, 0.85, 0.075, 0.060, 0.065, 0.025, 0.07, 0.018, 0.022, 49, 'Slack trust and learning reduce operating pressure');

INSERT INTO ethics_dimensions (
  dimension,
  organizational_issue,
  modeling_implication,
  professional_caution
) VALUES
('privacy', 'workforce_analytics_can_collect_sensitive_behavioral_or_performance_data', 'use_minimization_aggregation_consent_and_governance', 'data_collection_can_become_surveillance'),
('equity', 'workload_opportunity_attrition_and_promotion_burdens_may_be_uneven', 'disaggregate_by_role_level_location_tenure_and_relevant_groups', 'aggregate_metrics_can_hide_unequal_burden'),
('dignity', 'people_should_not_be_reduced_to_interchangeable_capacity_units', 'combine_quantitative_models_with_participatory_review', 'models_can_dehumanize_work'),
('accountability', 'model_outputs_can_shift_blame_onto_individuals_or_frontline_teams', 'distinguish_structural_causes_from_individual_behavior', 'models_should_not_be_used_as_punishment_tools'),
('transparency', 'employees_may_not_know_how_models_affect_decisions', 'document_assumptions_data_use_limits_and_decision_rights', 'opaque_models_reduce_trust'),
('power', 'leaders_may_use_models_to_justify_preferred_reorganizations_or_control', 'make_value_judgments_and_tradeoffs_explicit', 'technical_language_can_hide_power_choices'),
('participation', 'affected_workers_may_be_excluded_from_model_design_and_interpretation', 'use_stakeholder_review_and_frontline_validation', 'models_without_participation_may_miss_lived_work');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('capacity', 0, 1000000, 'Capacity should remain nonnegative and finite'),
('workload', 0, 1000000, 'Workload should remain nonnegative and finite'),
('backlog', 0, 1000000, 'Backlog should remain nonnegative and finite'),
('pressure', 0, 1000000, 'Pressure should remain nonnegative and finite'),
('burnout', 0, 1000000, 'Burnout should remain nonnegative and finite'),
('attrition', 0, 1000000, 'Attrition should remain nonnegative and finite'),
('trust', 0, 1, 'Trust should remain bounded between 0 and 1'),
('delivery', 0, 1000000, 'Delivery should remain nonnegative and finite');

INSERT INTO organizational_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_organization', 'illustrative_demand_growth', 0.45, 'Baseline demand growth'),
('high_demand_growth', 'illustrative_demand_growth', 0.85, 'Higher demand growth'),
('faster_hiring', 'illustrative_hiring_rate', 1.25, 'Faster hiring rate'),
('learning_investment', 'illustrative_learning_rate', 0.070, 'Higher learning investment'),
('high_coordination_burden', 'illustrative_coordination_burden_rate', 0.22, 'Higher cross-team dependency burden'),
('low_trust_environment', 'illustrative_initial_trust', 0.38, 'Lower starting trust'),
('burnout_sensitive', 'illustrative_burnout_sensitivity', 0.140, 'Greater burnout sensitivity'),
('resilient_learning_system', 'illustrative_initial_trust', 0.72, 'Higher trust and resilience');

CREATE VIEW v_organizational_system_components AS
SELECT component, system_role, modeling_representation, diagnostic_question
FROM organizational_system_components
ORDER BY component;

CREATE VIEW v_organizational_feedback_loops AS
SELECT feedback_loop, loop_type, organizational_mechanism, system_risk
FROM organizational_feedback_loops
ORDER BY feedback_loop;

CREATE VIEW v_modeling_approaches AS
SELECT approach, best_suited_for, key_diagnostic, professional_caution
FROM modeling_approaches
ORDER BY approach;

CREATE VIEW v_scenario_definitions AS
SELECT *
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_ethics_dimensions AS
SELECT dimension, organizational_issue, modeling_implication, professional_caution
FROM ethics_dimensions
ORDER BY dimension;

CREATE VIEW v_organizational_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM organizational_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_organizational_system_components;
SELECT * FROM v_organizational_feedback_loops;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_ethics_dimensions;
SELECT * FROM v_organizational_metric_summary;
SELECT * FROM v_validation_targets;
