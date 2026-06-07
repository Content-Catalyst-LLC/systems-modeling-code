use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    initial_stock: f64,
    carrying_capacity: f64,
    growth_rate: f64,
    extraction_rate: f64,
    restoration_rate: f64,
    disturbance_step: usize,
    disturbance_size: f64,
}

struct Summary {
    scenario: &'static str,
    final_stock: f64,
    minimum_stock: f64,
    maximum_stock: f64,
    final_resilience_index: f64,
    average_extraction: f64,
    average_restoration: f64,
}

fn simulate(s: &Scenario) -> Summary {
    let mut stock = s.initial_stock;
    let mut minimum_stock = stock;
    let mut maximum_stock = stock;
    let mut total_extraction = 0.0_f64;
    let mut total_restoration = 0.0_f64;

    for step in 1..=s.steps {
        let regeneration = s.growth_rate * stock * (1.0 - stock / s.carrying_capacity);
        let extraction = s.extraction_rate * stock;
        let restoration = s.restoration_rate * (s.carrying_capacity - stock);
        let disturbance = if step == s.disturbance_step { s.disturbance_size } else { 0.0 };

        stock = (stock + regeneration - extraction + restoration - disturbance)
            .max(0.0)
            .min(s.carrying_capacity);

        minimum_stock = minimum_stock.min(stock);
        maximum_stock = maximum_stock.max(stock);
        total_extraction += extraction;
        total_restoration += restoration;
    }

    Summary {
        scenario: s.name,
        final_stock: stock,
        minimum_stock,
        maximum_stock,
        final_resilience_index: stock / s.carrying_capacity,
        average_extraction: total_extraction / s.steps as f64,
        average_restoration: total_restoration / s.steps as f64,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_pressure", steps: 120, initial_stock: 70.0, carrying_capacity: 100.0, growth_rate: 0.065, extraction_rate: 0.040, restoration_rate: 0.010, disturbance_step: 65, disturbance_size: 12.0 },
        Scenario { name: "high_extraction", steps: 120, initial_stock: 70.0, carrying_capacity: 100.0, growth_rate: 0.065, extraction_rate: 0.065, restoration_rate: 0.010, disturbance_step: 65, disturbance_size: 12.0 },
        Scenario { name: "restoration_investment", steps: 120, initial_stock: 70.0, carrying_capacity: 100.0, growth_rate: 0.065, extraction_rate: 0.040, restoration_rate: 0.035, disturbance_step: 65, disturbance_size: 12.0 },
        Scenario { name: "larger_disturbance", steps: 120, initial_stock: 70.0, carrying_capacity: 100.0, growth_rate: 0.065, extraction_rate: 0.040, restoration_rate: 0.010, disturbance_step: 65, disturbance_size: 24.0 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_environmental_stock_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_stock,minimum_stock,maximum_stock,final_resilience_index,average_extraction,average_restoration,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.final_resilience_index >= 0.70 {
            "recovering pathway"
        } else {
            "degraded pathway"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.final_stock,
            result.minimum_stock,
            result.maximum_stock,
            result.final_resilience_index,
            result.average_extraction,
            result.average_restoration,
            label
        )?;
    }

    println!("Rust environmental diagnostics complete.");
    println!("outputs/tables/rust_environmental_stock_summary.csv");

    Ok(())
}
