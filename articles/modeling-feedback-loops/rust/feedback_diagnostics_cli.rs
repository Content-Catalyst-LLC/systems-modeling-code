use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

fn simulate_delayed_balancing(initial: f64, target: f64, correction: f64, delay: usize, steps: usize) -> Vec<f64> {
    let mut values = vec![0.0_f64; steps];
    values[0] = initial;

    for t in 1..steps {
        let delayed_index = if t >= delay { t - delay } else { 0 };
        values[t] = values[t - 1] + correction * (target - values[delayed_index]);
    }

    values
}

fn target_crossings(values: &[f64], target: f64) -> usize {
    let mut changes = 0_usize;

    for i in 1..values.len() {
        let left = values[i - 1] - target;
        let right = values[i] - target;

        if left == 0.0 || right == 0.0 {
            continue;
        }

        if (left < 0.0 && right > 0.0) || (left > 0.0 && right < 0.0) {
            changes += 1;
        }
    }

    changes
}

fn mean_absolute_gap(values: &[f64], target: f64) -> f64 {
    let mut total = 0.0_f64;
    for value in values {
        total += (*value - target).abs();
    }
    total / values.len() as f64
}

fn main() -> std::io::Result<()> {
    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_delayed_feedback_ensemble.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario_id,delay,correction_strength,final_state,maximum_state,minimum_state,overshoot_above_target,target_crossings,mean_absolute_target_gap"
    )?;

    let mut scenario_id = 0_usize;
    let target = 20.0_f64;

    for delay in [1_usize, 3, 5, 8, 12] {
        for correction in [0.12_f64, 0.20, 0.28, 0.36] {
            scenario_id += 1;
            let values = simulate_delayed_balancing(5.0, target, correction, delay, 90);

            let mut maximum = values[0];
            let mut minimum = values[0];

            for value in &values {
                maximum = maximum.max(*value);
                minimum = minimum.min(*value);
            }

            let overshoot = (maximum - target).max(0.0);

            writeln!(
                writer,
                "{},{},{:.6},{:.6},{:.6},{:.6},{:.6},{},{:.6}",
                scenario_id,
                delay,
                correction,
                values[values.len() - 1],
                maximum,
                minimum,
                overshoot,
                target_crossings(&values, target),
                mean_absolute_gap(&values, target)
            )?;
        }
    }

    println!("Rust feedback diagnostics complete.");
    println!("outputs/tables/rust_delayed_feedback_ensemble.csv");

    Ok(())
}
