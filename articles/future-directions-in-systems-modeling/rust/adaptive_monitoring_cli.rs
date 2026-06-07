use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

fn main() -> std::io::Result<()> {
    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_adaptive_monitoring.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "time,true_state,observed_state,estimated_state,residual,drift_indicator,intervention_flag")?;

    let mut true_state: f64 = 12.0;
    let mut estimate: f64 = 12.0;
    let mut drift: f64 = 0.0;

    for t in 0..24 {
        let shock = if t == 8 || t == 16 { 4.0 } else { 0.0 };

        true_state = 0.93 * true_state + 0.3 * ((t as f64) / 10.0).sin() + shock;
        let observed = true_state + 0.4 * ((t as f64) / 3.0).sin();

        let mut prediction = 0.93 * estimate + 0.3 * ((t as f64) / 10.0).sin();
        let residual = observed - prediction;
        let intervention = if residual.abs() > 3.0 { 1 } else { 0 };

        if intervention == 1 {
            prediction = prediction + 0.25 * residual;
        }

        estimate = 0.70 * prediction + 0.30 * observed;
        drift = 0.80 * drift + 0.20 * (observed - estimate).abs();

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            t, true_state, observed, estimate, residual, drift, intervention
        )?;
    }

    println!("Rust adaptive monitoring complete.");
    println!("outputs/tables/rust_adaptive_monitoring.csv");

    Ok(())
}
