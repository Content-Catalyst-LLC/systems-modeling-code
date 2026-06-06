use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Parameters {
    growth_rate: f64,
    carrying_capacity: f64,
    extraction_pressure: f64,
    recovery_delay: usize,
    feedback_strength: f64,
    shock_intensity: f64,
}

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn simulate_system(p: &Parameters) -> (f64, f64, f64, f64) {
    let steps = 80usize;
    let mut state = vec![0.0_f64; steps];
    state[0] = 10.0;
    let shock_time = steps / 2;

    for time in 1..steps {
        let delayed_index = if time >= p.recovery_delay { time - p.recovery_delay } else { 0 };
        let delayed_recovery = p.feedback_strength * state[delayed_index];
        let shock_effect = if time == shock_time { p.shock_intensity } else { 0.0 };

        let previous = state[time - 1];
        let next_state = previous
            + p.growth_rate * previous * (1.0 - previous / p.carrying_capacity)
            - p.extraction_pressure * previous
            + delayed_recovery
            - shock_effect;

        state[time] = next_state.max(0.0);
    }

    let final_state = state[steps - 1];
    let maximum_state = state.iter().fold(0.0_f64, |acc, value| acc.max(*value));
    let minimum_state = state.iter().fold(f64::INFINITY, |acc, value| acc.min(*value));
    let mean_state = state.iter().sum::<f64>() / steps as f64;

    (final_state, maximum_state, minimum_state, mean_state)
}

fn main() -> std::io::Result<()> {
    let mut seed = 60606_u64;

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_sensitivity_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "run_id,growth_rate,carrying_capacity,extraction_pressure,recovery_delay,feedback_strength,shock_intensity,final_state,maximum_state,minimum_state,mean_state")?;

    for run_id in 1..=400 {
        let p = Parameters {
            growth_rate: 0.04 + lcg(&mut seed) * (0.12 - 0.04),
            carrying_capacity: 60.0 + lcg(&mut seed) * 80.0,
            extraction_pressure: 0.005 + lcg(&mut seed) * (0.060 - 0.005),
            recovery_delay: 1 + (lcg(&mut seed) * 12.0).floor() as usize,
            feedback_strength: 0.005 + lcg(&mut seed) * (0.050 - 0.005),
            shock_intensity: lcg(&mut seed) * 24.0,
        };

        let (final_state, maximum_state, minimum_state, mean_state) = simulate_system(&p);

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6}",
            run_id,
            p.growth_rate,
            p.carrying_capacity,
            p.extraction_pressure,
            p.recovery_delay,
            p.feedback_strength,
            p.shock_intensity,
            final_state,
            maximum_state,
            minimum_state,
            mean_state
        )?;
    }

    println!("Rust sensitivity diagnostics complete.");
    println!("outputs/tables/rust_sensitivity_diagnostics.csv");

    Ok(())
}
