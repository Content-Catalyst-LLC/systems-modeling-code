use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

#[derive(Clone)]
struct Scenario {
    name: &'static str,
    growth_rate: f64,
    balancing_strength: f64,
    target: f64,
    delay: usize,
    capacity: f64,
    threshold: f64,
    threshold_correction: f64,
    shock_time: usize,
    shock_size: f64,
}

fn clamp(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn simulate(s: &Scenario) -> (f64, f64, f64, usize, f64, f64, usize) {
    let periods = 160usize;
    let mut stock = vec![20.0_f64];

    let mut min_stock = 20.0;
    let mut max_stock = 20.0;
    let mut time_to_peak = 0usize;
    let mut max_inflow = 0.0;
    let mut max_outflow = 0.0;
    let mut threshold_active_periods = 0usize;

    for time in 0..=periods {
        let current = *stock.last().unwrap();
        let delayed_index = if stock.len() > s.delay { stock.len() - 1 - s.delay } else { 0 };
        let delayed_stock = stock[delayed_index];

        let inflow = s.growth_rate * current * (1.0 - current / s.capacity);
        let outflow = s.balancing_strength * f64::max(delayed_stock - s.target, 0.0);

        let threshold_penalty = if current >= s.threshold {
            threshold_active_periods += 1;
            s.threshold_correction * (current - s.threshold)
        } else {
            0.0
        };

        let shock = if time == s.shock_time { s.shock_size } else { 0.0 };
        let next_stock = clamp(current + inflow - outflow - threshold_penalty + shock, 0.0, 250.0);

        if current > max_stock {
            max_stock = current;
            time_to_peak = time;
        }
        if current < min_stock {
            min_stock = current;
        }
        if inflow > max_inflow {
            max_inflow = inflow;
        }
        if outflow > max_outflow {
            max_outflow = outflow;
        }

        stock.push(next_stock);
    }

    let final_stock = stock[stock.len() - 2];

    (
        min_stock,
        max_stock,
        final_stock,
        time_to_peak,
        max_inflow,
        max_outflow,
        threshold_active_periods,
    )
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_system_dynamics", growth_rate: 0.090, balancing_strength: 0.055, target: 62.0, delay: 7, capacity: 100.0, threshold: 82.0, threshold_correction: 0.040, shock_time: 95, shock_size: -10.0 },
        Scenario { name: "short_delay", growth_rate: 0.090, balancing_strength: 0.055, target: 62.0, delay: 2, capacity: 100.0, threshold: 82.0, threshold_correction: 0.040, shock_time: 95, shock_size: -10.0 },
        Scenario { name: "long_delay", growth_rate: 0.090, balancing_strength: 0.055, target: 62.0, delay: 14, capacity: 100.0, threshold: 82.0, threshold_correction: 0.040, shock_time: 95, shock_size: -10.0 },
        Scenario { name: "weak_balancing", growth_rate: 0.090, balancing_strength: 0.025, target: 62.0, delay: 7, capacity: 100.0, threshold: 82.0, threshold_correction: 0.040, shock_time: 95, shock_size: -10.0 },
        Scenario { name: "strong_balancing", growth_rate: 0.090, balancing_strength: 0.090, target: 62.0, delay: 7, capacity: 100.0, threshold: 82.0, threshold_correction: 0.040, shock_time: 95, shock_size: -10.0 },
        Scenario { name: "lower_capacity", growth_rate: 0.090, balancing_strength: 0.055, target: 62.0, delay: 7, capacity: 75.0, threshold: 82.0, threshold_correction: 0.040, shock_time: 95, shock_size: -10.0 },
        Scenario { name: "strong_threshold_correction", growth_rate: 0.090, balancing_strength: 0.055, target: 62.0, delay: 7, capacity: 100.0, threshold: 82.0, threshold_correction: 0.090, shock_time: 95, shock_size: -10.0 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_system_dynamics_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,minimum_stock,maximum_stock,final_stock,time_to_peak,maximum_inflow,maximum_outflow,threshold_active_periods")?;

    for scenario in &scenarios {
        let (minimum, maximum, final_stock, time_to_peak, max_inflow, max_outflow, threshold_periods) = simulate(scenario);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{},{:.6},{:.6},{}",
            scenario.name,
            minimum,
            maximum,
            final_stock,
            time_to_peak,
            max_inflow,
            max_outflow,
            threshold_periods
        )?;
    }

    println!("Rust system dynamics diagnostics complete.");
    println!("outputs/tables/rust_system_dynamics_diagnostics.csv");

    Ok(())
}
