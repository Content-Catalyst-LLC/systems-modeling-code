-- agent_based_adoption_diffusion_schema.sql
-- SQLite schema and review queries for agent-based adoption and diffusion.

DROP VIEW IF EXISTS v_diffusion_scenarios;
DROP VIEW IF EXISTS v_agent_group_assumptions;
DROP VIEW IF EXISTS v_scenario_pressure_index;
DROP VIEW IF EXISTS v_group_barrier_index;
DROP VIEW IF EXISTS v_model_assumptions;
DROP VIEW IF EXISTS v_diagnostic_definitions;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS diagnostic_definitions;
DROP TABLE IF EXISTS model_assumptions;
DROP TABLE IF EXISTS agent_group_assumptions;
DROP TABLE IF EXISTS diffusion_scenarios;

CREATE TABLE diffusion_scenarios (
  scenario TEXT PRIMARY KEY,
  social_weight REAL NOT NULL,
  benefit_weight REAL NOT NULL,
  intervention_weight REAL NOT NULL,
  cost_weight REAL NOT NULL,
  resistance_weight REAL NOT NULL,
  seed_strategy TEXT NOT NULL,
  seed_count INTEGER NOT NULL,
  cost_modifier REAL NOT NULL,
  trust_modifier REAL NOT NULL,
  connection_probability REAL NOT NULL,
  bridge_probability REAL NOT NULL,
  steps INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE agent_group_assumptions (
  group_name TEXT PRIMARY KEY,
  threshold_low REAL NOT NULL,
  threshold_high REAL NOT NULL,
  benefit_low REAL NOT NULL,
  benefit_high REAL NOT NULL,
  cost_low REAL NOT NULL,
  cost_high REAL NOT NULL,
  trust_low REAL NOT NULL,
  trust_high REAL NOT NULL,
  resistance_low REAL NOT NULL,
  resistance_high REAL NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE model_assumptions (
  assumption_id TEXT PRIMARY KEY,
  assumption TEXT NOT NULL,
  category TEXT NOT NULL,
  risk_if_wrong TEXT NOT NULL,
  review_action TEXT NOT NULL
);

CREATE TABLE diagnostic_definitions (
  diagnostic TEXT PRIMARY KEY,
  definition TEXT NOT NULL,
  why_it_matters TEXT NOT NULL
);

CREATE TABLE validation_targets (
  metric TEXT PRIMARY KEY,
  target_low REAL NOT NULL,
  target_high REAL NOT NULL,
  notes TEXT NOT NULL
);

INSERT INTO diffusion_scenarios VALUES
('baseline_diffusion',0.45,0.42,0.10,0.28,0.20,'random',6,1.00,1.00,0.055,0.018,40,'Moderate benefit cost social influence trust and random seeding'),
('high_social_influence',0.75,0.42,0.10,0.28,0.20,'random',6,1.00,1.00,0.055,0.018,40,'Peer influence is stronger and can create faster threshold crossing'),
('high_cost_barrier',0.45,0.42,0.10,0.28,0.20,'random',6,1.35,1.00,0.055,0.018,40,'Costs are higher especially for cost-sensitive agents'),
('targeted_seeding',0.45,0.42,0.10,0.28,0.20,'high_degree',6,1.00,1.00,0.055,0.018,40,'Initial adopters are selected from high-degree network positions'),
('network_fragmentation',0.45,0.42,0.10,0.28,0.20,'random',6,1.00,1.00,0.060,0.003,40,'Between-group bridge ties are scarce and diffusion may stall by cluster'),
('trust_and_resistance',0.45,0.42,0.10,0.28,0.20,'random',6,1.10,0.65,0.055,0.018,40,'Trust is lower and cost pressure is slightly higher'),
('bridge_and_equity_seeding',0.45,0.42,0.12,0.26,0.20,'bridge_and_equity',8,0.95,1.05,0.055,0.018,40,'Seeds include high-barrier and highly connected agents to improve distributional reach');

INSERT INTO agent_group_assumptions VALUES
('early_access',0.25,0.50,0.55,0.85,0.25,0.55,0.55,0.90,0.15,0.45,'Agents with lower adoption thresholds and higher perceived benefit'),
('mainstream',0.40,0.70,0.45,0.75,0.30,0.65,0.45,0.80,0.25,0.55,'Agents with moderate thresholds and moderate adoption conditions'),
('high_barrier',0.60,0.90,0.30,0.65,0.55,0.90,0.25,0.60,0.45,0.80,'Agents facing higher costs lower trust and greater resistance');

INSERT INTO model_assumptions VALUES
('A1','Agents are grouped into early access mainstream and high barrier segments','agent_design','Real segmentation may differ from the synthetic groups','Use survey administrative or qualitative evidence for segmentation'),
('A2','Adoption is binary','functionality','Trial partial use abandonment and churn are ignored','Add multi-stage adoption states'),
('A3','Adoption is irreversible','dynamics','Real adopters may abandon switch or reduce use','Add abandonment and competing alternatives'),
('A4','Peer influence travels through synthetic network ties','network','Real influence may come through media institutions geography or supply chains','Use empirical or stakeholder-reviewed network structure'),
('A5','Agents adopt when adoption pressure clears a threshold','decision_rule','Real decisions may be probabilistic deliberative or institutionally constrained','Compare deterministic probabilistic and utility-based rules'),
('A6','Seed strategy can be random high-degree or bridge-and-equity focused','intervention','Actual seeding may depend on legitimacy access and implementation constraints','Test multiple seeding strategies and stakeholder acceptability'),
('A7','Trust and resistance are simplified','behavior','Trust is contextual historical and relational','Use participatory review and group-specific assumptions');

INSERT INTO diagnostic_definitions VALUES
('adoption_share','Share of agents that have adopted at a time step','Shows aggregate diffusion curve'),
('adopter_count','Number of adopted agents at a time step','Tracks total adoption'),
('adoption_gap','Difference between highest and lowest group adoption shares','Shows distributional inequality'),
('final_adoption_share','Adoption share at the end of the simulation','Measures final diffusion reach'),
('maximum_adoption_gap','Largest group adoption gap during the simulation','Shows worst distributional separation'),
('time_to_25_percent','First step when adoption share reaches 25 percent','Shows early diffusion speed'),
('time_to_50_percent','First step when adoption share reaches 50 percent','Shows mainstream diffusion timing'),
('peak_growth','Maximum step-to-step adoption-share increase','Shows takeoff or tipping intensity'),
('seed_efficiency','Final adoption share divided by seed count','Compares intervention leverage');

INSERT INTO validation_targets VALUES
('agent_count',1,1000000,'Workflow should include at least one agent'),
('scenario_count',1,1000000,'Workflow should include at least one scenario'),
('adoption_share',0,1,'Adoption share should remain normalized between zero and one'),
('adopter_count',0,1000000,'Adopter count should remain nonnegative'),
('adoption_gap',0,1,'Adoption gap should remain normalized between zero and one'),
('threshold',0,1,'Agent thresholds should remain normalized between zero and one');

CREATE VIEW v_diffusion_scenarios AS
SELECT * FROM diffusion_scenarios ORDER BY scenario;

CREATE VIEW v_agent_group_assumptions AS
SELECT * FROM agent_group_assumptions ORDER BY group_name;

CREATE VIEW v_scenario_pressure_index AS
SELECT
  scenario,
  ROUND(benefit_weight + social_weight + intervention_weight - cost_weight - resistance_weight, 6) AS simple_pressure_index,
  seed_strategy,
  seed_count,
  cost_modifier,
  trust_modifier,
  description
FROM diffusion_scenarios
ORDER BY simple_pressure_index DESC;

CREATE VIEW v_group_barrier_index AS
SELECT
  group_name,
  ROUND(((threshold_low + threshold_high) / 2.0) + ((cost_low + cost_high) / 2.0) + ((resistance_low + resistance_high) / 2.0) - ((trust_low + trust_high) / 2.0) - ((benefit_low + benefit_high) / 2.0), 6) AS simple_barrier_index,
  description
FROM agent_group_assumptions
ORDER BY simple_barrier_index DESC;

CREATE VIEW v_model_assumptions AS
SELECT * FROM model_assumptions ORDER BY assumption_id;

CREATE VIEW v_diagnostic_definitions AS
SELECT * FROM diagnostic_definitions ORDER BY diagnostic;

CREATE VIEW v_validation_targets AS
SELECT * FROM validation_targets ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_diffusion_scenarios;
SELECT * FROM v_agent_group_assumptions;
SELECT * FROM v_scenario_pressure_index;
SELECT * FROM v_group_barrier_index;
SELECT * FROM v_model_assumptions;
SELECT * FROM v_diagnostic_definitions;
SELECT * FROM v_validation_targets;
