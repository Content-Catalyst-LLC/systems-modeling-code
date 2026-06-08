use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    periods: i32,
    stock: f64,
    regeneration_rate: f64,
    demand_growth: f64,
    extraction_efficiency: f64,
    conservation_sensitivity: f64,
    max_conservation: f64,
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline", periods: 80, stock: 80.0, regeneration_rate: 0.080, demand_growth: 0.015, extraction_efficiency: 0.120, conservation_sensitivity: 0.45, max_conservation: 0.35 },
        Scenario { name: "high_demand", periods: 80, stock: 80.0, regeneration_rate: 0.080, demand_growth: 0.035, extraction_efficiency: 0.120, conservation_sensitivity: 0.45, max_conservation: 0.35 },
        Scenario { name: "conservation", periods: 80, stock: 80.0, regeneration_rate: 0.080, demand_growth: 0.015, extraction_efficiency: 0.120, conservation_sensitivity: 0.85, max_conservation: 0.55 },
        Scenario { name: "technology_rebound", periods: 80, stock: 80.0, regeneration_rate: 0.080, demand_growth: 0.030, extraction_efficiency: 0.180, conservation_sensitivity: 0.35, max_conservation: 0.30 },
        Scenario { name: "regeneration_stress", periods: 80, stock: 80.0, regeneration_rate: 0.045, demand_growth: 0.015, extraction_efficiency: 0.120, conservation_sensitivity: 0.45, max_conservation: 0.35 },
        Scenario { name: "delayed_governance", periods: 80, stock: 80.0, regeneration_rate: 0.080, demand_growth: 0.025, extraction_efficiency: 0.120, conservation_sensitivity: 0.20, max_conservation: 0.20 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_resource_depletion_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,final_stock,minimum_stock,cumulative_extraction,cumulative_regeneration,overshoot_periods")?;

    for s in &scenarios {
        let mut stock = s.stock;
        let mut min_stock = stock;
        let mut cumulative_extraction = 0.0;
        let mut cumulative_regeneration = 0.0;
        let mut overshoot_periods = 0;

        for t in 0..s.periods {
            let demand = 4.0 * (1.0 + s.demand_growth).powi(t);
            let scarcity = (1.0 - stock / 70.0).max(0.0);
            let conservation = s.max_conservation.min(s.conservation_sensitivity * scarcity);
            let effective_demand = demand * (1.0 - conservation);
            let regeneration = (s.regeneration_rate * stock * (1.0 - stock / 100.0)).max(0.0);
            let extraction = effective_demand.min((s.extraction_efficiency * stock).min(stock + regeneration));

            if extraction > regeneration {
                overshoot_periods += 1;
            }

            cumulative_extraction += extraction;
            cumulative_regeneration += regeneration;
            stock = (stock + regeneration - extraction).max(0.0);
            min_stock = min_stock.min(stock);
        }

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{}",
            s.name, stock, min_stock, cumulative_extraction, cumulative_regeneration, overshoot_periods
        )?;
    }

    println!("Rust resource depletion CLI complete.");
    println!("outputs/tables/rust_resource_depletion_summary.csv");

    Ok(())
}
