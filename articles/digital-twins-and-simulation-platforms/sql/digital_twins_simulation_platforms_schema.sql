-- digital_twins_simulation_platforms_schema.sql
-- SQLite schema and analysis queries for digital twins and simulation platforms.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_digital_twin_components;
DROP VIEW IF EXISTS v_operating_loop;
DROP VIEW IF EXISTS v_platform_layers;
DROP VIEW IF EXISTS v_governance_register;
DROP VIEW IF EXISTS v_validation_dimensions;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_twin_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS twin_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS validation_dimensions;
DROP TABLE IF EXISTS governance_register;
DROP TABLE IF EXISTS platform_layers;
DROP TABLE IF EXISTS operating_loop;
DROP TABLE IF EXISTS digital_twin_components;

CREATE TABLE digital_twin_components (
  component TEXT PRIMARY KEY,
  function TEXT NOT NULL,
  design_question TEXT NOT NULL,
  system_risk TEXT NOT NULL
);

CREATE TABLE operating_loop (
  loop_stage TEXT PRIMARY KEY,
  technical_requirement TEXT NOT NULL,
  governance_requirement TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE platform_layers (
  platform_layer TEXT PRIMARY KEY,
  purpose TEXT NOT NULL,
  failure_mode TEXT NOT NULL,
  control TEXT NOT NULL
);

CREATE TABLE governance_register (
  governance_area TEXT PRIMARY KEY,
  digital_twin_question TEXT NOT NULL,
  responsible_practice TEXT NOT NULL,
  warning_sign TEXT NOT NULL
);

CREATE TABLE validation_dimensions (
  validation_dimension TEXT PRIMARY KEY,
  question TEXT NOT NULL,
  evidence TEXT NOT NULL,
  common_failure TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  n_steps INTEGER NOT NULL,
  initial_state REAL NOT NULL,
  state_persistence REAL NOT NULL,
  drift_amplitude REAL NOT NULL,
  process_noise REAL NOT NULL,
  observation_noise REAL NOT NULL,
  update_gain REAL NOT NULL,
  anomaly_threshold REAL NOT NULL,
  intervention_effect REAL NOT NULL,
  shock_times TEXT NOT NULL,
  shock_magnitude REAL NOT NULL,
  seed INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE twin_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO digital_twin_components VALUES
('physical_asset_or_system', 'real_world_counterpart_whose_behavior_the_twin_represents', 'what_exactly_is_included_in_the_system_boundary', 'wrong_boundary_creates_misleading_state_estimates'),
('sensor_and_data_layer', 'collects_measurements_telemetry_logs_inspections_or_external_data', 'are_observations_accurate_timely_representative_and_secure', 'poor_observations_distort_the_twin'),
('data_pipeline', 'moves_cleans_validates_stores_and_transforms_data_for_model_use', 'how_are_missingness_delay_errors_and_provenance_handled', 'weak_pipeline_creates_silent_failure_modes'),
('model_layer', 'simulates_structure_dynamics_constraints_failure_modes_or_behavior', 'which_modeling_approach_is_appropriate_for_the_system', 'wrong_model_fidelity_creates_false_confidence'),
('synchronization_layer', 'updates_model_state_or_parameters_using_new_observations', 'how_does_the_twin_decide_what_the_current_state_is', 'poor_synchronization_creates_state_drift'),
('analytics_layer', 'detects_anomalies_forecasts_conditions_estimates_risk_or_compares_interventions', 'what_outputs_are_reliable_enough_for_operational_use', 'opaque_analytics_can_drive_bad_decisions'),
('interface_layer', 'presents_results_to_operators_analysts_managers_engineers_or_policymakers', 'how_are_uncertainty_assumptions_and_alerts_communicated', 'polished_interfaces_can_hide_uncertainty'),
('governance_layer', 'controls_access_accountability_validation_privacy_security_and_acceptable_use', 'who_is_responsible_when_the_twin_is_wrong_or_misused', 'unclear_accountability_raises_operational_risk');

INSERT INTO operating_loop VALUES
('observe', 'reliable_sensing_and_data_capture', 'consent_privacy_authority_and_data_minimization_where_people_are_affected', 'what_observations_enter_the_twin'),
('validate_data', 'quality_checks_timestamps_error_detection_and_provenance', 'documentation_and_auditability', 'which_observations_are_rejected_or_flagged'),
('estimate_state', 'filtering_inference_calibration_and_uncertainty_representation', 'clear_communication_of_confidence_and_limits', 'what_is_the_current_estimated_state'),
('compare', 'residual_analysis_anomaly_detection_and_threshold_rules', 'escalation_rules_and_human_review', 'does_observed_behavior_match_expected_behavior'),
('simulate', 'scenario_engine_constraints_and_model_fidelity', 'transparent_assumptions_and_valid_operating_domain', 'what_futures_or_interventions_are_tested'),
('evaluate', 'performance_metrics_and_tradeoff_analysis', 'accountability_for_objectives_and_value_choices', 'which_action_has_lower_expected_risk_or_loss'),
('decide', 'decision_workflow_integration', 'defined_authority_contestability_and_responsibility', 'who_acts_on_the_twin_output'),
('learn', 'model_updating_and_version_control', 'change_management_and_drift_monitoring', 'how_does_the_twin_change_after_new_evidence');

INSERT INTO platform_layers VALUES
('data_ingestion', 'receives_sensor_telemetry_inspection_operational_and_external_data', 'missing_delayed_duplicate_corrupted_or_insecure_data', 'timestamp_validation_schema_checks_and_source_authentication'),
('data_management', 'stores_versions_cleans_and_documents_data', 'untraceable_data_lineage_or_inconsistent_definitions', 'data_catalog_versioning_and_provenance_records'),
('simulation_engine', 'runs_system_models_under_current_or_hypothetical_conditions', 'model_too_slow_oversimplified_or_poorly_calibrated', 'tiered_fidelity_model_reduction_and_validation'),
('analytics_engine', 'detects_anomalies_forecasts_risk_estimates_hidden_states_or_recommends_actions', 'false_alarms_opaque_predictions_or_unstable_performance', 'threshold_review_backtesting_and_human_escalation'),
('visualization_layer', 'communicates_current_state_scenarios_alerts_and_uncertainty', 'dashboard_clarity_creates_false_confidence_or_hides_uncertainty', 'uncertainty_display_and_assumption_disclosure'),
('integration_layer', 'connects_twin_to_operational_tools_maintenance_systems_or_decision_workflows', 'model_outputs_used_without_appropriate_review_or_context', 'role_based_access_and_decision_workflow_controls'),
('security_layer', 'protects_data_models_interfaces_and_operational_connections', 'cyber_intrusion_data_poisoning_unauthorized_access_or_model_manipulation', 'access_control_monitoring_logging_and_incident_response');

INSERT INTO governance_register VALUES
('authority', 'who_is_allowed_to_operate_modify_or_rely_on_the_twin', 'define_roles_access_levels_and_change_control_procedures', 'unapproved_users_can_change_model_parameters'),
('data_security', 'how_are_data_streams_protected_from_intrusion_or_manipulation', 'use_encryption_authentication_monitoring_logging_and_secure_architecture', 'telemetry_is_accepted_without_integrity_checks'),
('model_integrity', 'how_are_model_versions_parameters_and_updates_protected', 'use_version_control_audit_trails_review_gates_and_rollback_procedures', 'model_changes_are_not_traceable'),
('privacy', 'does_the_twin_expose_information_about_people_households_workers_or_communities', 'apply_minimization_aggregation_access_controls_consent_where_appropriate_and_privacy_review', 'personal_or_location_data_are_overexposed'),
('validation', 'how_is_the_twin_tested_before_and_after_deployment', 'use_calibration_stress_testing_drift_monitoring_and_independent_review', 'model_is_deployed_without_operating_domain_limits'),
('decision_accountability', 'who_is_responsible_when_model_supported_decisions_cause_harm', 'define_human_oversight_escalation_rules_contestability_and_responsibility', 'operators_cannot_override_or_challenge_alerts'),
('public_legitimacy', 'can_affected_communities_understand_and_question_the_use_of_the_twin', 'provide_transparency_consultation_and_governance_where_public_systems_are_involved', 'public_systems_are_modeled_without_visible_accountability');

INSERT INTO validation_dimensions VALUES
('structural_validity', 'does_the_model_represent_key_mechanisms_and_constraints', 'domain_review_engineering_review_causal_review_and_assumption_documentation', 'model_omits_critical_feedback_or_capacity_constraints'),
('state_tracking_accuracy', 'does_the_twin_estimate_current_system_state_accurately_enough', 'comparison_against_trusted_measurements_inspections_or_ground_truth', 'twin_tracks_sensor_noise_instead_of_true_state'),
('predictive_performance', 'does_the_twin_forecast_relevant_outcomes_within_acceptable_error', 'holdout_tests_backtesting_forecast_error_and_scenario_validation', 'forecasts_fail_under_unusual_conditions'),
('anomaly_detection_quality', 'does_the_twin_detect_meaningful_deviations_without_excessive_false_alarms', 'precision_recall_event_review_and_alert_fatigue_analysis', 'alert_thresholds_are_too_sensitive_or_too_blunt'),
('robustness', 'does_performance_hold_under_shocks_missing_data_or_unusual_conditions', 'stress_tests_missing_data_tests_and_out_of_distribution_scenarios', 'twin_fails_when_data_are_delayed_or_missing'),
('drift_monitoring', 'does_the_twin_remain_valid_as_system_behavior_changes', 'residual_tracking_parameter_drift_and_periodic_recalibration_review', 'old_calibration_is_kept_after_system_change'),
('decision_usefulness', 'do_outputs_improve_decisions_without_creating_harmful_dependency', 'user_review_operational_evaluation_and_post_deployment_monitoring', 'operators_overtrust_outputs_without_context');

INSERT INTO scenario_definitions VALUES
('baseline_twin', 120, 50, 0.95, 0.15, 0.60, 1.80, 0.35, 3.50, 1.00, '35|80|105', 4.0, 42, 'Baseline digital twin state tracking with recurring shocks'),
('high_noise_twin', 120, 50, 0.95, 0.15, 0.60, 3.20, 0.30, 4.80, 1.00, '35|80|105', 4.0, 43, 'Noisier observations make synchronization harder'),
('shock_heavy_twin', 120, 50, 0.95, 0.15, 0.75, 1.80, 0.35, 3.50, 1.00, '25|45|65|85|105', 5.5, 44, 'More frequent and larger shocks create repeated anomalies'),
('slow_update_twin', 120, 50, 0.95, 0.15, 0.60, 1.80, 0.18, 3.50, 1.00, '35|80|105', 4.0, 45, 'Lower update gain makes the twin slower to synchronize'),
('resilient_twin', 120, 50, 0.95, 0.15, 0.45, 1.25, 0.45, 3.25, 1.25, '35|80|105', 3.5, 46, 'Better sensing and stronger update behavior improve tracking'),
('sensor_drift_twin', 120, 50, 0.95, 0.15, 0.60, 1.80, 0.35, 3.50, 1.00, '35|80|105', 4.0, 47, 'Observation stream includes gradual sensor drift in the workflow');

INSERT INTO validation_targets VALUES
('MAE_observed', 0, 1000000, 'Observed MAE should be nonnegative and finite'),
('MAE_twin', 0, 1000000, 'Twin MAE should be nonnegative and finite'),
('RMSE_observed', 0, 1000000, 'Observed RMSE should be nonnegative and finite'),
('RMSE_twin', 0, 1000000, 'Twin RMSE should be nonnegative and finite'),
('anomaly_count', 0, 1000000, 'Anomaly count should be nonnegative'),
('intervention_count', 0, 1000000, 'Intervention count should be nonnegative'),
('tracking_improvement_ratio', -1000000, 1000000, 'Positive values mean the twin improved over noisy observations');

INSERT INTO twin_metrics VALUES
(NULL, 'baseline_twin', 'MAE_twin', 1.10, 'Illustrative twin state-tracking error'),
(NULL, 'baseline_twin', 'MAE_observed', 1.80, 'Illustrative raw observation error'),
(NULL, 'high_noise_twin', 'MAE_twin', 1.90, 'Illustrative noisy twin tracking error'),
(NULL, 'high_noise_twin', 'MAE_observed', 3.20, 'Illustrative noisy observation error'),
(NULL, 'resilient_twin', 'MAE_twin', 0.80, 'Illustrative resilient twin tracking error'),
(NULL, 'resilient_twin', 'MAE_observed', 1.25, 'Illustrative improved observation quality');

CREATE VIEW v_digital_twin_components AS
SELECT component, function, design_question, system_risk
FROM digital_twin_components
ORDER BY component;

CREATE VIEW v_operating_loop AS
SELECT loop_stage, technical_requirement, governance_requirement, diagnostic_question
FROM operating_loop
ORDER BY
  CASE loop_stage
    WHEN 'observe' THEN 1
    WHEN 'validate_data' THEN 2
    WHEN 'estimate_state' THEN 3
    WHEN 'compare' THEN 4
    WHEN 'simulate' THEN 5
    WHEN 'evaluate' THEN 6
    WHEN 'decide' THEN 7
    WHEN 'learn' THEN 8
    ELSE 99
  END;

CREATE VIEW v_platform_layers AS
SELECT platform_layer, purpose, failure_mode, control
FROM platform_layers
ORDER BY platform_layer;

CREATE VIEW v_governance_register AS
SELECT governance_area, digital_twin_question, responsible_practice, warning_sign
FROM governance_register
ORDER BY governance_area;

CREATE VIEW v_validation_dimensions AS
SELECT validation_dimension, question, evidence, common_failure
FROM validation_dimensions
ORDER BY validation_dimension;

CREATE VIEW v_scenario_definitions AS
SELECT *
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_twin_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM twin_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT metric, target_low, target_high, notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_digital_twin_components;
SELECT * FROM v_operating_loop;
SELECT * FROM v_platform_layers;
SELECT * FROM v_governance_register;
SELECT * FROM v_validation_dimensions;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_twin_metric_summary;
SELECT * FROM v_validation_targets;
