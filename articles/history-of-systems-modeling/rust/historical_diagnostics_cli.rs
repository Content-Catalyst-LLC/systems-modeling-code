use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

#[derive(Clone)]
struct Scenario {
    name: &'static str,
    growth_rate: f64,
    carrying_capacity: f64,
    balancing_strength: f64,
    target: f64,
    delay: usize,
    shock_time: usize,
    shock_size: f64,
}

fn clamp(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn simulate(s: &Scenario) -> (f64, f64, f64, f64, usize, f64) {
    let n_steps = 160usize;
    let mut exponential = vec![10.0_f64];
    let mut logistic = vec![10.0_f64];
    let mut delayed_feedback = vec![10.0_f64];

    let mut max_delayed = 10.0;
    let mut time_to_peak = 0usize;
    let mut max_outflow = 0.0;

    for time in 0..=n_steps {
        let current_exponential = *exponential.last().unwrap();
        let current_logistic = *logistic.last().unwrap();
        let current_delayed = *delayed_feedback.last().unwrap();

        let delayed_index = if delayed_feedback.len() > s.delay {
            delayed_feedback.len() - 1 - s.delay
        } else {
            0
        };

        let delayed_state = delayed_feedback[delayed_index];
        let inflow = s.growth_rate * current_delayed;
        let outflow = s.balancing_strength * f64::max(delayed_state - s.target, 0.0);
        let shock = if time == s.shock_time { s.shock_size } else { 0.0 };

        let next_exponential = clamp(current_exponential + s.growth_rate * current_exponential, 0.0, 250.0);
        let next_logistic = clamp(
            current_logistic + s.growth_rate * current_logistic * (1.0 - current_logistic / s.carrying_capacity),
            0.0,
            250.0,
        );
        let next_delayed = clamp(current_delayed + inflow - outflow + shock, 0.0, 250.0);

        exponential.push(next_exponential);
        logistic.push(next_logistic);
        delayed_feedback.push(next_delayed);

        if current_delayed > max_delayed {
            max_delayed = current_delayed;
            time_to_peak = time;
        }
        if outflow > max_outflow {
            max_outflow = outflow;
        }
    }

    (
        exponential[exponential.len() - 2],
        logistic[logistic.len() - 2],
        delayed_feedback[delayed_feedback.len() - 2],
        max_delayed,
        time_to_peak,
        max_outflow,
    )
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_historical_dynamics", growth_rate: 0.080, carrying_capacity: 80.0, balancing_strength: 0.060, target: 55.0, delay: 7, shock_time: 90, shock_size: -8.0 },
        Scenario { name: "short_delay", growth_rate: 0.080, carrying_capacity: 80.0, balancing_strength: 0.060, target: 55.0, delay: 2, shock_time: 90, shock_size: -8.0 },
        Scenario { name: "long_delay", growth_rate: 0.080, carrying_capacity: 80.0, balancing_strength: 0.060, target: 55.0, delay: 14, shock_time: 90, shock_size: -8.0 },
        Scenario { name: "weak_balancing", growth_rate: 0.080, carrying_capacity: 80.0, balancing_strength: 0.030, target: 55.0, delay: 7, shock_time: 90, shock_size: -8.0 },
        Scenario { name: "higher_growth", growth_rate: 0.105, carrying_capacity: 80.0, balancing_strength: 0.060, target: 55.0, delay: 7, shock_time: 90, shock_size: -8.0 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_historical_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,final_exponential,final_logistic,final_delayed_feedback,maximum_delayed_feedback,time_to_peak,maximum_outflow")?;

    for scenario in &scenarios {
        let (final_exponential, final_logistic, final_delayed, max_delayed, time_to_peak, max_outflow) = simulate(scenario);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{},{:.6}",
            scenario.name,
            final_exponential,
            final_logistic,
            final_delayed,
            max_delayed,
            time_to_peak,
            max_outflow
        )?;
    }

    println!("Rust historical diagnostics complete.");
    println!("outputs/tables/rust_historical_diagnostics.csv");

    Ok(())
}
