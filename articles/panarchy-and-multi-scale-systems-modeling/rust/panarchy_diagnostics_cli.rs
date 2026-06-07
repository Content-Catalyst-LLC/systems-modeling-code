use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    fast_growth: f64,
    fast_capacity: f64,
    slow_constraint: f64,
    release_threshold: f64,
    release_magnitude: f64,
    revolt_strength: f64,
    remember_strength: f64,
    slow_adjustment: f64,
    slow_target: f64,
}

struct Summary {
    scenario: &'static str,
    final_fast_cycle: f64,
    final_slow_memory: f64,
    release_events: usize,
    maximum_fast_cycle: f64,
    maximum_slow_memory: f64,
    mean_cross_scale_coupling: f64,
}

fn simulate(s: &Scenario, steps: usize) -> Summary {
    let mut fast_cycle = 0.5_f64;
    let mut slow_memory = 1.0_f64;
    let mut release_events = 0_usize;
    let mut maximum_fast_cycle = fast_cycle;
    let mut maximum_slow_memory = slow_memory;
    let mut total_coupling = 0.0_f64;

    for time in 1..=steps {
        if time > 1 {
            fast_cycle = fast_cycle
                + s.fast_growth * fast_cycle * (1.0 - fast_cycle / s.fast_capacity)
                - s.slow_constraint * slow_memory;

            if fast_cycle > s.release_threshold {
                fast_cycle = (fast_cycle - s.release_magnitude).max(0.0);
                slow_memory += s.revolt_strength;
                release_events += 1;
            } else {
                slow_memory = slow_memory + s.slow_adjustment * (s.slow_target - slow_memory);
            }

            fast_cycle = (fast_cycle + s.remember_strength * slow_memory).max(0.0);
        }

        maximum_fast_cycle = maximum_fast_cycle.max(fast_cycle);
        maximum_slow_memory = maximum_slow_memory.max(slow_memory);
        total_coupling += fast_cycle * slow_memory;
    }

    Summary {
        scenario: s.name,
        final_fast_cycle: fast_cycle,
        final_slow_memory: slow_memory,
        release_events,
        maximum_fast_cycle,
        maximum_slow_memory,
        mean_cross_scale_coupling: total_coupling / steps as f64,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_panarchy", fast_growth: 0.16, fast_capacity: 3.20, slow_constraint: 0.08, release_threshold: 2.50, release_magnitude: 1.35, revolt_strength: 0.14, remember_strength: 0.035, slow_adjustment: 0.010, slow_target: 1.60 },
        Scenario { name: "strong_revolt", fast_growth: 0.16, fast_capacity: 3.20, slow_constraint: 0.08, release_threshold: 2.35, release_magnitude: 1.35, revolt_strength: 0.24, remember_strength: 0.035, slow_adjustment: 0.010, slow_target: 1.60 },
        Scenario { name: "strong_remember", fast_growth: 0.16, fast_capacity: 3.20, slow_constraint: 0.08, release_threshold: 2.50, release_magnitude: 1.35, revolt_strength: 0.14, remember_strength: 0.065, slow_adjustment: 0.014, slow_target: 1.60 },
        Scenario { name: "rigid_slow_structure", fast_growth: 0.16, fast_capacity: 3.20, slow_constraint: 0.13, release_threshold: 2.50, release_magnitude: 1.35, revolt_strength: 0.14, remember_strength: 0.020, slow_adjustment: 0.004, slow_target: 1.60 },
        Scenario { name: "weak_memory_high_volatility", fast_growth: 0.17, fast_capacity: 3.10, slow_constraint: 0.06, release_threshold: 2.30, release_magnitude: 1.45, revolt_strength: 0.20, remember_strength: 0.015, slow_adjustment: 0.008, slow_target: 1.45 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_panarchy_multiscale_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_fast_cycle,final_slow_memory,release_events,maximum_fast_cycle,maximum_slow_memory,mean_cross_scale_coupling"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario, 160);
        writeln!(
            writer,
            "{},{:.6},{:.6},{},{:.6},{:.6},{:.6}",
            result.scenario,
            result.final_fast_cycle,
            result.final_slow_memory,
            result.release_events,
            result.maximum_fast_cycle,
            result.maximum_slow_memory,
            result.mean_cross_scale_coupling
        )?;
    }

    println!("Rust panarchy diagnostics complete.");
    println!("outputs/tables/rust_panarchy_multiscale_summary.csv");

    Ok(())
}
