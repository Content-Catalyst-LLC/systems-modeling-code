-- Systems Modeling schema
-- Stores systems model metadata, components, links, assumptions, runs, and outputs.

CREATE TABLE IF NOT EXISTS systems_models (
    model_id INTEGER PRIMARY KEY,
    model_name TEXT NOT NULL,
    model_family TEXT NOT NULL,
    purpose TEXT NOT NULL,
    interpretation_note TEXT
);

CREATE TABLE IF NOT EXISTS system_components (
    component_id INTEGER PRIMARY KEY,
    model_id INTEGER NOT NULL,
    component_name TEXT NOT NULL,
    component_type TEXT NOT NULL,
    unit TEXT,
    interpretation_note TEXT,
    FOREIGN KEY (model_id) REFERENCES systems_models(model_id)
);

CREATE TABLE IF NOT EXISTS system_links (
    link_id INTEGER PRIMARY KEY,
    model_id INTEGER NOT NULL,
    source_component TEXT NOT NULL,
    target_component TEXT NOT NULL,
    link_type TEXT NOT NULL,
    weight REAL,
    delay_periods REAL,
    interpretation_note TEXT,
    FOREIGN KEY (model_id) REFERENCES systems_models(model_id)
);

CREATE TABLE IF NOT EXISTS model_assumptions (
    assumption_id INTEGER PRIMARY KEY,
    model_id INTEGER NOT NULL,
    assumption_text TEXT NOT NULL,
    confidence REAL,
    impact_if_wrong REAL,
    testing_method TEXT,
    FOREIGN KEY (model_id) REFERENCES systems_models(model_id)
);

CREATE TABLE IF NOT EXISTS simulation_runs (
    run_id INTEGER PRIMARY KEY,
    model_id INTEGER NOT NULL,
    scenario_id TEXT NOT NULL,
    method TEXT NOT NULL,
    steps INTEGER,
    interpretation_note TEXT,
    FOREIGN KEY (model_id) REFERENCES systems_models(model_id)
);

CREATE TABLE IF NOT EXISTS simulation_outputs (
    output_id INTEGER PRIMARY KEY,
    run_id INTEGER NOT NULL,
    time_step INTEGER NOT NULL,
    component_name TEXT NOT NULL,
    component_value REAL NOT NULL,
    FOREIGN KEY (run_id) REFERENCES simulation_runs(run_id)
);

INSERT INTO systems_models
(model_id, model_name, model_family, purpose, interpretation_note)
VALUES
(1, 'Interacting Stocks Feedback Model', 'stock-and-flow model', 'Explore reinforcing and balancing feedback between two stocks.', 'Educational systems modeling example.'),
(2, 'Network Shock Propagation Model', 'network simulation model', 'Explore how shocks propagate through interconnected components.', 'Educational network systems modeling example.');
