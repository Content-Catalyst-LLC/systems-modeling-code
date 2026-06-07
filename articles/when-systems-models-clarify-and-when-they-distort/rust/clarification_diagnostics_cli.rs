use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct ModelCase {
    name: &'static str,
    structural_clarity: f64,
    dynamic_clarity: f64,
    scenario_clarity: f64,
    assumption_transparency: f64,
    false_precision_risk: f64,
    boundary_risk: f64,
    proxy_risk: f64,
    misuse_risk: f64,
}

fn clarification_score(m: &ModelCase) -> f64 {
    0.30 * m.structural_clarity
        + 0.25 * m.dynamic_clarity
        + 0.25 * m.scenario_clarity
        + 0.20 * m.assumption_transparency
}

fn distortion_risk_score(m: &ModelCase) -> f64 {
    0.25 * m.false_precision_risk
        + 0.30 * m.boundary_risk
        + 0.20 * m.proxy_risk
        + 0.25 * m.misuse_risk
}

fn use_label(net: f64) -> &'static str {
    if net >= 0.20 {
        "strong_clarification_with_managed_risk"
    } else if net >= 0.0 {
        "useful_with_strong_caveats"
    } else {
        "high_distortion_risk_without_revision"
    }
}

fn main() -> std::io::Result<()> {
    let cases = vec![
        ModelCase { name: "infrastructure_resilience_model", structural_clarity: 0.85, dynamic_clarity: 0.70, scenario_clarity: 0.80, assumption_transparency: 0.65, false_precision_risk: 0.45, boundary_risk: 0.65, proxy_risk: 0.45, misuse_risk: 0.50 },
        ModelCase { name: "public_health_capacity_model", structural_clarity: 0.75, dynamic_clarity: 0.85, scenario_clarity: 0.70, assumption_transparency: 0.60, false_precision_risk: 0.55, boundary_risk: 0.70, proxy_risk: 0.55, misuse_risk: 0.65 },
        ModelCase { name: "urban_accessibility_model", structural_clarity: 0.70, dynamic_clarity: 0.50, scenario_clarity: 0.60, assumption_transparency: 0.70, false_precision_risk: 0.60, boundary_risk: 0.75, proxy_risk: 0.70, misuse_risk: 0.55 },
        ModelCase { name: "energy_transition_pathway_model", structural_clarity: 0.80, dynamic_clarity: 0.80, scenario_clarity: 0.85, assumption_transparency: 0.55, false_precision_risk: 0.50, boundary_risk: 0.65, proxy_risk: 0.50, misuse_risk: 0.60 },
        ModelCase { name: "machine_learning_risk_model", structural_clarity: 0.45, dynamic_clarity: 0.40, scenario_clarity: 0.35, assumption_transparency: 0.35, false_precision_risk: 0.85, boundary_risk: 0.70, proxy_risk: 0.85, misuse_risk: 0.90 },
        ModelCase { name: "digital_twin_operations_model", structural_clarity: 0.75, dynamic_clarity: 0.65, scenario_clarity: 0.70, assumption_transparency: 0.50, false_precision_risk: 0.70, boundary_risk: 0.60, proxy_risk: 0.50, misuse_risk: 0.75 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_clarification_distortion_model_cases.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "model_case,clarification_score,distortion_risk_score,net_interpretive_value,use_label")?;

    for item in &cases {
        let clarification = clarification_score(item);
        let distortion = distortion_risk_score(item);
        let net = clarification - distortion;

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{}",
            item.name,
            clarification,
            distortion,
            net,
            use_label(net)
        )?;
    }

    println!("Rust clarification diagnostics complete.");
    println!("outputs/tables/rust_clarification_distortion_model_cases.csv");

    Ok(())
}
