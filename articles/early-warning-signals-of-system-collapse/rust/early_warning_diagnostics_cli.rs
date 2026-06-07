use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    stability_start: f64,
    stability_end: f64,
    noise_sd: f64,
    window: usize,
}

struct Summary {
    scenario: &'static str,
    final_stability: f64,
    final_state: f64,
    maximum_abs_state: f64,
    final_rolling_variance: f64,
}

fn linear_value(start: f64, stop: f64, index: usize, count: usize) -> f64 {
    let step = (stop - start) / (count as f64 - 1.0);
    start + index as f64 * step
}

fn deterministic_noise(index: usize, scale: f64) -> f64 {
    (index as f64 * 1.61803398875).sin() * scale
}

fn rolling_variance(values: &[f64]) -> f64 {
    if values.len() < 2 {
        return 0.0;
    }

    let mean = values.iter().sum::<f64>() / values.len() as f64;
    let ss = values.iter().map(|value| (value - mean).powi(2)).sum::<f64>();

    ss / (values.len() as f64 - 1.0)
}

fn simulate(s: &Scenario) -> Summary {
    let mut state = 0.0_f64;
    let mut maximum_abs_state = 0.0_f64;
    let mut history: Vec<f64> = Vec::new();
    let mut final_variance = 0.0_f64;

    for index in 0..s.steps {
        let stability = linear_value(s.stability_start, s.stability_end, index, s.steps);

        if index > 0 {
            state = stability * state + deterministic_noise(index, s.noise_sd);
        }

        history.push(state);
        maximum_abs_state = maximum_abs_state.max(state.abs());

        if history.len() >= s.window {
            let recent = &history[history.len() - s.window..];
            final_variance = rolling_variance(recent);
        }
    }

    Summary {
        scenario: s.name,
        final_stability: s.stability_end,
        final_state: state,
        maximum_abs_state,
        final_rolling_variance: final_variance,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_destabilization", steps: 320, stability_start: 0.55, stability_end: 0.985, noise_sd: 1.00, window: 25 },
        Scenario { name: "moderate_destabilization", steps: 320, stability_start: 0.45, stability_end: 0.900, noise_sd: 1.00, window: 25 },
        Scenario { name: "high_noise_destabilization", steps: 320, stability_start: 0.55, stability_end: 0.985, noise_sd: 1.40, window: 25 },
        Scenario { name: "low_noise_destabilization", steps: 320, stability_start: 0.55, stability_end: 0.985, noise_sd: 0.65, window: 25 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_early_warning_indicator_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_stability,final_state,maximum_abs_state,final_rolling_variance"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6}",
            result.scenario,
            result.final_stability,
            result.final_state,
            result.maximum_abs_state,
            result.final_rolling_variance
        )?;
    }

    println!("Rust early-warning diagnostics complete.");
    println!("outputs/tables/rust_early_warning_indicator_summary.csv");

    Ok(())
}
