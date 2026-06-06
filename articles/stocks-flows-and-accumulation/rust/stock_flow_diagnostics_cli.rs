use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    arrival_multiplier: f64,
    completion_shift: f64,
    extraction_before: f64,
    extraction_after: f64,
    resource_policy_time: usize,
    maintenance_before: f64,
    maintenance_after: f64,
    maintenance_policy_time: usize,
}

struct Summary {
    scenario: &'static str,
    stock: &'static str,
    initial_value: f64,
    final_value: f64,
    minimum_value: f64,
    maximum_value: f64,
    mean_net_flow: f64,
}

fn summarize(scenario: &'static str, stock: &'static str, values: &[f64], net_flows: &[f64]) -> Summary {
    let mut minimum = values[0];
    let mut maximum = values[0];
    let mut total_net = 0.0_f64;

    for i in 0..values.len() {
        minimum = minimum.min(values[i]);
        maximum = maximum.max(values[i]);
        total_net += net_flows[i];
    }

    Summary {
        scenario,
        stock,
        initial_value: values[0],
        final_value: values[values.len() - 1],
        minimum_value: minimum,
        maximum_value: maximum,
        mean_net_flow: total_net / net_flows.len() as f64,
    }
}

fn simulate(s: &Scenario, steps: usize) -> Vec<Summary> {
    let mut backlog = 80.0_f64;
    let mut resource = 600.0_f64;
    let mut condition = 72.0_f64;

    let mut backlog_values = Vec::new();
    let mut resource_values = Vec::new();
    let mut condition_values = Vec::new();
    let mut backlog_net_flows = Vec::new();
    let mut resource_net_flows = Vec::new();
    let mut condition_net_flows = Vec::new();

    for time in 1..=steps {
        let mut arrivals = 18.0 * s.arrival_multiplier;
        if (s.name == "capacity_and_conservation" || s.name == "adaptive_recovery") && time >= 50 {
            arrivals = 18.0 * 0.72 * s.arrival_multiplier;
        }
        if s.name == "delayed_response" && time >= 75 {
            arrivals = 18.0 * 0.72 * s.arrival_multiplier;
        }

        let extraction = if time >= s.resource_policy_time {
            s.extraction_after
        } else {
            s.extraction_before
        };

        let maintenance = if time >= s.maintenance_policy_time {
            s.maintenance_after
        } else {
            s.maintenance_before
        };

        let completions = (backlog + arrivals).min(12.0 + s.completion_shift + 0.08 * backlog);
        let backlog_net = arrivals - completions;
        backlog = (backlog + backlog_net).max(0.0);

        let regeneration = 0.045 * resource * (1.0 - resource / 1000.0);
        let resource_net = regeneration - extraction;
        resource = (resource + resource_net).max(0.0);

        let wear = 1.4 + 0.012 * (100.0 - condition).max(0.0);
        let condition_net = maintenance - wear;
        condition = (condition + condition_net).max(0.0).min(100.0);

        backlog_values.push(backlog);
        resource_values.push(resource);
        condition_values.push(condition);
        backlog_net_flows.push(backlog_net);
        resource_net_flows.push(resource_net);
        condition_net_flows.push(condition_net);
    }

    vec![
        summarize(s.name, "backlog", &backlog_values, &backlog_net_flows),
        summarize(s.name, "resource", &resource_values, &resource_net_flows),
        summarize(s.name, "infrastructure_condition", &condition_values, &condition_net_flows),
    ]
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline", arrival_multiplier: 1.00, completion_shift: 0.00, extraction_before: 24.0, extraction_after: 24.0, resource_policy_time: 999, maintenance_before: 0.9, maintenance_after: 0.9, maintenance_policy_time: 999 },
        Scenario { name: "capacity_and_conservation", arrival_multiplier: 0.85, completion_shift: 2.0, extraction_before: 22.0, extraction_after: 12.0, resource_policy_time: 70, maintenance_before: 1.2, maintenance_after: 2.8, maintenance_policy_time: 60 },
        Scenario { name: "delayed_response", arrival_multiplier: 1.00, completion_shift: 1.5, extraction_before: 24.0, extraction_after: 12.0, resource_policy_time: 85, maintenance_before: 0.9, maintenance_after: 2.8, maintenance_policy_time: 85 },
        Scenario { name: "adaptive_recovery", arrival_multiplier: 0.90, completion_shift: 3.0, extraction_before: 22.0, extraction_after: 10.0, resource_policy_time: 55, maintenance_before: 1.4, maintenance_after: 3.4, maintenance_policy_time: 50 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_stock_flow_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,stock,initial_value,final_value,minimum_value,maximum_value,mean_net_flow")?;

    for scenario in &scenarios {
        for summary in simulate(scenario, 120) {
            writeln!(
                writer,
                "{},{},{:.6},{:.6},{:.6},{:.6},{:.6}",
                summary.scenario,
                summary.stock,
                summary.initial_value,
                summary.final_value,
                summary.minimum_value,
                summary.maximum_value,
                summary.mean_net_flow
            )?;
        }
    }

    println!("Rust stock-flow diagnostics complete.");
    println!("outputs/tables/rust_stock_flow_summary.csv");

    Ok(())
}
