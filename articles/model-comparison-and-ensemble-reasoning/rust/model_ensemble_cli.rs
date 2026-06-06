use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn normal_like(seed: &mut u64) -> f64 {
    let u1 = lcg(seed).max(1e-12);
    let u2 = lcg(seed).max(1e-12);
    (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
}

fn simulate_managed(growth: f64, capacity: f64, extraction: f64, steps: usize, initial: f64) -> Vec<f64> {
    let mut values = vec![0.0_f64; steps];
    values[0] = initial;

    for i in 1..steps {
        let previous = values[i - 1];
        let next_value = previous + growth * previous * (1.0 - previous / capacity) - extraction * previous;
        values[i] = next_value.max(0.0);
    }

    values
}

fn simulate_logistic(growth: f64, capacity: f64, steps: usize, initial: f64) -> Vec<f64> {
    let mut values = vec![0.0_f64; steps];
    values[0] = initial;

    for i in 1..steps {
        let previous = values[i - 1];
        let next_value = previous + growth * previous * (1.0 - previous / capacity);
        values[i] = next_value.max(0.0);
    }

    values
}

fn rmse(actual: &[f64], predicted: &[f64]) -> f64 {
    let mut total = 0.0_f64;
    for i in 0..actual.len() {
        let diff = actual[i] - predicted[i];
        total += diff * diff;
    }
    (total / actual.len() as f64).sqrt()
}

fn main() -> std::io::Result<()> {
    let steps = 90usize;
    let train_cutoff = 60usize;
    let mut seed = 42_u64;

    let true_state = simulate_managed(0.085, 130.0, 0.012, steps, 12.0);
    let mut observed = vec![0.0_f64; steps];

    for i in 0..steps {
        observed[i] = (true_state[i] + normal_like(&mut seed) * 1.1).max(0.0);
    }

    let models: Vec<(&str, Vec<f64>)> = vec![
        ("logistic_low", simulate_logistic(0.070, 115.0, steps, observed[0])),
        ("logistic_high", simulate_logistic(0.095, 145.0, steps, observed[0])),
        ("managed_reference", simulate_managed(0.085, 130.0, 0.012, steps, observed[0])),
        ("managed_high_press", simulate_managed(0.090, 140.0, 0.020, steps, observed[0])),
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_model_ensemble_metrics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "model,calibration_rmse,validation_rmse,generalization_gap")?;

    for (model_name, prediction) in models {
        let calibration_rmse = rmse(&observed[0..train_cutoff], &prediction[0..train_cutoff]);
        let validation_rmse = rmse(&observed[train_cutoff..], &prediction[train_cutoff..]);

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6}",
            model_name,
            calibration_rmse,
            validation_rmse,
            validation_rmse - calibration_rmse
        )?;
    }

    println!("Rust model ensemble diagnostics complete.");
    println!("outputs/tables/rust_model_ensemble_metrics.csv");

    Ok(())
}
