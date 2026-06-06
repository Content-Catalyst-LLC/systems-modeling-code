use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

#[derive(Clone)]
struct Scenario {
    name: &'static str,
    coupling_strength: f64,
    recovery_rate: f64,
    redundancy: f64,
    shock_size: f64,
}

fn clamp(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn simulate(scenario: &Scenario) -> (f64, f64, f64, f64) {
    let mut state = 1.0;
    let mut min_state = state;
    let n_steps = 120;
    let shock_time = 40;

    for t in 1..n_steps {
        let dependency_loss = scenario.coupling_strength * (state - 1.0) * (1.0 - scenario.redundancy);
        let recovery = scenario.recovery_rate * (1.0 - state);
        let shock = if t == shock_time { scenario.shock_size } else { 0.0 };

        state = clamp(state + dependency_loss + recovery + shock, 0.0, 1.25);
        if state < min_state {
            min_state = state;
        }
    }

    (min_state, 1.0 - min_state, state, 1.0 - state)
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline", coupling_strength: 0.18, recovery_rate: 0.075, redundancy: 0.20, shock_size: -0.55 },
        Scenario { name: "high_coupling", coupling_strength: 0.28, recovery_rate: 0.070, redundancy: 0.12, shock_size: -0.55 },
        Scenario { name: "higher_redundancy", coupling_strength: 0.16, recovery_rate: 0.105, redundancy: 0.42, shock_size: -0.55 },
        Scenario { name: "severe_shock", coupling_strength: 0.18, recovery_rate: 0.065, redundancy: 0.20, shock_size: -0.72 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_systems_model_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,minimum_state,maximum_loss,final_state,unrecovered_loss")?;

    for scenario in &scenarios {
        let (minimum_state, maximum_loss, final_state, unrecovered_loss) = simulate(scenario);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6}",
            scenario.name, minimum_state, maximum_loss, final_state, unrecovered_loss
        )?;
    }

    println!("Rust diagnostics CLI complete.");
    println!("outputs/tables/rust_systems_model_diagnostics.csv");

    Ok(())
}
