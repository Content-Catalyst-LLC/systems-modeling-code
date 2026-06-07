use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Stakeholder {
    name: &'static str,
    access: f64,
    cost: f64,
    resilience: f64,
    equity: f64,
    feasibility: f64,
}

struct Scenario {
    name: &'static str,
    access: f64,
    cost: f64,
    resilience: f64,
    equity: f64,
    feasibility: f64,
}

fn score(stakeholder: &Stakeholder, scenario: &Scenario) -> f64 {
    stakeholder.access * scenario.access
        + stakeholder.cost * scenario.cost
        + stakeholder.resilience * scenario.resilience
        + stakeholder.equity * scenario.equity
        + stakeholder.feasibility * scenario.feasibility
}

fn mean(values: &[f64]) -> f64 {
    values.iter().sum::<f64>() / (values.len() as f64).max(1.0)
}

fn stddev(values: &[f64]) -> f64 {
    let mu = mean(values);
    let variance = values.iter().map(|value| (value - mu).powi(2)).sum::<f64>() / (values.len() as f64).max(1.0);
    variance.sqrt()
}

fn min_max(values: &[f64]) -> (f64, f64) {
    let mut minimum = values[0];
    let mut maximum = values[0];

    for value in values {
        if *value < minimum {
            minimum = *value;
        }
        if *value > maximum {
            maximum = *value;
        }
    }

    (minimum, maximum)
}

fn main() -> std::io::Result<()> {
    let stakeholders = vec![
        Stakeholder { name: "community_residents", access: 0.30, cost: 0.10, resilience: 0.20, equity: 0.30, feasibility: 0.10 },
        Stakeholder { name: "frontline_staff", access: 0.20, cost: 0.15, resilience: 0.25, equity: 0.20, feasibility: 0.20 },
        Stakeholder { name: "technical_experts", access: 0.15, cost: 0.20, resilience: 0.30, equity: 0.15, feasibility: 0.20 },
        Stakeholder { name: "public_agency", access: 0.20, cost: 0.25, resilience: 0.25, equity: 0.15, feasibility: 0.15 },
        Stakeholder { name: "service_users", access: 0.35, cost: 0.10, resilience: 0.15, equity: 0.30, feasibility: 0.10 },
        Stakeholder { name: "resource_managers", access: 0.15, cost: 0.20, resilience: 0.30, equity: 0.15, feasibility: 0.20 },
    ];

    let scenarios = vec![
        Scenario { name: "targeted_service_expansion", access: 0.85, cost: 0.55, resilience: 0.65, equity: 0.90, feasibility: 0.60 },
        Scenario { name: "infrastructure_repair_priority", access: 0.55, cost: 0.65, resilience: 0.85, equity: 0.50, feasibility: 0.75 },
        Scenario { name: "digital_monitoring_platform", access: 0.60, cost: 0.50, resilience: 0.70, equity: 0.45, feasibility: 0.70 },
        Scenario { name: "community_led_resilience", access: 0.75, cost: 0.70, resilience: 0.80, equity: 0.85, feasibility: 0.55 },
        Scenario { name: "baseline_policy_continuation", access: 0.40, cost: 0.90, resilience: 0.35, equity: 0.30, feasibility: 0.85 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_participatory_scenario_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,mean_score,disagreement_sd,minimum_score,maximum_score,score_range,legitimacy_adjusted_score,consensus_label"
    )?;

    for scenario in &scenarios {
        let scores: Vec<f64> = stakeholders.iter().map(|stakeholder| {
            let _ = stakeholder.name;
            score(stakeholder, scenario)
        }).collect();

        let mu = mean(&scores);
        let sd = stddev(&scores);
        let (minimum, maximum) = min_max(&scores);
        let legitimacy_adjusted = mu - 0.50 * sd;

        let label = if sd >= 0.08 {
            "high disagreement"
        } else if sd >= 0.04 {
            "moderate disagreement"
        } else {
            "low disagreement"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            scenario.name,
            mu,
            sd,
            minimum,
            maximum,
            maximum - minimum,
            legitimacy_adjusted,
            label
        )?;
    }

    println!("Rust participatory diagnostics complete.");
    println!("outputs/tables/rust_participatory_scenario_summary.csv");

    Ok(())
}
