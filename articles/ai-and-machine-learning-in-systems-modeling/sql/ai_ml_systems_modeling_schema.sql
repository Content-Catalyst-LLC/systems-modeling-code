-- ai_ml_systems_modeling_schema.sql
-- SQLite schema and analysis queries for AI and machine learning in systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_ai_roles;
DROP VIEW IF EXISTS v_hybrid_architectures;
DROP VIEW IF EXISTS v_governance_dimensions;
DROP VIEW IF EXISTS v_data_risk_register;
DROP VIEW IF EXISTS v_constraint_types;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_validation_targets;
DROP VIEW IF EXISTS v_model_metrics_summary;

DROP TABLE IF EXISTS model_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS constraint_types;
DROP TABLE IF EXISTS data_risk_register;
DROP TABLE IF EXISTS governance_dimensions;
DROP TABLE IF EXISTS hybrid_architectures;
DROP TABLE IF EXISTS ai_roles;

CREATE TABLE ai_roles (
  ai_role TEXT PRIMARY KEY,
  systems_modeling_use TEXT NOT NULL,
  example TEXT NOT NULL,
  primary_risk TEXT NOT NULL,
  responsible_practice TEXT NOT NULL
);

CREATE TABLE hybrid_architectures (
  architecture TEXT PRIMARY KEY,
  structural_component TEXT NOT NULL,
  machine_learning_component TEXT NOT NULL,
  best_use TEXT NOT NULL,
  main_caution TEXT NOT NULL
);

CREATE TABLE governance_dimensions (
  governance_area TEXT PRIMARY KEY,
  systems_modeling_question TEXT NOT NULL,
  responsible_practice TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE data_risk_register (
  data_issue TEXT PRIMARY KEY,
  systems_modeling_consequence TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL,
  mitigation TEXT NOT NULL
);

CREATE TABLE constraint_types (
  constraint_type TEXT PRIMARY KEY,
  systems_modeling_example TEXT NOT NULL,
  machine_learning_implication TEXT NOT NULL,
  validation_check TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  n INTEGER NOT NULL,
  noise_scale REAL NOT NULL,
  structural_weight REAL NOT NULL,
  residual_strength REAL NOT NULL,
  interaction_strength REAL NOT NULL,
  drift_strength REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE model_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  model_name TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO ai_roles VALUES
('pattern_detection', 'identify_structure_in_high_dimensional_data', 'detect_recurring_failure_patterns_in_infrastructure_sensor_data', 'spurious_correlations', 'connect_patterns_to_domain_review_and_system_structure'),
('parameter_estimation', 'estimate_values_that_are_difficult_to_measure_directly', 'infer_behavioral_response_rates_in_an_agent_based_model', 'overfitting_or_weak_domain_validity', 'use_holdout_validation_sensitivity_analysis_and_plausible_ranges'),
('surrogate_modeling', 'approximate_expensive_simulations_quickly', 'emulate_a_hydrological_climate_traffic_or_energy_model', 'emulator_failure_outside_training_domain', 'map_valid_operating_domain_and_report_uncertainty'),
('residual_learning', 'correct_systematic_errors_in_a_structural_model', 'learn_difference_between_simulated_and_observed_demand', 'masking_structural_model_error', 'use_residuals_as_diagnostics_not_only_prediction_patches'),
('anomaly_detection', 'flag_unusual_system_behavior', 'detect_unexpected_grid_supply_chain_or_hospital_stress', 'false_alarms_or_missed_events', 'define_escalation_thresholds_and_human_review'),
('adaptive_updating', 'update_model_components_as_new_data_arrive', 'refresh_demand_forecasts_in_a_digital_twin', 'silent_drift_and_model_instability', 'monitor_drift_and_version_model_changes'),
('feature_extraction', 'convert_raw_data_into_model_inputs', 'extract_land_cover_patterns_from_satellite_imagery', 'measurement_bias_or_scale_mismatch', 'audit_data_provenance_and_spatial_temporal_resolution'),
('scenario_clustering', 'group_model_runs_into_interpretable_families', 'identify_common_failure_modes_across_simulations', 'overcompression_of_system_diversity', 'preserve_traceability_to_original_runs');

INSERT INTO hybrid_architectures VALUES
('direct_prediction', 'minimal_or_external', 'learns_output_from_features', 'forecasting_where_explanation_is_secondary', 'weak_causal_interpretation'),
('surrogate_model', 'original_simulation_defines_behavior', 'learns_fast_approximation_of_simulation_output', 'scenario_sweeps_sensitivity_analysis_and_optimization', 'can_fail_outside_training_domain'),
('residual_learning', 'structural_model_gives_baseline', 'learns_systematic_model_error', 'improving_predictions_while_preserving_structure', 'can_hide_deeper_model_misspecification'),
('parameter_learning', 'simulation_uses_interpretable_parameters', 'estimates_parameter_values_from_data', 'calibration_and_adaptive_modeling', 'parameter_estimates_can_overfit_or_drift'),
('constraint_aware_learning', 'known_laws_rules_or_limits_shape_admissible_behavior', 'learns_within_structural_limits', 'engineering_environmental_climate_and_physical_systems', 'constraints_may_be_incomplete_or_wrongly_encoded'),
('adaptive_digital_twin', 'system_model_represents_current_operational_state', 'updates_forecasts_or_detects_anomalies_from_live_data', 'infrastructure_energy_logistics_health_and_industrial_systems', 'real_time_models_require_real_time_governance');

INSERT INTO governance_dimensions VALUES
('purpose_definition', 'what_decision_or_analysis_is_the_ai_enhanced_model_meant_to_support', 'define_use_cases_prohibited_uses_and_decision_boundaries', 'model_is_reused_for_unapproved_decisions'),
('data_governance', 'what_data_are_used_from_whom_under_what_authority_and_with_what_limits', 'document_provenance_privacy_consent_minimization_and_retention_rules', 'data_lineage_is_unknown'),
('model_validation', 'does_the_model_work_across_scenarios_groups_time_and_stress_conditions', 'use_technical_validation_domain_review_subgroup_testing_and_stress_testing', 'only_aggregate_accuracy_is_reported'),
('transparency', 'can_users_understand_the_model_purpose_assumptions_and_limits', 'maintain_model_cards_documentation_assumption_logs_and_uncertainty_statements', 'no_one_can_explain_model_limits'),
('human_oversight', 'who_reviews_outputs_and_remains_accountable', 'define_review_roles_override_rules_escalation_paths_and_audit_trails', 'users_treat_outputs_as_orders'),
('monitoring', 'does_model_performance_change_after_deployment', 'track_drift_error_subgroup_performance_and_unintended_consequences', 'no_post_deployment_monitoring_exists'),
('public_accountability', 'who_can_question_or_contest_model_supported_decisions', 'provide_meaningful_contestability_appeal_and_governance_mechanisms', 'affected_people_cannot_challenge_outputs');

INSERT INTO data_risk_register VALUES
('sampling_bias', 'model_learns_from_a_distorted_population_or_system_state', 'who_or_what_is_missing_from_the_dataset', 'compare_coverage_to_system_boundary_and_known_population'),
('measurement_error', 'model_learns_noisy_or_inaccurate_relationships', 'how_were_variables_measured_and_validated', 'document_measurement_process_and_uncertainty'),
('historical_bias', 'model_reproduces_past_inequities_or_institutional_patterns', 'does_the_dataset_encode_unfair_or_outdated_decisions', 'audit_features_labels_and_outcomes_for_structural_bias'),
('temporal_drift', 'model_performance_degrades_as_system_behavior_changes', 'how_often_must_the_model_be_recalibrated', 'monitor_error_over_time_and_trigger_review'),
('proxy_variables', 'features_indirectly_encode_sensitive_or_structural_conditions', 'what_does_each_feature_actually_represent', 'review_feature_meaning_and_subgroup_effects'),
('scale_mismatch', 'data_resolution_does_not_match_the_system_process_being_modeled', 'are_spatial_temporal_or_organizational_scales_aligned', 'match_data_resolution_to_model_processes'),
('feedback_contamination', 'data_reflect_earlier_model_decisions_or_policy_interventions', 'has_the_system_changed_because_of_prior_analytics', 'track_deployment_effects_and_data_generating_process');

INSERT INTO constraint_types VALUES
('conservation', 'mass_water_energy_carbon_or_material_balance', 'penalize_predictions_that_violate_balance_equations', 'conservation_residual_remains_within_tolerance'),
('capacity', 'infrastructure_throughput_hospital_beds_grid_capacity_or_logistics_limits', 'bound_outputs_by_feasible_system_capacity', 'predictions_do_not_exceed_capacity_without_flag'),
('nonnegativity', 'population_inventory_backlog_emissions_cost_cases_or_demand', 'prevent_impossible_negative_values', 'all_nonnegative_variables_remain_nonnegative'),
('temporal_ordering', 'policy_effects_cannot_precede_implementation', 'respect_lag_delay_and_causally_plausible_timing', 'predicted_effects_do_not_precede_inputs'),
('network_structure', 'flows_depend_on_connectivity_and_edge_constraints', 'learn_within_graph_topology_and_flow_limits', 'flows_do_not_cross_missing_edges'),
('institutional_rules', 'eligibility_budget_authority_service_boundaries_or_legal_constraints', 'represent_policy_and_governance_constraints_explicitly', 'outputs_respect_defined_rule_set');

INSERT INTO scenario_definitions VALUES
('baseline_hybrid', 1000, 0.50, 1.00, 0.70, 0.25, 0.00, 'Baseline structural model with nonlinear residual learning opportunity'),
('high_noise_system', 1000, 0.95, 1.00, 0.70, 0.25, 0.00, 'Noisier system makes residual learning harder'),
('strong_residual_system', 1000, 0.50, 1.00, 1.10, 0.38, 0.00, 'Large unmodeled residual creates strong hybrid improvement'),
('weak_structure_system', 1000, 0.50, 0.65, 0.90, 0.32, 0.00, 'Structural baseline is weaker and residual learner carries more burden'),
('drifting_system', 1000, 0.55, 1.00, 0.70, 0.25, 0.45, 'Data generating process shifts over observation index'),
('low_noise_system', 1000, 0.25, 1.00, 0.70, 0.25, 0.00, 'Lower noise makes model comparison clearer');

INSERT INTO validation_targets VALUES
('rmse', 0, 1000000, 'RMSE should be nonnegative and finite'),
('mae', 0, 1000000, 'MAE should be nonnegative and finite'),
('hybrid_improvement_ratio', -1000000, 1000000, 'Positive values mean hybrid improved over baseline'),
('baseline_rmse', 0, 1000000, 'Baseline RMSE should be finite'),
('hybrid_rmse', 0, 1000000, 'Hybrid RMSE should be finite'),
('baseline_mae', 0, 1000000, 'Baseline MAE should be finite'),
('hybrid_mae', 0, 1000000, 'Hybrid MAE should be finite');

INSERT INTO model_metrics VALUES
(NULL, 'baseline_hybrid', 'structural_baseline', 'rmse', 2.50, 'Illustrative structural baseline error'),
(NULL, 'baseline_hybrid', 'hybrid_residual_learning', 'rmse', 0.60, 'Illustrative hybrid residual-learning error'),
(NULL, 'high_noise_system', 'structural_baseline', 'rmse', 2.80, 'Illustrative high-noise baseline error'),
(NULL, 'high_noise_system', 'hybrid_residual_learning', 'rmse', 1.10, 'Illustrative high-noise hybrid error'),
(NULL, 'drifting_system', 'structural_baseline', 'rmse', 2.70, 'Illustrative drifting baseline error'),
(NULL, 'drifting_system', 'hybrid_residual_learning', 'rmse', 0.90, 'Illustrative drifting hybrid error');

CREATE VIEW v_ai_roles AS
SELECT ai_role, systems_modeling_use, example, primary_risk, responsible_practice
FROM ai_roles
ORDER BY ai_role;

CREATE VIEW v_hybrid_architectures AS
SELECT architecture, structural_component, machine_learning_component, best_use, main_caution
FROM hybrid_architectures
ORDER BY architecture;

CREATE VIEW v_governance_dimensions AS
SELECT governance_area, systems_modeling_question, responsible_practice, warning_sign
FROM governance_dimensions
ORDER BY governance_area;

CREATE VIEW v_data_risk_register AS
SELECT data_issue, systems_modeling_consequence, diagnostic_question, mitigation
FROM data_risk_register
ORDER BY data_issue;

CREATE VIEW v_constraint_types AS
SELECT constraint_type, systems_modeling_example, machine_learning_implication, validation_check
FROM constraint_types
ORDER BY constraint_type;

CREATE VIEW v_scenario_definitions AS
SELECT *
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

CREATE VIEW v_model_metrics_summary AS
SELECT
  scenario,
  model_name,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM model_metrics
GROUP BY scenario, model_name, metric_name
ORDER BY scenario, model_name, metric_name;

.headers on
.mode column

SELECT * FROM v_ai_roles;
SELECT * FROM v_hybrid_architectures;
SELECT * FROM v_governance_dimensions;
SELECT * FROM v_data_risk_register;
SELECT * FROM v_constraint_types;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_validation_targets;
SELECT * FROM v_model_metrics_summary;
