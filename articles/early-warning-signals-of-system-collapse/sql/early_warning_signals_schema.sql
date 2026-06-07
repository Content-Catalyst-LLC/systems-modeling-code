-- early_warning_signals_schema.sql
-- SQLite schema and analysis queries for early warning signals of system collapse.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_early_warning_indicators;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_domain_warning_examples;
DROP VIEW IF EXISTS v_network_warning_examples;
DROP VIEW IF EXISTS v_spatial_warning_examples;
DROP VIEW IF EXISTS v_warning_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS warning_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS spatial_warning_examples;
DROP TABLE IF EXISTS network_warning_examples;
DROP TABLE IF EXISTS domain_warning_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS early_warning_indicators;

CREATE TABLE early_warning_indicators (
  indicator TEXT PRIMARY KEY,
  system_meaning TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE scenario_definitions (
  scenario TEXT PRIMARY KEY,
  steps INTEGER NOT NULL,
  stability_start REAL NOT NULL,
  stability_end REAL NOT NULL,
  noise_sd REAL NOT NULL,
  window INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE domain_warning_examples (
  domain TEXT PRIMARY KEY,
  focal_variable TEXT NOT NULL,
  warning_signal TEXT NOT NULL,
  collapse_or_transition_risk TEXT NOT NULL,
  modeling_concern TEXT NOT NULL
);

CREATE TABLE network_warning_examples (
  network_system TEXT PRIMARY KEY,
  structural_warning_indicator TEXT NOT NULL,
  possible_instability_meaning TEXT NOT NULL,
  modeling_test TEXT NOT NULL
);

CREATE TABLE spatial_warning_examples (
  spatial_system TEXT PRIMARY KEY,
  spatial_warning_indicator TEXT NOT NULL,
  possible_instability_meaning TEXT NOT NULL,
  modeling_test TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE warning_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO early_warning_indicators (
  indicator,
  system_meaning,
  modeling_representation,
  diagnostic_question
) VALUES
('critical_slowing_down', 'recovery weakens as a system approaches a threshold', 'recovery rate or local stability parameter', 'Are perturbations decaying more slowly'),
('rolling_variance', 'fluctuations grow as stabilizing feedback weakens', 'moving-window variance', 'Are disturbances becoming more amplified'),
('lag1_autocorrelation', 'current state increasingly resembles recent past', 'moving-window lag-1 autocorrelation', 'Are deviations persisting longer over time'),
('recovery_time', 'time needed to return near baseline after disturbance', 'shock-response return time', 'Is recovery taking longer after comparable shocks'),
('skewness_change', 'state distribution becomes asymmetric near a boundary', 'moving-window skewness', 'Is the system drifting toward one side of state space'),
('flickering', 'temporary switching between alternative states', 'regime-state switching count', 'Is the system visiting an alternative regime before transition'),
('spatial_correlation', 'neighboring units become more similar in stress', 'spatial autocorrelation or clustering', 'Is stress becoming spatially coherent'),
('patchiness', 'spatial pattern becomes fragmented or clustered', 'patch-size and fragmentation metrics', 'Is landscape organization changing before collapse'),
('centrality_concentration', 'dependencies concentrate in critical nodes', 'network centrality distribution', 'Are failure pathways becoming more concentrated'),
('modularity_loss', 'network modules become less able to contain failure', 'modularity or community structure', 'Can disruption still be contained');

INSERT INTO scenario_definitions (
  scenario,
  steps,
  stability_start,
  stability_end,
  noise_sd,
  window,
  description
) VALUES
('baseline_destabilization', 320, 0.55, 0.985, 1.00, 25, 'Stability parameter rises toward threshold under moderate noise'),
('moderate_destabilization', 320, 0.45, 0.900, 1.00, 25, 'Recovery weakens less severely than baseline'),
('high_noise_destabilization', 320, 0.55, 0.985, 1.40, 25, 'Higher noise makes indicator interpretation harder'),
('low_noise_destabilization', 320, 0.55, 0.985, 0.65, 25, 'Lower noise clarifies rolling signal behavior'),
('short_window', 320, 0.55, 0.985, 1.00, 15, 'Shorter window produces more volatile indicators'),
('long_window', 320, 0.55, 0.985, 1.00, 45, 'Longer window smooths indicators but delays detection'),
('rapid_destabilization', 220, 0.55, 0.990, 1.00, 25, 'Faster movement toward weak recovery'),
('slow_destabilization', 520, 0.55, 0.985, 1.00, 25, 'Slower movement produces longer monitoring record');

INSERT INTO domain_warning_examples (
  domain,
  focal_variable,
  warning_signal,
  collapse_or_transition_risk,
  modeling_concern
) VALUES
('ecology', 'vegetation_or_population_state', 'rolling_variance_and_autocorrelation', 'regime_shift_or_population_collapse', 'seasonality_sampling_and_external_forcing'),
('climate', 'ice_extent_circulation_or_temperature_indicator', 'variance_autocorrelation_or_spatial_coherence', 'tipping_element_transition', 'long_time_horizons_and_forcing_trends'),
('infrastructure', 'outage_duration_load_or_repair_delay', 'recovery_time_and_failure_clustering', 'cascading_failure_or_chronic_service_loss', 'network_dependency_and_capacity_thresholds'),
('finance', 'liquidity_spreads_or_volatility', 'volatility_autocorrelation_and_exposure_concentration', 'panic_withdrawal_or_contagion', 'expectation_feedback_and_counterparty_exposure'),
('public_health', 'bed_occupancy_wait_time_or_staffing_gap', 'recovery_time_queue_variance_and_capacity_margin', 'system_overload_or_delayed_care', 'reporting_delay_and_surge_thresholds'),
('organizations', 'error_rate_workload_or_turnover', 'variance_recovery_time_and_attrition_clustering', 'burnout_or_operational_breakdown', 'slow_capacity_erosion_and_measurement_artifacts'),
('public_institutions', 'trust_compliance_or_service_failure', 'volatility_spatial_clustering_and_legitimacy_decline', 'noncompliance_or_legitimacy_loss', 'measurement_validity_and_political_interpretation'),
('supply_chains', 'inventory_delay_or_supplier_failure', 'delay_variance_centrality_and_redundancy_loss', 'cascading_shortage_or_production_disruption', 'dependency_depth_and_rerouting_capacity');

INSERT INTO network_warning_examples (
  network_system,
  structural_warning_indicator,
  possible_instability_meaning,
  modeling_test
) VALUES
('power_grid', 'rising_load_to_capacity_ratio', 'components are closer to overload', 'simulate line failure and load redistribution'),
('supply_chain', 'dependency_concentration', 'flows rely on fewer critical suppliers', 'remove central suppliers and measure shortage propagation'),
('financial_network', 'counterparty_centrality', 'losses may spread through concentrated exposures', 'simulate default cascade and liquidity stress'),
('public_health_referrals', 'hub_dependency', 'patients depend on overloaded central facilities', 'simulate surge and referral diversion'),
('transportation_network', 'declining_redundant_paths', 'rerouting options are disappearing', 'simulate link closure and travel-time increase'),
('information_network', 'highly_clustered_misinformation_pathways', 'false signals can propagate rapidly', 'simulate diffusion from influential nodes');

INSERT INTO spatial_warning_examples (
  spatial_system,
  spatial_warning_indicator,
  possible_instability_meaning,
  modeling_test
) VALUES
('dryland_ecosystem', 'vegetation_patchiness', 'landscape may be approaching desertification', 'measure patch-size distribution and spatial correlation'),
('forest_landscape', 'canopy_stress_clustering', 'disturbance susceptibility may be spatially coherent', 'track clusters under drought and pest stress'),
('coral_reef', 'bleaching_coherence', 'thermal stress may exceed local recovery capacity', 'compare reef patches across heat events'),
('urban_infrastructure', 'outage_hotspots', 'service failure may be spatially concentrated', 'map repeated failures and repair delay'),
('public_health', 'demand_surge_clusters', 'capacity stress may concentrate geographically', 'compare service area demand and travel time'),
('food_system', 'crop_yield_correlation', 'common-mode climate stress may reduce regional diversity', 'measure yield covariance across production zones');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('state', -1000000, 1000000, 'System state should remain finite'),
('absolute_state', 0, 1000000, 'Absolute state should be nonnegative and finite'),
('stability', -1, 1, 'Autoregressive stability value should remain inside the configured range'),
('rolling_variance', 0, 1000000, 'Rolling variance should remain nonnegative and finite'),
('rolling_autocorrelation', -1, 1, 'Lag-1 autocorrelation should remain bounded when available'),
('variance_slope', -1000000, 1000000, 'Variance trend slope should remain finite'),
('autocorrelation_slope', -1000000, 1000000, 'Autocorrelation trend slope should remain finite'),
('maximum_abs_state', 0, 1000000, 'Maximum absolute state should remain nonnegative and finite');

INSERT INTO warning_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_destabilization', 'illustrative_final_stability', 0.985, 'Recovery weakens strongly as stability approaches one'),
('moderate_destabilization', 'illustrative_final_stability', 0.900, 'Recovery weakens less severely'),
('high_noise_destabilization', 'illustrative_noise_sd', 1.400, 'Higher noise complicates interpretation'),
('low_noise_destabilization', 'illustrative_noise_sd', 0.650, 'Lower noise clarifies signal behavior'),
('short_window', 'illustrative_window', 15, 'Shorter windows produce more volatile warning indicators'),
('long_window', 'illustrative_window', 45, 'Longer windows smooth signals but delay detection'),
('rapid_destabilization', 'illustrative_steps', 220, 'Rapid forcing leaves less monitoring time'),
('slow_destabilization', 'illustrative_steps', 520, 'Slow forcing provides more monitoring observations');

CREATE VIEW v_early_warning_indicators AS
SELECT
  indicator,
  system_meaning,
  modeling_representation,
  diagnostic_question
FROM early_warning_indicators
ORDER BY indicator;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  steps,
  stability_start,
  stability_end,
  noise_sd,
  window,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_domain_warning_examples AS
SELECT
  domain,
  focal_variable,
  warning_signal,
  collapse_or_transition_risk,
  modeling_concern
FROM domain_warning_examples
ORDER BY domain;

CREATE VIEW v_network_warning_examples AS
SELECT
  network_system,
  structural_warning_indicator,
  possible_instability_meaning,
  modeling_test
FROM network_warning_examples
ORDER BY network_system;

CREATE VIEW v_spatial_warning_examples AS
SELECT
  spatial_system,
  spatial_warning_indicator,
  possible_instability_meaning,
  modeling_test
FROM spatial_warning_examples
ORDER BY spatial_system;

CREATE VIEW v_warning_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM warning_metrics
GROUP BY scenario, metric_name
ORDER BY scenario, metric_name;

CREATE VIEW v_validation_targets AS
SELECT
  metric,
  target_low,
  target_high,
  notes
FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_early_warning_indicators;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_domain_warning_examples;
SELECT * FROM v_network_warning_examples;
SELECT * FROM v_spatial_warning_examples;
SELECT * FROM v_warning_metric_summary;
SELECT * FROM v_validation_targets;
