use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct ModelResult {
    id: &'static str,
    result_type: &'static str,
    lower_bound: f64,
    upper_bound: f64,
    assumption_disclosure: f64,
    uncertainty_disclosure: f64,
    boundary_disclosure: f64,
    misuse_warning: f64,
}

fn communication_quality(r: &ModelResult) -> f64 {
    0.30 * r.assumption_disclosure
        + 0.30 * r.uncertainty_disclosure
        + 0.20 * r.boundary_disclosure
        + 0.20 * r.misuse_warning
}

fn false_precision_label(r: &ModelResult) -> &'static str {
    let width = r.upper_bound - r.lower_bound;
    if r.uncertainty_disclosure < 0.60 && width > 0.20 {
        "high_false_precision_risk"
    } else if r.uncertainty_disclosure < 0.70 {
        "moderate_false_precision_risk"
    } else {
        "lower_false_precision_risk"
    }
}

fn main() -> std::io::Result<()> {
    let results = vec![
        ModelResult { id: "R1", result_type: "scenario", lower_bound: 0.55, upper_bound: 0.88, assumption_disclosure: 0.80, uncertainty_disclosure: 0.85, boundary_disclosure: 0.70, misuse_warning: 0.75 },
        ModelResult { id: "R2", result_type: "forecast", lower_bound: 9000.0, upper_bound: 16000.0, assumption_disclosure: 0.60, uncertainty_disclosure: 0.75, boundary_disclosure: 0.55, misuse_warning: 0.60 },
        ModelResult { id: "R3", result_type: "ranking", lower_bound: 0.75, upper_bound: 0.89, assumption_disclosure: 0.70, uncertainty_disclosure: 0.55, boundary_disclosure: 0.65, misuse_warning: 0.45 },
        ModelResult { id: "R4", result_type: "map", lower_bound: 0.40, upper_bound: 0.82, assumption_disclosure: 0.45, uncertainty_disclosure: 0.40, boundary_disclosure: 0.50, misuse_warning: 0.40 },
        ModelResult { id: "R5", result_type: "optimization", lower_bound: 0.80, upper_bound: 0.96, assumption_disclosure: 0.65, uncertainty_disclosure: 0.60, boundary_disclosure: 0.60, misuse_warning: 0.55 },
        ModelResult { id: "R6", result_type: "dashboard", lower_bound: 0.62, upper_bound: 0.86, assumption_disclosure: 0.55, uncertainty_disclosure: 0.50, boundary_disclosure: 0.55, misuse_warning: 0.35 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_model_result_communication_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "result_id,result_type,uncertainty_width,communication_quality_score,false_precision_risk")?;

    for r in &results {
        let width = r.upper_bound - r.lower_bound;
        writeln!(
            writer,
            "{},{},{:.6},{:.6},{}",
            r.id,
            r.result_type,
            width,
            communication_quality(r),
            false_precision_label(r)
        )?;
    }

    println!("Rust communication diagnostics complete.");
    println!("outputs/tables/rust_model_result_communication_diagnostics.csv");

    Ok(())
}
