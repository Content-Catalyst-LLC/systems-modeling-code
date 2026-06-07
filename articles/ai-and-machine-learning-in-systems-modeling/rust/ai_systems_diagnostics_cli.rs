use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    n: usize,
    noise_scale: f64,
    structural_weight: f64,
    residual_strength: f64,
    interaction_strength: f64,
    drift_strength: f64,
}

fn deterministic_noise(index: usize, scale: f64) -> f64 {
    (index as f64 * 1.61803398875).sin() * scale
}

fn baseline(a: f64, b: f64, c: f64, structural_weight: f64) -> f64 {
    structural_weight * (1.8 * a.sin() + 0.6 * b - 0.4 * c)
}

fn simulate_summary(s: &Scenario) -> (f64, f64, f64, f64, f64) {
    let mut baseline_squared = 0.0_f64;
    let mut hybrid_squared = 0.0_f64;
    let mut baseline_abs = 0.0_f64;
    let mut hybrid_abs = 0.0_f64;
    let mut count = 0.0_f64;

    for i in 0..s.n {
        let share = i as f64 / ((s.n - 1) as f64).max(1.0);
        let a = (i as f64 * 0.137) % 10.0;
        let b = (i as f64 * 0.071).sin() * 3.0;
        let c = 1.0 + ((i as f64 * 0.173) % 7.0);

        let structural_baseline = baseline(a, b, c, s.structural_weight);
        let true_residual = s.residual_strength * b.powi(2)
            + s.interaction_strength * a * b
            + s.drift_strength * share * b
            + deterministic_noise(i, s.noise_scale);

        let true_response = structural_baseline + true_residual;
        let learned_residual = s.residual_strength * b.powi(2)
            + s.interaction_strength * a * b
            + s.drift_strength * share * b;

        let hybrid_prediction = structural_baseline + learned_residual;

        let baseline_error = true_response - structural_baseline;
        let hybrid_error = true_response - hybrid_prediction;

        baseline_squared += baseline_error * baseline_error;
        hybrid_squared += hybrid_error * hybrid_error;
        baseline_abs += baseline_error.abs();
        hybrid_abs += hybrid_error.abs();
        count += 1.0;
    }

    let baseline_rmse = (baseline_squared / count).sqrt();
    let hybrid_rmse = (hybrid_squared / count).sqrt();
    let baseline_mae = baseline_abs / count;
    let hybrid_mae = hybrid_abs / count;
    let improvement = (baseline_rmse - hybrid_rmse) / baseline_rmse.max(1e-12);

    (baseline_rmse, hybrid_rmse, baseline_mae, hybrid_mae, improvement)
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_hybrid", n: 1000, noise_scale: 0.50, structural_weight: 1.00, residual_strength: 0.70, interaction_strength: 0.25, drift_strength: 0.00 },
        Scenario { name: "high_noise_system", n: 1000, noise_scale: 0.95, structural_weight: 1.00, residual_strength: 0.70, interaction_strength: 0.25, drift_strength: 0.00 },
        Scenario { name: "strong_residual_system", n: 1000, noise_scale: 0.50, structural_weight: 1.00, residual_strength: 1.10, interaction_strength: 0.38, drift_strength: 0.00 },
        Scenario { name: "drifting_system", n: 1000, noise_scale: 0.55, structural_weight: 1.00, residual_strength: 0.70, interaction_strength: 0.25, drift_strength: 0.45 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_ai_hybrid_metrics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,baseline_rmse,hybrid_rmse,baseline_mae,hybrid_mae,hybrid_improvement_ratio,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let (baseline_rmse, hybrid_rmse, baseline_mae, hybrid_mae, improvement) = simulate_summary(scenario);
        let label = if hybrid_rmse < baseline_rmse {
            "hybrid improved baseline"
        } else {
            "hybrid did not improve baseline"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            scenario.name,
            baseline_rmse,
            hybrid_rmse,
            baseline_mae,
            hybrid_mae,
            improvement,
            label
        )?;
    }

    println!("Rust AI systems diagnostics complete.");
    println!("outputs/tables/rust_ai_hybrid_metrics.csv");

    Ok(())
}
