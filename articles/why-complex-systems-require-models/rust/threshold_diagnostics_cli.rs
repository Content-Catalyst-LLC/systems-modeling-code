use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

#[derive(Clone)]
struct Scenario {
    name: &'static str,
    growth_rate: f64,
    balancing_strength: f64,
    target: f64,
    delay: usize,
    threshold: f64,
    threshold_correction: f64,
    shock_time: usize,
    shock_size: f64,
}

fn clamp(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn simulate(s: &Scenario) -> (f64, f64, f64, f64, usize, usize, f64) {
    let periods = 160usize;
    let mut state = vec![12.0_f64];

    let mut minimum_state = 12.0;
    let mut maximum_state = 12.0;
    let mut time_to_peak = 0usize;
    let mut threshold_active_periods = 0usize;
    let mut maximum_balancing_outflow = 0.0;

    for time in 0..=periods {
        let current = *state.last().unwrap();
        let delayed_index = if state.len() > s.delay { state.len() - 1 - s.delay } else { 0 };
        let delayed_state = state[delayed_index];

        let inflow = s.growth_rate * current;
        let balancing_outflow = s.balancing_strength * f64::max(delayed_state - s.target, 0.0);

        let threshold_penalty = if current >= s.threshold {
            threshold_active_periods += 1;
            s.threshold_correction * (current - s.threshold)
        } else {
            0.0
        };

        let shock = if time == s.shock_time { s.shock_size } else { 0.0 };
        let next_state = clamp(current + inflow - balancing_outflow - threshold_penalty + shock, 0.0, 250.0);

        if current > maximum_state {
            maximum_state = current;
            time_to_peak = time;
        }
        if current < minimum_state {
            minimum_state = current;
        }
        if balancing_outflow > maximum_balancing_outflow {
            maximum_balancing_outflow = balancing_outflow;
        }

        state.push(next_state);
    }

    let final_state = state[state.len() - 2];
    (
        minimum_state,
        maximum_state,
        final_state,
        maximum_state - 12.0,
        time_to_peak,
        threshold_active_periods,
        maximum_balancing_outflow,
    )
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_delayed_feedback", growth_rate: 0.080, balancing_strength: 0.060, target: 50.0, delay: 7, threshold: 85.0, threshold_correction: 0.035, shock_time: 70, shock_size: -10.0 },
        Scenario { name: "short_delay", growth_rate: 0.080, balancing_strength: 0.060, target: 50.0, delay: 2, threshold: 85.0, threshold_correction: 0.035, shock_time: 70, shock_size: -10.0 },
        Scenario { name: "long_delay", growth_rate: 0.080, balancing_strength: 0.060, target: 50.0, delay: 14, threshold: 85.0, threshold_correction: 0.035, shock_time: 70, shock_size: -10.0 },
        Scenario { name: "weak_balancing", growth_rate: 0.080, balancing_strength: 0.030, target: 50.0, delay: 7, threshold: 85.0, threshold_correction: 0.035, shock_time: 70, shock_size: -10.0 },
        Scenario { name: "strong_threshold_response", growth_rate: 0.080, balancing_strength: 0.060, target: 50.0, delay: 7, threshold: 85.0, threshold_correction: 0.080, shock_time: 70, shock_size: -10.0 },
        Scenario { name: "higher_growth", growth_rate: 0.105, balancing_strength: 0.060, target: 50.0, delay: 7, threshold: 85.0, threshold_correction: 0.035, shock_time: 70, shock_size: -10.0 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_threshold_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,minimum_state,maximum_state,final_state,maximum_overshoot,time_to_peak,threshold_active_periods,maximum_balancing_outflow")?;

    for scenario in &scenarios {
        let (minimum, maximum, final_state, overshoot, time_to_peak, threshold_periods, max_outflow) = simulate(scenario);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{},{},{:.6}",
            scenario.name,
            minimum,
            maximum,
            final_state,
            overshoot,
            time_to_peak,
            threshold_periods,
            max_outflow
        )?;
    }

    println!("Rust threshold diagnostics complete.");
    println!("outputs/tables/rust_threshold_diagnostics.csv");

    Ok(())
}
