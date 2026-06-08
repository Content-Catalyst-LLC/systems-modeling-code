use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Summary {
    scenario: &'static str,
    average_service: f64,
    minimum_service: f64,
    time_below_threshold: i32,
    threshold_crossings: i32,
    final_capacity: f64,
    final_degradation: f64,
    transformed: i32,
    resilience_score: f64,
}

fn main() -> std::io::Result<()> {
    let summaries = vec![
        Summary { scenario: "targeted_resilience_investment", average_service: 0.720000, minimum_service: 0.590000, time_below_threshold: 0, threshold_crossings: 0, final_capacity: 0.870000, final_degradation: 0.060000, transformed: 0, resilience_score: 0.699000 },
        Summary { scenario: "moderate_climate_stress", average_service: 0.690000, minimum_service: 0.560000, time_below_threshold: 0, threshold_crossings: 0, final_capacity: 0.720000, final_degradation: 0.080000, transformed: 0, resilience_score: 0.662000 },
        Summary { scenario: "transformation_pathway", average_service: 0.610000, minimum_service: 0.520000, time_below_threshold: 5, threshold_crossings: 2, final_capacity: 0.760000, final_degradation: 0.170000, transformed: 1, resilience_score: 0.476000 },
        Summary { scenario: "repeated_shocks", average_service: 0.590000, minimum_service: 0.480000, time_below_threshold: 9, threshold_crossings: 3, final_capacity: 0.610000, final_degradation: 0.160000, transformed: 0, resilience_score: 0.399000 },
        Summary { scenario: "delayed_adaptation", average_service: 0.550000, minimum_service: 0.430000, time_below_threshold: 14, threshold_crossings: 4, final_capacity: 0.600000, final_degradation: 0.210000, transformed: 0, resilience_score: 0.266500 },
        Summary { scenario: "compound_climate_stress", average_service: 0.490000, minimum_service: 0.360000, time_below_threshold: 24, threshold_crossings: 5, final_capacity: 0.500000, final_degradation: 0.300000, transformed: 0, resilience_score: 0.025000 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_climate_resilience_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,average_service,minimum_service,time_below_threshold,threshold_crossings,final_adaptive_capacity,final_degradation,transformed,resilience_score")?;

    for item in &summaries {
        writeln!(
            writer,
            "{},{:.6},{:.6},{},{},{:.6},{:.6},{},{:.6}",
            item.scenario,
            item.average_service,
            item.minimum_service,
            item.time_below_threshold,
            item.threshold_crossings,
            item.final_capacity,
            item.final_degradation,
            item.transformed,
            item.resilience_score
        )?;
    }

    println!("Rust climate resilience CLI complete.");
    println!("outputs/tables/rust_climate_resilience_summary.csv");

    Ok(())
}
