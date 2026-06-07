use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    initial_state: f64,
    state_persistence: f64,
    drift_amplitude: f64,
    process_noise: f64,
    observation_noise: f64,
    update_gain: f64,
    anomaly_threshold: f64,
    intervention_effect: f64,
    shock_magnitude: f64,
}

fn deterministic_noise(step: usize, scale: f64) -> f64 {
    (step as f64 * 1.61803398875).sin() * scale
}

fn shock_at(step: usize) -> bool {
    step == 35 || step == 80 || step == 105
}

fn simulate(s: &Scenario) -> (f64, f64, f64, f64, usize, usize, f64) {
    let mut true_state = vec![0.0_f64; s.steps];
    let mut observed_state = vec![0.0_f64; s.steps];
    let mut twin_state = vec![0.0_f64; s.steps];

    let mut anomaly_count = 0_usize;
    let mut intervention_count = 0_usize;

    true_state[0] = s.initial_state;
    observed_state[0] = true_state[0] + deterministic_noise(0, s.observation_noise);
    twin_state[0] = observed_state[0];

    for step in 1..s.steps {
        let drift = s.drift_amplitude * (step as f64 / 12.0).sin();
        let shock = if shock_at(step) { s.shock_magnitude } else { 0.0 };

        true_state[step] = s.state_persistence * true_state[step - 1]
            + drift
            + shock
            + deterministic_noise(step, s.process_noise);

        observed_state[step] = true_state[step] + deterministic_noise(step + 200, s.observation_noise);

        let mut prediction = s.state_persistence * twin_state[step - 1] + drift;
        let residual = observed_state[step] - prediction;

        if residual.abs() > s.anomaly_threshold {
            anomaly_count += 1;
        }

        if residual > s.anomaly_threshold {
            intervention_count += 1;
            prediction -= s.intervention_effect;
        }

        twin_state[step] = prediction + s.update_gain * residual;
    }

    let mut observed_abs = 0.0_f64;
    let mut twin_abs = 0.0_f64;
    let mut observed_squared = 0.0_f64;
    let mut twin_squared = 0.0_f64;

    for step in 0..s.steps {
        let observed_error = observed_state[step] - true_state[step];
        let twin_error = twin_state[step] - true_state[step];
        observed_abs += observed_error.abs();
        twin_abs += twin_error.abs();
        observed_squared += observed_error * observed_error;
        twin_squared += twin_error * twin_error;
    }

    let n = s.steps as f64;
    let observed_mae = observed_abs / n;
    let twin_mae = twin_abs / n;
    let observed_rmse = (observed_squared / n).sqrt();
    let twin_rmse = (twin_squared / n).sqrt();
    let improvement = (observed_rmse - twin_rmse) / observed_rmse.max(1e-12);

    (observed_mae, twin_mae, observed_rmse, twin_rmse, anomaly_count, intervention_count, improvement)
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_twin", steps: 120, initial_state: 50.0, state_persistence: 0.95, drift_amplitude: 0.15, process_noise: 0.60, observation_noise: 1.80, update_gain: 0.35, anomaly_threshold: 3.50, intervention_effect: 1.00, shock_magnitude: 4.0 },
        Scenario { name: "high_noise_twin", steps: 120, initial_state: 50.0, state_persistence: 0.95, drift_amplitude: 0.15, process_noise: 0.60, observation_noise: 3.20, update_gain: 0.30, anomaly_threshold: 4.80, intervention_effect: 1.00, shock_magnitude: 4.0 },
        Scenario { name: "slow_update_twin", steps: 120, initial_state: 50.0, state_persistence: 0.95, drift_amplitude: 0.15, process_noise: 0.60, observation_noise: 1.80, update_gain: 0.18, anomaly_threshold: 3.50, intervention_effect: 1.00, shock_magnitude: 4.0 },
        Scenario { name: "resilient_twin", steps: 120, initial_state: 50.0, state_persistence: 0.95, drift_amplitude: 0.15, process_noise: 0.45, observation_noise: 1.25, update_gain: 0.45, anomaly_threshold: 3.25, intervention_effect: 1.25, shock_magnitude: 3.5 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_digital_twin_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,MAE_observed,MAE_twin,RMSE_observed,RMSE_twin,anomaly_count,intervention_count,tracking_improvement_ratio,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let (observed_mae, twin_mae, observed_rmse, twin_rmse, anomaly_count, intervention_count, improvement) = simulate(scenario);
        let label = if twin_rmse < observed_rmse {
            "twin improved noisy observation"
        } else {
            "twin did not improve noisy observation"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{},{},{:.6},{}",
            scenario.name,
            observed_mae,
            twin_mae,
            observed_rmse,
            twin_rmse,
            anomaly_count,
            intervention_count,
            improvement,
            label
        )?;
    }

    println!("Rust digital twin diagnostics complete.");
    println!("outputs/tables/rust_digital_twin_summary.csv");

    Ok(())
}
