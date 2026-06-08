-- infrastructure_shock_propagation_schema.sql
-- SQLite schema and review queries for infrastructure shock propagation.

DROP VIEW IF EXISTS v_nodes;
DROP VIEW IF EXISTS v_edges;
DROP VIEW IF EXISTS v_scenarios;
DROP VIEW IF EXISTS v_node_risk_ranking;
DROP VIEW IF EXISTS v_dependency_edges;
DROP VIEW IF EXISTS v_model_assumptions;
DROP VIEW IF EXISTS v_diagnostic_definitions;
DROP VIEW IF EXISTS v_validation_targets;

DROP TABLE IF EXISTS validation_targets;
DROP TABLE IF EXISTS diagnostic_definitions;
DROP TABLE IF EXISTS model_assumptions;
DROP TABLE IF EXISTS shock_scenarios;
DROP TABLE IF EXISTS infrastructure_edges;
DROP TABLE IF EXISTS infrastructure_nodes;

CREATE TABLE infrastructure_nodes (
  node TEXT PRIMARY KEY,
  sector TEXT NOT NULL,
  load REAL NOT NULL,
  capacity REAL NOT NULL,
  criticality REAL NOT NULL,
  repair_time INTEGER NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE infrastructure_edges (
  source TEXT NOT NULL,
  target TEXT NOT NULL,
  edge_type TEXT NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE shock_scenarios (
  scenario TEXT PRIMARY KEY,
  initial_failures TEXT NOT NULL,
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

INSERT INTO infrastructure_nodes VALUES
('power_hub','power',85,120,0.95,4,'Primary power node supporting multiple dependent services'),
('water_pump','water',50,70,0.80,3,'Water pumping asset dependent on power service'),
('hospital','health',70,95,1.00,5,'Critical health facility dependent on power and access'),
('telecom_exchange','telecom',65,85,0.90,4,'Telecommunications exchange supporting emergency operations and logistics'),
('bridge','transport',75,110,0.75,6,'Major access connector for hospital and logistics hub'),
('logistics_hub','logistics',60,80,0.70,3,'Distribution and supply node dependent on transport fuel and telecom'),
('fuel_depot','fuel',45,65,0.65,3,'Fuel supply node supporting logistics movement'),
('neighborhood_a','community',40,60,0.55,2,'Community service area dependent on water and logistics'),
('neighborhood_b','community',35,55,0.50,2,'Community service area dependent on hospital and emergency operations'),
('emergency_ops','emergency',55,75,0.95,4,'Emergency coordination node dependent on telecommunications');

INSERT INTO infrastructure_edges VALUES
('power_hub','water_pump','dependency','Water pumping requires power'),
('power_hub','hospital','dependency','Hospital requires power'),
('power_hub','telecom_exchange','dependency','Telecom exchange requires power'),
('telecom_exchange','emergency_ops','dependency','Emergency operations require telecom service'),
('bridge','hospital','access','Bridge provides access to hospital'),
('bridge','logistics_hub','access','Bridge provides access to logistics hub'),
('logistics_hub','neighborhood_a','service','Logistics hub supports neighborhood A'),
('fuel_depot','logistics_hub','dependency','Logistics hub depends on fuel supply'),
('emergency_ops','neighborhood_b','service','Emergency operations support neighborhood B'),
('water_pump','neighborhood_a','service','Water pump serves neighborhood A'),
('hospital','neighborhood_b','service','Hospital serves neighborhood B'),
('telecom_exchange','logistics_hub','dependency','Logistics hub depends on telecommunications');

INSERT INTO shock_scenarios VALUES
('localized_outage','neighborhood_a','Peripheral local outage used as a containment baseline'),
('hub_failure','power_hub','Primary power hub failure tests high-dependency cascade risk'),
('dependency_cascade','telecom_exchange','Telecom failure tests functional dependency propagation'),
('load_redistribution','bridge','Bridge failure tests access disruption and load redistribution'),
('compound_shock','power_hub|bridge|telecom_exchange','Compound shock disables power access and telecom simultaneously'),
('recovery_intervention','power_hub|bridge','Recovery intervention scenario starts with high-consequence failures');

INSERT INTO model_assumptions VALUES
('A1','Infrastructure is represented as a static graph','boundary','Adaptive rerouting and operational reconfiguration may be understated','Add dynamic topology or operational response rules'),
('A2','Node state is binary','functionality','Partial or degraded operation may be ignored','Add multistate functionality levels'),
('A3','Load redistributes evenly to functional outgoing neighbors','flow','Real load follows physics routing contracts or operator decisions','Use sector-specific flow or routing models'),
('A4','Dependency failure occurs above a fixed tolerance','dependency','Real dependencies may be nonlinear hidden or time dependent','Audit dependencies and test tolerance sensitivity'),
('A5','Overload failure occurs above a fixed threshold','capacity','Real overload may be probabilistic and time dependent','Add probabilistic or duration-dependent failure'),
('A6','Criticality weights are synthetic','consequence','Social consequence may be misrepresented','Use stakeholder and service consequence review'),
('A7','Recovery is simplified','recovery','Repair time may depend on crews materials weather and access','Add repair logistics and resource constraints');

INSERT INTO diagnostic_definitions VALUES
('failed_count','Number of failed nodes at a propagation step','Measures technical cascade scale'),
('weighted_service_loss','Sum of criticality weights for failed nodes','Measures consequence-weighted disruption'),
('functional_count','Number of nodes still functioning','Tracks remaining technical functionality'),
('cascade_depth','Propagation step at which maximum failure count is reached','Shows how far failure recursively spreads'),
('dependency_failures','Nodes failed by dependency loss','Identifies interdependency vulnerability'),
('overload_failures','Nodes failed by load exceeding capacity','Identifies insufficient spare capacity'),
('max_failed_count','Maximum failed nodes reached during scenario','Compares worst cascade scale across scenarios'),
('max_weighted_service_loss','Maximum consequence-weighted loss reached during scenario','Compares worst service consequence across scenarios');

INSERT INTO validation_targets VALUES
('failed_count',0,1000000,'Failed node count should remain nonnegative'),
('weighted_service_loss',0,1000000,'Weighted service loss should remain nonnegative'),
('functional_count',0,1000000,'Functional node count should remain nonnegative'),
('node_count',1,1000000,'Workflow should include at least one node'),
('edge_count',1,1000000,'Workflow should include at least one edge'),
('scenario_count',1,1000000,'Workflow should include at least one scenario');

CREATE VIEW v_nodes AS
SELECT
  node,
  sector,
  load,
  capacity,
  ROUND(load / capacity, 6) AS load_capacity_ratio,
  criticality,
  repair_time,
  description
FROM infrastructure_nodes
ORDER BY sector, node;

CREATE VIEW v_edges AS
SELECT source, target, edge_type, description
FROM infrastructure_edges
ORDER BY edge_type, source, target;

CREATE VIEW v_scenarios AS
SELECT scenario, initial_failures, description
FROM shock_scenarios
ORDER BY scenario;

CREATE VIEW v_node_risk_ranking AS
SELECT
  node,
  sector,
  ROUND(load / capacity, 6) AS load_capacity_ratio,
  criticality,
  repair_time,
  ROUND((load / capacity) * criticality, 6) AS simple_risk_index
FROM infrastructure_nodes
ORDER BY simple_risk_index DESC;

CREATE VIEW v_dependency_edges AS
SELECT source, target, description
FROM infrastructure_edges
WHERE edge_type = 'dependency'
ORDER BY source, target;

CREATE VIEW v_model_assumptions AS
SELECT * FROM model_assumptions
ORDER BY assumption_id;

CREATE VIEW v_diagnostic_definitions AS
SELECT * FROM diagnostic_definitions
ORDER BY diagnostic;

CREATE VIEW v_validation_targets AS
SELECT * FROM validation_targets
ORDER BY metric;

.headers on
.mode column

SELECT * FROM v_nodes;
SELECT * FROM v_edges;
SELECT * FROM v_scenarios;
SELECT * FROM v_node_risk_ranking;
SELECT * FROM v_dependency_edges;
SELECT * FROM v_model_assumptions;
SELECT * FROM v_diagnostic_definitions;
SELECT * FROM v_validation_targets;
