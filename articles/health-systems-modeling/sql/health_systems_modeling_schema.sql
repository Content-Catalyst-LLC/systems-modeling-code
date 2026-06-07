-- health_systems_modeling_schema.sql
-- SQLite schema and analysis queries for health systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_health_system_components;
DROP VIEW IF EXISTS v_health_feedback_loops;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_equity_dimensions;
DROP VIEW IF EXISTS v_health_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS health_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS equity_dimensions;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS health_feedback_loops;
DROP TABLE IF EXISTS health_system_components;

CREATE TABLE health_system_components (
  component TEXT PRIMARY KEY,
  system_role TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE health_feedback_loops (
  feedback_loop TEXT PRIMARY KEY,
  loop_type TEXT NOT NULL,
  health_system_mechanism TEXT NOT NULL,
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
  initial_demand REAL NOT NULL,
  initial_trust REAL NOT NULL,
  demand_growth REAL NOT NULL,
  prevention_effect REAL NOT NULL,
  workforce_recovery REAL NOT NULL,
  burnout_sensitivity REAL NOT NULL,
  attrition_sensitivity REAL NOT NULL,
  hiring_rate REAL NOT NULL,
  access_barrier REAL NOT NULL,
  trust_loss_rate REAL NOT NULL,
  trust_gain_rate REAL NOT NULL,
  surge_start INTEGER NOT NULL,
  surge_end INTEGER NOT NULL,
  surge_intensity REAL NOT NULL,
  seed INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE equity_dimensions (
  dimension TEXT PRIMARY KEY,
  health_system_issue TEXT NOT NULL,
  modeling_implication TEXT NOT NULL,
  professional_caution TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE health_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO health_system_components (
  component,
  system_role,
  modeling_representation,
  diagnostic_question
) VALUES
('population', 'people_with_different_risk_health_status_access_behavior_and_vulnerability', 'population_groups_risk_strata_cohorts_agents_or_geographic_areas', 'Which_populations_are_at_risk_and_how_are_outcomes_distributed'),
('health_need', 'demand_for_prevention_diagnosis_treatment_chronic_care_emergency_care_and_support', 'incidence_prevalence_risk_profile_care_demand_or_disease_state', 'What_health_need_generates_service_demand'),
('service_capacity', 'ability_to_deliver_care_or_public_health_services', 'beds_clinicians_appointments_supplies_funding_hours_or_throughput', 'Where_does_demand_exceed_effective_capacity'),
('care_pathways', 'sequences_from_need_to_access_diagnosis_treatment_follow_up_and_outcome', 'states_transitions_queues_referral_networks_or_patient_journeys', 'Where_do_people_fall_out_of_the_care_pathway'),
('workforce', 'clinicians_public_health_workers_support_staff_caregivers_and_managers', 'staff_stock_skill_mix_workload_burnout_attrition_or_productivity', 'Is_capacity_sustainable_and_safe'),
('behavior_and_trust', 'shape_care_seeking_adherence_prevention_communication_and_public_health_cooperation', 'uptake_rates_trust_index_compliance_rules_or_behavioral_response', 'How_do_trust_and_behavior_shape_health_system_performance'),
('financing_and_incentives', 'shape_access_utilization_coding_investment_and_organizational_behavior', 'coverage_reimbursement_payment_model_cost_sharing_or_budget_constraints', 'Which_incentives_change_access_quality_or_utilization'),
('equity_and_social_context', 'shape_exposure_access_burden_outcome_and_resilience', 'disaggregated_groups_social_determinants_vulnerability_index_or_access_barriers', 'Who_benefits_who_waits_and_who_experiences_harm');

INSERT INTO health_feedback_loops (
  feedback_loop,
  loop_type,
  health_system_mechanism,
  system_risk
) VALUES
('access_early_care', 'reinforcing', 'better_access_supports_earlier_care_reducing_severe_disease_and_future_demand', 'poor_access_can_create_worsening_avoidable_demand'),
('workload_burnout_capacity', 'reinforcing', 'high_workload_increases_burnout_and_attrition_reducing_workforce_capacity', 'self_reinforcing_staffing_crisis'),
('trust_prevention', 'reinforcing', 'trust_increases_prevention_uptake_improving_outcomes_and_reinforcing_trust', 'low_trust_weakens_public_health_response'),
('quality_rework', 'reinforcing', 'poor_quality_creates_complications_readmissions_complaints_and_rework', 'care_burden_increases_while_outcomes_worsen'),
('payment_utilization', 'reinforcing_or_balancing', 'payment_incentives_affect_service_mix_coding_utilization_and_investment', 'financial_incentives_may_distort_care_priorities'),
('emergency_crowding', 'reinforcing', 'crowding_delays_care_increases_length_of_stay_worsens_flow_and_raises_pressure', 'access_and_safety_deteriorate_together'),
('deferred_care_acuity', 'reinforcing', 'delayed_care_increases_acuity_which_increases_future_demand_and_cost', 'hidden_backlog_becomes_future_crisis');

INSERT INTO modeling_approaches (
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('system_dynamics', 'feedback_delay_capacity_workforce_prevention_chronic_burden_policy_effects_and_public_health_capacity', 'stock_trajectories_loop_dominance_backlog_and_workforce_pressure', 'aggregate_models_can_hide_subgroup_inequity_and_clinical_complexity'),
('compartmental_modeling', 'disease_spread_intervention_timing_and_population_state_transitions', 'transmission_rate_peak_burden_susceptible_population_and_hospitalization', 'biological_models_can_miss_behavior_trust_and_social_context'),
('discrete_event_simulation', 'patient_flow_queues_resource_use_bottlenecks_clinical_operations_and_service_delivery', 'wait_time_utilization_length_of_stay_throughput_and_bottlenecks', 'process_models_can_ignore_equity_and_access_before_entry'),
('agent_based_modeling', 'heterogeneous_behavior_care_seeking_adherence_transmission_social_networks_and_health_inequity', 'distribution_of_outcomes_emergent_patterns_and_group_differences', 'behavior_rules_can_encode_bias_or_unsupported_assumptions'),
('network_modeling', 'contacts_referrals_provider_networks_supply_chains_and_information_flow', 'connectivity_centrality_cascade_risk_and_fragmentation', 'network_data_can_create_privacy_and_missingness_risks'),
('geospatial_health_modeling', 'access_exposure_place_based_vulnerability_environmental_health_and_service_deserts', 'distance_service_area_hotspot_and_spatial_disparity', 'spatial_precision_can_create_false_confidence'),
('participatory_modeling', 'community_knowledge_trust_access_barriers_equity_and_intervention_design', 'assumption_review_lived_barriers_and_shared_interpretation', 'participation_must_be_meaningful_not_symbolic');

INSERT INTO scenario_definitions (
  scenario,
  n_steps,
  initial_capacity,
  initial_demand,
  initial_trust,
  demand_growth,
  prevention_effect,
  workforce_recovery,
  burnout_sensitivity,
  attrition_sensitivity,
  hiring_rate,
  access_barrier,
  trust_loss_rate,
  trust_gain_rate,
  surge_start,
  surge_end,
  surge_intensity,
  seed,
  description
) VALUES
('baseline_health_system', 120, 100, 92, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18, 42, 'Baseline demand capacity backlog and trust pathway'),
('higher_demand_growth', 120, 100, 92, 0.64, 0.65, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18, 43, 'Higher underlying demand growth increases care pressure'),
('stronger_prevention', 120, 100, 92, 0.70, 0.35, 0.060, 0.035, 0.085, 0.030, 0.50, 0.16, 0.018, 0.018, 45, 65, 18, 44, 'Prevention and trust reduce future demand'),
('larger_surge', 120, 100, 92, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 32, 45, 'Larger surge event tests emergency capacity'),
('faster_hiring', 120, 100, 92, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 1.20, 0.18, 0.020, 0.012, 45, 65, 18, 46, 'Faster hiring improves capacity after transition'),
('higher_access_barrier', 120, 100, 92, 0.54, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.32, 0.035, 0.012, 45, 65, 18, 47, 'Higher access barriers increase unmet need and reduce trust'),
('burnout_sensitive', 120, 100, 92, 0.60, 0.45, 0.015, 0.020, 0.135, 0.045, 0.50, 0.22, 0.030, 0.010, 45, 65, 22, 48, 'Greater burnout sensitivity creates workforce deterioration'),
('resilient_prepared_system', 120, 108, 88, 0.74, 0.28, 0.055, 0.060, 0.060, 0.020, 0.95, 0.12, 0.014, 0.020, 45, 65, 14, 49, 'Prevention workforce recovery and lower access barriers improve resilience');

INSERT INTO equity_dimensions (
  dimension,
  health_system_issue,
  modeling_implication,
  professional_caution
) VALUES
('access', 'people_face_unequal_ability_to_obtain_timely_appropriate_care', 'measure_wait_time_distance_cost_language_access_digital_access_and_referral_completion', 'formal_service_availability_does_not_guarantee_practical_access'),
('exposure', 'health_risks_differ_by_work_housing_environment_violence_stress_and_pollution', 'represent_cumulative_exposure_and_place_based_vulnerability', 'average_risk_can_hide_hotspots'),
('affordability', 'cost_sharing_insurance_design_medication_prices_and_lost_wages_affect_care', 'model_financial_burden_and_care_avoidance', 'lower_utilization_may_mean_avoided_needed_care'),
('quality', 'care_quality_may_differ_across_facilities_groups_and_communication_contexts', 'disaggregate_outcomes_safety_events_diagnosis_and_treatment_completion', 'quality_metrics_can_hide_differential_harm'),
('trust', 'historical_and_ongoing_harm_affects_engagement_with_health_institutions', 'represent_trust_participation_communication_and_accountability', 'trust_should_not_be_treated_as_patient_deficit'),
('voice', 'affected_communities_may_be_excluded_from_model_design_and_interpretation', 'use_participatory_modeling_and_transparent_assumptions', 'models_should_not_replace_community_knowledge'),
('privacy', 'health_data_can_expose_sensitive_identity_risk_or_vulnerability', 'use_minimization_aggregation_deidentification_governance_and_consent', 'privacy_risk_can_damage_trust');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('demand', 0, 1000000, 'Demand should remain nonnegative and finite'),
('capacity', 0, 1000000, 'Capacity should remain nonnegative and finite'),
('effective_capacity', 0, 1000000, 'Effective capacity should remain nonnegative and finite'),
('backlog', 0, 1000000, 'Backlog should remain nonnegative and finite'),
('pressure', 0, 1000000, 'Pressure should remain nonnegative and finite'),
('burnout', 0, 1000000, 'Burnout should remain nonnegative and finite'),
('attrition', 0, 1000000, 'Attrition should remain nonnegative and finite'),
('served', 0, 1000000, 'Served volume should remain nonnegative and finite'),
('unmet_need', 0, 1000000, 'Unmet need should remain nonnegative and finite'),
('access_gap', 0, 1000000, 'Access gap should remain nonnegative and finite'),
('trust', 0, 1, 'Trust should remain bounded between 0 and 1');

INSERT INTO health_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_health_system', 'illustrative_demand_growth', 0.35, 'Baseline demand growth'),
('higher_demand_growth', 'illustrative_demand_growth', 0.65, 'Higher demand growth'),
('stronger_prevention', 'illustrative_prevention_effect', 0.060, 'Stronger prevention effect'),
('larger_surge', 'illustrative_surge_intensity', 32.00, 'Larger surge event'),
('faster_hiring', 'illustrative_hiring_rate', 1.20, 'Faster hiring rate'),
('higher_access_barrier', 'illustrative_access_barrier', 0.32, 'Higher access barrier'),
('burnout_sensitive', 'illustrative_burnout_sensitivity', 0.135, 'Greater burnout sensitivity'),
('resilient_prepared_system', 'illustrative_initial_trust', 0.74, 'Higher starting trust and resilience');

CREATE VIEW v_health_system_components AS
SELECT component, system_role, modeling_representation, diagnostic_question
FROM health_system_components
ORDER BY component;

CREATE VIEW v_health_feedback_loops AS
SELECT feedback_loop, loop_type, health_system_mechanism, system_risk
FROM health_feedback_loops
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
SELECT dimension, health_system_issue, modeling_implication, professional_caution
FROM equity_dimensions
ORDER BY dimension;

CREATE VIEW v_health_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM health_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_health_system_components;
SELECT * FROM v_health_feedback_loops;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_equity_dimensions;
SELECT * FROM v_health_metric_summary;
SELECT * FROM v_validation_targets;
