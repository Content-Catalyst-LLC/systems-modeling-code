-- economic_systems_modeling_schema.sql
-- SQLite schema and analysis queries for economic systems modeling.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_economic_system_components;
DROP VIEW IF EXISTS v_economic_feedback_loops;
DROP VIEW IF EXISTS v_modeling_approaches;
DROP VIEW IF EXISTS v_scenario_definitions;
DROP VIEW IF EXISTS v_sectoral_balance_examples;
DROP VIEW IF EXISTS v_economic_metric_summary;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS economic_metrics;
DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS sectoral_balance_examples;
DROP TABLE IF EXISTS scenario_definitions;
DROP TABLE IF EXISTS modeling_approaches;
DROP TABLE IF EXISTS economic_feedback_loops;
DROP TABLE IF EXISTS economic_system_components;

CREATE TABLE economic_system_components (
  component TEXT PRIMARY KEY,
  system_role TEXT NOT NULL,
  modeling_representation TEXT NOT NULL,
  diagnostic_question TEXT NOT NULL
);

CREATE TABLE economic_feedback_loops (
  feedback_loop TEXT PRIMARY KEY,
  loop_type TEXT NOT NULL,
  economic_mechanism TEXT NOT NULL,
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
  demand_sensitivity REAL NOT NULL,
  investment_sensitivity REAL NOT NULL,
  interest_rate REAL NOT NULL,
  depreciation REAL NOT NULL,
  credit_sensitivity REAL NOT NULL,
  shock_step INTEGER NOT NULL,
  shock_size REAL NOT NULL,
  seed INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE sectoral_balance_examples (
  sector TEXT PRIMARY KEY,
  balance_item TEXT NOT NULL,
  stock_or_flow TEXT NOT NULL,
  system_meaning TEXT NOT NULL,
  modeling_concern TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

CREATE TABLE economic_metrics (
  metric_id INTEGER PRIMARY KEY,
  scenario TEXT NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  interpretation TEXT NOT NULL
);

INSERT INTO economic_system_components (
  component,
  system_role,
  modeling_representation,
  diagnostic_question
) VALUES
('households', 'consume_save_borrow_work_and_respond_to_income', 'household_groups_budgets_debt_and_behavior_rules', 'How do income_prices_and_debt_shape_consumption'),
('firms', 'produce_invest_hire_price_and_innovate', 'production_capacity_inventories_costs_and_expectations', 'How do demand_and_costs_shape_output_and_investment'),
('financial_institutions', 'create_credit_manage_liquidity_and_transmit_stress', 'balance_sheets_lending_rules_and_exposure_networks', 'How does_credit_expand_or_contract'),
('government', 'taxes_spends_regulates_invests_and_stabilizes', 'policy_rules_fiscal_flows_transfers_and_public_investment', 'How does_policy_change_system_trajectories'),
('central_bank', 'influences_rates_liquidity_credit_conditions_and_expectations', 'interest_rate_rule_liquidity_facility_or_credit_parameter', 'How do_financial_conditions_affect_activity'),
('markets', 'coordinate_prices_quantities_wages_assets_and_expectations', 'clearing_rules_disequilibrium_adjustment_or_matching', 'How do_prices_and_quantities_adjust_over_time'),
('institutions', 'shape_incentives_rights_enforcement_trust_and_power', 'rules_constraints_governance_and_compliance_dynamics', 'How do_rules_shape_behavior_and_distribution'),
('resources_and_environment', 'provide_energy_materials_land_ecosystems_and_absorptive_capacity', 'resource_stocks_emissions_damage_and_constraints', 'How do_biophysical_limits_affect_economic_pathways');

INSERT INTO economic_feedback_loops (
  feedback_loop,
  loop_type,
  economic_mechanism,
  system_risk
) VALUES
('income_consumption', 'reinforcing', 'higher_income_supports_spending_output_and_employment', 'demand_contraction_can_become_self_reinforcing'),
('credit_asset_price', 'reinforcing', 'higher_asset_prices_expand_collateral_and_borrowing', 'speculative_bubble_and_financial_instability'),
('debt_service', 'balancing_or_destabilizing', 'rising_debt_service_constrains_spending_and_borrowing', 'debt_overhang_and_recessionary_pressure'),
('inventory_adjustment', 'balancing', 'low_inventory_triggers_production_and_high_inventory_triggers_cuts', 'oscillation_if_information_delays_are_large'),
('inflation_policy', 'balancing', 'policy_tightens_when_inflation_rises_and_eases_when_activity_weakens', 'overshoot_if_policy_effects_are_delayed'),
('technology_learning', 'reinforcing', 'deployment_creates_learning_cost_decline_and_more_deployment', 'lock_in_if_inferior_systems_gain_early_advantage'),
('trust_compliance', 'reinforcing', 'legitimate_institutions_increase_compliance_and_performance', 'trust_erosion_can_create_policy_failure');

INSERT INTO modeling_approaches (
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
) VALUES
('system_dynamics', 'feedback_accumulation_delay_policy_resistance_and_long_run_dynamics', 'stock_trajectories_loop_dominance_sensitivity_and_overshoot', 'feedback_structure_can_be_disputed_or_incomplete'),
('agent_based_modeling', 'heterogeneous_decisions_adaptation_emergence_and_behavioral_response', 'distributional_outcomes_agent_mechanisms_and_emergent_patterns', 'decision_rules_require_empirical_or_theoretical_support'),
('network_modeling', 'financial_supply_chain_trade_sector_and_institutional_interdependence', 'centrality_cascade_size_systemic_exposure_and_dependency_paths', 'missing_links_can_dominate_results'),
('stock_flow_consistent_modeling', 'balance_sheets_debt_dynamics_sectoral_flows_and_macro_finance', 'sectoral_surplus_deficit_patterns_and_accounting_consistency', 'model_can_be_accounting_consistent_but_behaviorally_weak'),
('input_output_modeling', 'sectoral_production_dependency_supply_chain_exposure_and_multipliers', 'direct_and_indirect_output_loss_sector_multipliers_and_bottlenecks', 'fixed_coefficients_may_miss_substitution_and_adaptation'),
('integrated_assessment_modeling', 'economy_energy_environment_climate_and_policy_pathways', 'emissions_damages_investment_needs_and_policy_tradeoffs', 'damage_functions_and_discounting_embed_value_judgments');

INSERT INTO scenario_definitions (
  scenario,
  n_steps,
  demand_sensitivity,
  investment_sensitivity,
  interest_rate,
  depreciation,
  credit_sensitivity,
  shock_step,
  shock_size,
  seed,
  description
) VALUES
('baseline_feedback', 120, 0.62, 0.16, 0.035, 0.045, 0.10, 70, -8, 42, 'Moderate demand investment and credit feedback'),
('higher_investment', 120, 0.62, 0.21, 0.035, 0.045, 0.10, 70, -8, 43, 'Higher investment response to demand'),
('tighter_credit', 120, 0.62, 0.16, 0.055, 0.045, 0.10, 70, -8, 44, 'Higher interest rate tightens investment and debt dynamics'),
('larger_shock', 120, 0.62, 0.16, 0.035, 0.045, 0.10, 70, -18, 45, 'Larger negative demand shock'),
('higher_debt_growth', 120, 0.62, 0.16, 0.035, 0.045, 0.18, 70, -8, 46, 'Credit expands more aggressively with investment'),
('weak_demand', 120, 0.52, 0.16, 0.035, 0.045, 0.10, 70, -8, 47, 'Lower consumption demand response'),
('rapid_depreciation', 120, 0.62, 0.16, 0.035, 0.070, 0.10, 70, -8, 48, 'Faster capital depreciation reduces capacity'),
('policy_support', 120, 0.66, 0.18, 0.030, 0.045, 0.10, 70, -4, 49, 'Stronger demand conditions and smaller shock');

INSERT INTO sectoral_balance_examples (
  sector,
  balance_item,
  stock_or_flow,
  system_meaning,
  modeling_concern
) VALUES
('households', 'saving_minus_investment', 'flow', 'private_household_financial_balance', 'distribution_and_debt_constraints_matter'),
('firms', 'investment_and_borrowing', 'flow_and_stock', 'productive_capacity_and_corporate_liabilities', 'investment_can_raise_capacity_and_fragility'),
('government', 'taxes_minus_spending', 'flow', 'public_sector_balance', 'one_sector_deficit_is_another_sector_surplus'),
('external_sector', 'imports_minus_exports', 'flow', 'rest_of_world_balance', 'trade_position_affects_domestic_sectoral_balances'),
('financial_sector', 'credit_assets_and_liabilities', 'stock_and_flow', 'intermediation_and_balance_sheet_exposure', 'financial_claims_transmit_risk'),
('environment', 'resource_stock_and_emissions_flow', 'stock_and_flow', 'biophysical_economic_boundary', 'throughput_and_damage_accumulate_over_time');

INSERT INTO validation_targets (
  metric,
  target_low,
  target_high,
  notes
) VALUES
('output', 0, 1000000, 'Output should remain nonnegative and finite'),
('capital', 0, 1000000, 'Capital stock should remain nonnegative and finite'),
('debt', 0, 1000000, 'Debt stock should remain nonnegative and finite'),
('fragility', 0, 1000000, 'Fragility ratio should remain nonnegative and finite'),
('consumption', 0, 1000000, 'Consumption should remain nonnegative and finite'),
('investment', 0, 1000000, 'Investment should remain nonnegative and finite'),
('debt_service', 0, 1000000, 'Debt service should remain nonnegative and finite'),
('demand_gap', -1000000, 1000000, 'Demand gap should remain finite');

INSERT INTO economic_metrics (
  scenario,
  metric_name,
  metric_value,
  interpretation
) VALUES
('baseline_feedback', 'illustrative_interest_rate', 0.035, 'Baseline financing condition'),
('higher_investment', 'illustrative_investment_sensitivity', 0.21, 'Higher investment response to output'),
('tighter_credit', 'illustrative_interest_rate', 0.055, 'Tighter credit condition'),
('larger_shock', 'illustrative_shock_size', -18.0, 'Larger negative demand shock'),
('higher_debt_growth', 'illustrative_credit_sensitivity', 0.18, 'Faster debt accumulation'),
('weak_demand', 'illustrative_demand_sensitivity', 0.52, 'Weaker consumption response'),
('rapid_depreciation', 'illustrative_depreciation', 0.070, 'Faster capital depreciation'),
('policy_support', 'illustrative_shock_size', -4.0, 'Policy support scenario with smaller shock');

CREATE VIEW v_economic_system_components AS
SELECT
  component,
  system_role,
  modeling_representation,
  diagnostic_question
FROM economic_system_components
ORDER BY component;

CREATE VIEW v_economic_feedback_loops AS
SELECT
  feedback_loop,
  loop_type,
  economic_mechanism,
  system_risk
FROM economic_feedback_loops
ORDER BY feedback_loop;

CREATE VIEW v_modeling_approaches AS
SELECT
  approach,
  best_suited_for,
  key_diagnostic,
  professional_caution
FROM modeling_approaches
ORDER BY approach;

CREATE VIEW v_scenario_definitions AS
SELECT
  scenario,
  n_steps,
  demand_sensitivity,
  investment_sensitivity,
  interest_rate,
  depreciation,
  credit_sensitivity,
  shock_step,
  shock_size,
  seed,
  description
FROM scenario_definitions
ORDER BY scenario;

CREATE VIEW v_sectoral_balance_examples AS
SELECT
  sector,
  balance_item,
  stock_or_flow,
  system_meaning,
  modeling_concern
FROM sectoral_balance_examples
ORDER BY sector;

CREATE VIEW v_economic_metric_summary AS
SELECT
  scenario,
  metric_name,
  ROUND(MIN(metric_value), 3) AS minimum_value,
  ROUND(AVG(metric_value), 3) AS average_value,
  ROUND(MAX(metric_value), 3) AS maximum_value
FROM economic_metrics
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

SELECT * FROM v_economic_system_components;
SELECT * FROM v_economic_feedback_loops;
SELECT * FROM v_modeling_approaches;
SELECT * FROM v_scenario_definitions;
SELECT * FROM v_sectoral_balance_examples;
SELECT * FROM v_economic_metric_summary;
SELECT * FROM v_validation_targets;
