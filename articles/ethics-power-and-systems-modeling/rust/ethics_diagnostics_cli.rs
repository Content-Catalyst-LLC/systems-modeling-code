use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Stakeholder {
    name: &'static str,
    affected: f64,
    represented: i32,
    influence: f64,
    expected_benefit: f64,
    expected_burden: f64,
}

fn burden_label(score: f64) -> &'static str {
    if score >= 0.45 {
        "high_power_burden_gap"
    } else if score >= 0.20 {
        "moderate_power_burden_gap"
    } else {
        "lower_power_burden_gap"
    }
}

fn main() -> std::io::Result<()> {
    let stakeholders = vec![
        Stakeholder { name: "public_agency", affected: 0.40, represented: 1, influence: 0.95, expected_benefit: 0.80, expected_burden: 0.20 },
        Stakeholder { name: "technical_modelers", affected: 0.20, represented: 1, influence: 0.85, expected_benefit: 0.65, expected_burden: 0.15 },
        Stakeholder { name: "frontline_workers", affected: 0.70, represented: 1, influence: 0.45, expected_benefit: 0.55, expected_burden: 0.35 },
        Stakeholder { name: "affected_residents", affected: 0.95, represented: 1, influence: 0.35, expected_benefit: 0.50, expected_burden: 0.60 },
        Stakeholder { name: "low_access_households", affected: 1.00, represented: 0, influence: 0.10, expected_benefit: 0.35, expected_burden: 0.80 },
        Stakeholder { name: "future_generations", affected: 0.90, represented: 0, influence: 0.00, expected_benefit: 0.40, expected_burden: 0.75 },
        Stakeholder { name: "local_environment", affected: 0.85, represented: 0, influence: 0.05, expected_benefit: 0.30, expected_burden: 0.70 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_ethics_stakeholder_distributional_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "group,affected,represented,influence,expected_benefit,expected_burden,net_benefit,burden_gap,power_burden_gap,risk_label"
    )?;

    for s in &stakeholders {
        let net_benefit = s.expected_benefit - s.expected_burden;
        let burden_gap = s.expected_burden - s.expected_benefit;
        let power_burden_gap = s.affected * s.expected_burden * (1.0 - s.influence);

        writeln!(
            writer,
            "{},{:.6},{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            s.name,
            s.affected,
            s.represented,
            s.influence,
            s.expected_benefit,
            s.expected_burden,
            net_benefit,
            burden_gap,
            power_burden_gap,
            burden_label(power_burden_gap)
        )?;
    }

    println!("Rust ethics diagnostics complete.");
    println!("outputs/tables/rust_ethics_stakeholder_distributional_diagnostics.csv");

    Ok(())
}
