use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    collapse_threshold: f64,
    recovery_threshold: f64,
    intervention_time: usize,
    pressure_growth: f64,
    recovery_effort: f64,
}

struct Summary {
    scenario: &'static str,
    initial_state: f64,
    final_state: f64,
    minimum_state: f64,
    maximum_pressure: f64,
    degraded_periods: usize,
    final_regime: &'static str,
    mean_net_flow: f64,
    hysteresis_gap: f64,
}

fn simulate(s: &Scenario, steps: usize) -> Summary {
    let mut system_state = 82.0_f64;
    let initial_state = system_state;
    let mut pressure = 20.0_f64;
    let mut regime = "stable";

    let mut minimum_state = system_state;
    let mut maximum_pressure = pressure;
    let mut degraded_periods = 0_usize;
    let mut total_net_flow = 0.0_f64;

    for time in 1..=steps {
        let mut net_flow = 0.0_f64;

        if time > 1 {
            pressure += s.pressure_growth;

            if time >= s.intervention_time {
                pressure = (pressure - s.recovery_effort).max(0.0);
            }

            if regime == "stable" && pressure >= s.collapse_threshold {
                regime = "degraded";
            } else if regime == "degraded" && pressure <= s.recovery_threshold {
                regime = "stable";
            }

            let (damage_flow, recovery_flow) = if regime == "stable" {
                (0.05 * pressure + 0.002 * pressure * pressure, 2.6)
            } else {
                (0.09 * pressure + 0.006 * pressure * pressure + 1.8, 0.8 + 0.03 * system_state)
            };

            net_flow = recovery_flow - damage_flow;
            system_state = (system_state + net_flow).max(0.0).min(100.0);
        }

        if regime == "degraded" {
            degraded_periods += 1;
        }

        minimum_state = minimum_state.min(system_state);
        maximum_pressure = maximum_pressure.max(pressure);
        total_net_flow += net_flow;
    }

    Summary {
        scenario: s.name,
        initial_state,
        final_state: system_state,
        minimum_state,
        maximum_pressure,
        degraded_periods,
        final_regime: regime,
        mean_net_flow: total_net_flow / steps as f64,
        hysteresis_gap: s.collapse_threshold - s.recovery_threshold,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "early_intervention", collapse_threshold: 70.0, recovery_threshold: 45.0, intervention_time: 55, pressure_growth: 0.85, recovery_effort: 1.20 },
        Scenario { name: "late_intervention", collapse_threshold: 70.0, recovery_threshold: 45.0, intervention_time: 85, pressure_growth: 0.85, recovery_effort: 1.20 },
        Scenario { name: "strong_recovery", collapse_threshold: 70.0, recovery_threshold: 45.0, intervention_time: 85, pressure_growth: 0.85, recovery_effort: 2.00 },
        Scenario { name: "lower_threshold_stress", collapse_threshold: 58.0, recovery_threshold: 38.0, intervention_time: 70, pressure_growth: 0.95, recovery_effort: 1.20 },
        Scenario { name: "hysteresis_trap", collapse_threshold: 66.0, recovery_threshold: 30.0, intervention_time: 88, pressure_growth: 0.90, recovery_effort: 1.30 },
        Scenario { name: "rapid_prevention", collapse_threshold: 70.0, recovery_threshold: 45.0, intervention_time: 40, pressure_growth: 0.85, recovery_effort: 1.80 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_nonlinear_regime_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,initial_state,final_state,minimum_state,maximum_pressure,degraded_periods,final_regime,mean_net_flow,hysteresis_gap"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario, 140);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{},{},{:.6},{:.6}",
            result.scenario,
            result.initial_state,
            result.final_state,
            result.minimum_state,
            result.maximum_pressure,
            result.degraded_periods,
            result.final_regime,
            result.mean_net_flow,
            result.hysteresis_gap
        )?;
    }

    println!("Rust nonlinear regime diagnostics complete.");
    println!("outputs/tables/rust_nonlinear_regime_summary.csv");

    Ok(())
}
