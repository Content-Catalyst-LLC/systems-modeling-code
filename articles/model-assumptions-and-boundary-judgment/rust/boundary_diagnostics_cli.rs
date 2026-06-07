use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Assumption {
    id: &'static str,
    category: &'static str,
    uncertainty: f64,
    sensitivity: f64,
    consequence: f64,
}

struct Boundary {
    name: &'static str,
    capital_cost: f64,
    service_reliability: f64,
    equity_performance: f64,
    long_term_resilience: f64,
}

fn risk_score(a: &Assumption) -> f64 {
    a.uncertainty * a.sensitivity * a.consequence
}

fn risk_label(score: f64) -> &'static str {
    if score >= 0.45 {
        "high"
    } else if score >= 0.25 {
        "moderate"
    } else {
        "lower"
    }
}

fn boundary_score(b: &Boundary) -> f64 {
    0.20 * b.capital_cost
        + 0.30 * b.service_reliability
        + 0.25 * b.equity_performance
        + 0.25 * b.long_term_resilience
}

fn main() -> std::io::Result<()> {
    let assumptions = vec![
        Assumption { id: "A1", category: "boundary", uncertainty: 0.80, sensitivity: 0.75, consequence: 0.90 },
        Assumption { id: "A2", category: "data", uncertainty: 0.55, sensitivity: 0.60, consequence: 0.70 },
        Assumption { id: "A3", category: "parameter", uncertainty: 0.40, sensitivity: 0.85, consequence: 0.65 },
        Assumption { id: "A4", category: "behavioral", uncertainty: 0.70, sensitivity: 0.50, consequence: 0.60 },
        Assumption { id: "A5", category: "scenario", uncertainty: 0.65, sensitivity: 0.80, consequence: 0.85 },
        Assumption { id: "A6", category: "normative", uncertainty: 0.75, sensitivity: 0.90, consequence: 0.95 },
        Assumption { id: "A7", category: "scale", uncertainty: 0.50, sensitivity: 0.65, consequence: 0.75 },
        Assumption { id: "A8", category: "causal", uncertainty: 0.45, sensitivity: 0.80, consequence: 0.80 },
        Assumption { id: "A9", category: "measurement", uncertainty: 0.70, sensitivity: 0.70, consequence: 0.85 },
    ];

    let boundaries = vec![
        Boundary { name: "narrow_asset_boundary", capital_cost: 0.80, service_reliability: 0.60, equity_performance: 0.35, long_term_resilience: 0.50 },
        Boundary { name: "expanded_service_boundary", capital_cost: 0.72, service_reliability: 0.75, equity_performance: 0.55, long_term_resilience: 0.65 },
        Boundary { name: "community_resilience_boundary", capital_cost: 0.65, service_reliability: 0.78, equity_performance: 0.85, long_term_resilience: 0.78 },
        Boundary { name: "long_horizon_boundary", capital_cost: 0.60, service_reliability: 0.82, equity_performance: 0.70, long_term_resilience: 0.90 },
        Boundary { name: "multi_stakeholder_boundary", capital_cost: 0.62, service_reliability: 0.76, equity_performance: 0.88, long_term_resilience: 0.82 },
    ];

    create_dir_all("outputs/tables")?;

    let file = File::create("outputs/tables/rust_assumption_register.csv")?;
    let mut writer = BufWriter::new(file);
    writeln!(writer, "assumption_id,category,uncertainty,sensitivity,consequence,risk_score,risk_label")?;

    for assumption in &assumptions {
        let score = risk_score(assumption);
        writeln!(
            writer,
            "{},{},{:.6},{:.6},{:.6},{:.6},{}",
            assumption.id,
            assumption.category,
            assumption.uncertainty,
            assumption.sensitivity,
            assumption.consequence,
            score,
            risk_label(score)
        )?;
    }

    let file2 = File::create("outputs/tables/rust_boundary_scenario_comparison.csv")?;
    let mut writer2 = BufWriter::new(file2);
    writeln!(writer2, "boundary,capital_cost,service_reliability,equity_performance,long_term_resilience,composite_score")?;

    for boundary in &boundaries {
        writeln!(
            writer2,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6}",
            boundary.name,
            boundary.capital_cost,
            boundary.service_reliability,
            boundary.equity_performance,
            boundary.long_term_resilience,
            boundary_score(boundary)
        )?;
    }

    println!("Rust boundary diagnostics complete.");
    println!("outputs/tables/rust_boundary_scenario_comparison.csv");

    Ok(())
}
