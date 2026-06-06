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

fn simulate_model(growth_rate: f64, carrying_capacity: f64, n_steps: usize, initial_state: f64) -> Vec<f64> {
    let mut values = vec![0.0_f64; n_steps];
    values[0] = initial_state;

    for i in 1..n_steps {
        let previous = values[i - 1];
        let next_value = previous + growth_rate * previous * (1.0 - previous / carrying_capacity);
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
    let n_steps = 80usize;
    let train_cutoff = 52usize;
    let true_growth = 0.095_f64;
    let true_capacity = 120.0_f64;
    let mut seed = 42_u64;

    let true_state = simulate_model(true_growth, true_capacity, n_steps, 10.0);
    let mut observed = vec![0.0_f64; n_steps];

    for i in 0..n_steps {
        observed[i] = (true_state[i] + normal_like(&mut seed) * 0.85).max(0.0);
    }

    let train_observed = &observed[0..train_cutoff];
    let valid_observed = &observed[train_cutoff..];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_calibration_validation_grid.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "candidate_id,growth_rate,carrying_capacity,calibration_rmse,validation_rmse,generalization_gap")?;

    let mut candidate_id = 0usize;

    for gi in 0..=64 {
        let growth_rate = 0.040 + gi as f64 * (0.200 - 0.040) / 64.0;

        for ci in 0..=44 {
            let carrying_capacity = 70.0 + ci as f64 * (180.0 - 70.0) / 44.0;
            candidate_id += 1;

            let train_pred = simulate_model(growth_rate, carrying_capacity, train_observed.len(), train_observed[0]);
            let valid_pred_all = simulate_model(
                growth_rate,
                carrying_capacity,
                valid_observed.len() + 1,
                train_observed[train_observed.len() - 1],
            );
            let valid_pred = &valid_pred_all[1..];

            let calibration_rmse = rmse(train_observed, &train_pred);
            let validation_rmse = rmse(valid_observed, valid_pred);

            writeln!(
                writer,
                "{},{:.6},{:.6},{:.6},{:.6},{:.6}",
                candidate_id,
                growth_rate,
                carrying_capacity,
                calibration_rmse,
                validation_rmse,
                validation_rmse - calibration_rmse
            )?;
        }
    }

    println!("Rust calibration validation diagnostics complete.");
    println!("outputs/tables/rust_calibration_validation_grid.csv");

    Ok(())
}
