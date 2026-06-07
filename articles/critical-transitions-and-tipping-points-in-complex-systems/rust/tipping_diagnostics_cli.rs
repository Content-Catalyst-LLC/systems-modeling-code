use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    forward_start: f64,
    forward_end: f64,
    steps: usize,
    initial_state: f64,
    dt: f64,
    jump_threshold: f64,
}

struct Summary {
    scenario: &'static str,
    path: &'static str,
    initial_state: f64,
    final_state: f64,
    minimum_state: f64,
    maximum_state: f64,
    maximum_jump_size: f64,
    transition_flags: usize,
}

fn update_state(x: f64, r: f64, dt: f64) -> f64 {
    x + dt * (r + x - x.powi(3))
}

fn linear_space(start: f64, stop: f64, count: usize) -> Vec<f64> {
    let step = (stop - start) / (count as f64 - 1.0);
    (0..count).map(|i| start + i as f64 * step).collect()
}

fn simulate_path(
    scenario: &Scenario,
    path_name: &'static str,
    values: &[f64],
    initial_state: f64,
) -> Summary {
    let mut x = initial_state;
    let mut minimum_state = x;
    let mut maximum_state = x;
    let mut maximum_jump_size = 0.0_f64;
    let mut transition_flags = 0_usize;

    for (index, r) in values.iter().enumerate() {
        let previous_x = x;

        if index > 0 {
            x = update_state(x, *r, scenario.dt);
        }

        let jump_size = (x - previous_x).abs();

        if jump_size > scenario.jump_threshold {
            transition_flags += 1;
        }

        minimum_state = minimum_state.min(x);
        maximum_state = maximum_state.max(x);
        maximum_jump_size = maximum_jump_size.max(jump_size);
    }

    Summary {
        scenario: scenario.name,
        path: path_name,
        initial_state,
        final_state: x,
        minimum_state,
        maximum_state,
        maximum_jump_size,
        transition_flags,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_hysteresis", forward_start: -1.20, forward_end: 1.20, steps: 300, initial_state: -1.00, dt: 0.050, jump_threshold: 0.150 },
        Scenario { name: "slow_forcing", forward_start: -1.20, forward_end: 1.20, steps: 500, initial_state: -1.00, dt: 0.035, jump_threshold: 0.120 },
        Scenario { name: "fast_forcing", forward_start: -1.20, forward_end: 1.20, steps: 150, initial_state: -1.00, dt: 0.075, jump_threshold: 0.220 },
        Scenario { name: "wide_forcing", forward_start: -1.45, forward_end: 1.45, steps: 360, initial_state: -1.10, dt: 0.050, jump_threshold: 0.150 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_critical_transition_hysteresis_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,path,initial_state,final_state,minimum_state,maximum_state,maximum_jump_size,transition_flags"
    )?;

    for scenario in &scenarios {
        let forward_values = linear_space(scenario.forward_start, scenario.forward_end, scenario.steps);
        let forward_summary = simulate_path(scenario, "forward_forcing", &forward_values, scenario.initial_state);

        let backward_values = linear_space(scenario.forward_end, scenario.forward_start, scenario.steps);
        let backward_summary = simulate_path(scenario, "backward_forcing", &backward_values, forward_summary.final_state);

        for result in [forward_summary, backward_summary] {
            writeln!(
                writer,
                "{},{},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
                result.scenario,
                result.path,
                result.initial_state,
                result.final_state,
                result.minimum_state,
                result.maximum_state,
                result.maximum_jump_size,
                result.transition_flags
            )?;
        }
    }

    println!("Rust tipping diagnostics complete.");
    println!("outputs/tables/rust_critical_transition_hysteresis_summary.csv");

    Ok(())
}
