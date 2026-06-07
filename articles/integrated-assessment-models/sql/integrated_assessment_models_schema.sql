PRAGMA foreign_keys = ON;
DROP VIEW IF EXISTS v_iam_system_components;
DROP VIEW IF EXISTS v_iam_feedback_loops;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_ethics_dimensions;
DROP VIEW IF EXISTS v_validation_targets;
DROP TABLE IF EXISTS iam_system_components;
DROP TABLE IF EXISTS iam_feedback_loops;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS ethics_dimensions;
DROP TABLE IF EXISTS validation_targets;

CREATE TABLE iam_system_components(component TEXT PRIMARY KEY, system_role TEXT, modeling_representation TEXT, diagnostic_question TEXT);
CREATE TABLE iam_feedback_loops(feedback_loop TEXT PRIMARY KEY, loop_type TEXT, integrated_assessment_mechanism TEXT, system_risk TEXT);
CREATE TABLE modeling_approaches(approach TEXT PRIMARY KEY, best_suited_for TEXT, key_diagnostic TEXT, professional_caution TEXT);
CREATE TABLE scenario_definitions(scenario TEXT PRIMARY KEY, start_year INTEGER, end_year INTEGER, step INTEGER, initial_output REAL, productivity_growth REAL, initial_emissions_intensity REAL, emissions_intensity_decline REAL, mitigation_start REAL, mitigation_growth REAL, max_mitigation REAL, damage_coefficient REAL, mitigation_cost_scale REAL, discount_rate REAL, description TEXT);
CREATE TABLE ethics_dimensions(dimension TEXT PRIMARY KEY, iam_issue TEXT, modeling_implication TEXT, professional_caution TEXT);
CREATE TABLE validation_targets(metric TEXT PRIMARY KEY, target_low REAL, target_high REAL, notes TEXT);

INSERT INTO iam_system_components VALUES
('economic_module','production_consumption_investment_welfare_and_damages','growth_or_welfare_model','How_do_output_costs_damages_and_welfare_interact'),
('energy_system_module','energy_demand_fuels_infrastructure_and_technology_substitution','technology_portfolio_and_cost_curves','Which_energy_assumptions_shape_emissions'),
('emissions_module','links_activity_to_greenhouse_gas_emissions','emissions_intensity_and_abatement_rates','How_do_output_intensity_and_mitigation_create_emissions'),
('climate_module','links_emissions_to_concentrations_forcing_and_temperature','carbon_cycle_and_temperature_proxy','How_do_emissions_translate_into_climate_pressure'),
('policy_module','represents_carbon_prices_caps_standards_and_targets','policy_scenarios_and_constraints','How_do_policy_assumptions_change_trajectories');

INSERT INTO iam_feedback_loops VALUES
('growth_energy_emissions','reinforcing','growth_increases_energy_demand_and_emissions_when_carbon_intensity_remains_high','lock_in_risk'),
('mitigation_learning_cost','reinforcing','deployment_supports_learning_and_cost_decline','path_dependence'),
('damages_output_welfare','balancing_or_reinforcing','climate_damages_affect_output_and_welfare','damage_understatement'),
('delayed_action_transition_pressure','reinforcing','delay_increases_later_abatement_pressure','feasibility_risk'),
('discounting_future_damages','balancing','discounting_reduces_weight_of_future_damages','ethical_assumption_risk');

INSERT INTO modeling_approaches VALUES
('aggregated_climate_economy_modeling','welfare_damage_mitigation_and_social_cost_of_carbon','discounting_damages_temperature_and_welfare','aggregation_hides_distribution'),
('energy_economy_modeling','technology_portfolios_and_transition_costs','energy_mix_emissions_intensity_deployment_rate','technology_assumptions_drive_results'),
('scenario_based_iam','comparison_of_policy_technology_and_development_futures','pathway_divergence_and_robust_patterns','scenario_framing_shapes_interpretation'),
('model_intercomparison','robustness_testing_across_iams','cross_model_spread_and_common_findings','shared_blind_spots_can_remain');

INSERT INTO scenario_definitions VALUES
('delayed_transition',2025,2100,5,100,0.012,0.42,0.006,0.02,0.010,0.90,0.012,0.040,0.015,'Slow transition'),
('moderate_transition',2025,2100,5,100,0.012,0.42,0.012,0.06,0.025,0.95,0.010,0.040,0.015,'Moderate transition'),
('accelerated_decarbonization',2025,2100,5,100,0.012,0.42,0.018,0.10,0.045,0.98,0.008,0.055,0.015,'Accelerated decarbonization'),
('high_innovation_pathway',2025,2100,5,100,0.013,0.42,0.026,0.08,0.040,0.98,0.008,0.038,0.015,'High innovation pathway');

INSERT INTO ethics_dimensions VALUES
('discounting','discount_rates_change_future_weighting','test_multiple_discount_rates','not_purely_technical'),
('aggregation','averages_hide_inequality','disaggregate_where_possible','aggregate_welfare_obscures_harm'),
('technology_optimism','speculative_future_deployment_can_drive_pathways','stress_test_technology_limits','optimism_can_justify_delay'),
('land_justice','land_mitigation_affects_food_ecology_and_livelihoods','include_land_tradeoff_diagnostics','land_is_not_empty_space'),
('false_precision','long_horizon_outputs_look_certain','report_ranges_and_assumptions','precise_numbers_can_mislead');

INSERT INTO validation_targets VALUES
('output',0,1000000,'Output should remain nonnegative'),
('mitigation_rate',0,1,'Mitigation rate should remain bounded'),
('emissions',0,1000000,'Emissions should remain nonnegative'),
('temperature_proxy',0,1000000,'Temperature proxy should remain finite'),
('damages',0,1000000,'Damages should remain nonnegative'),
('discounted_welfare_proxy',-1000000,1000000,'Welfare proxy should remain finite');

CREATE VIEW v_iam_system_components AS SELECT * FROM iam_system_components ORDER BY component;
CREATE VIEW v_iam_feedback_loops AS SELECT * FROM iam_feedback_loops ORDER BY feedback_loop;
CREATE VIEW v_modeling_approaches AS SELECT * FROM modeling_approaches ORDER BY approach;
CREATE VIEW v_scenario_definitions AS SELECT * FROM scenario_definitions ORDER BY scenario;
CREATE VIEW v_ethics_dimensions AS SELECT * FROM ethics_dimensions ORDER BY dimension;
CREATE VIEW v_validation_targets AS SELECT * FROM validation_targets ORDER BY metric;
.headers on
.mode column
SELECT * FROM v_iam_system_components;
SELECT * FROM v_iam_feedback_loops;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_ethics_dimensions;
SELECT * FROM v_validation_targets;
