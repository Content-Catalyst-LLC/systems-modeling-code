use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

fn logistic_map(r: f64, initial_state: f64, steps: usize) -> Vec<f64> {
    let mut values = vec![0.0_f64; steps];
    values[0] = initial_state;

    for i in 1..steps {
        values[i] = r * values[i - 1] * (1.0 - values[i - 1]);
    }

    values
}

fn entropy(values: &[f64], bins: usize) -> f64 {
    let mut low = values[0];
    let mut high = values[0];

    for value in values {
        if *value < low {
            low = *value;
        }
        if *value > high {
            high = *value;
        }
    }

    if (high - low).abs() < 1e-12 {
        return 0.0;
    }

    let mut counts = vec![0_usize; bins];

    for value in values {
        let mut index = ((*value - low) / (high - low) * bins as f64).floor() as usize;
        if index >= bins {
            index = bins - 1;
        }
        counts[index] += 1;
    }

    let total: usize = counts.iter().sum();
    let mut result = 0.0_f64;

    for count in counts {
        if count > 0 {
            let p = count as f64 / total as f64;
            result -= p * p.ln();
        }
    }

    result
}

fn main() -> std::io::Result<()> {
    let steps = 120_usize;
    let trajectory_1 = logistic_map(3.9, 0.4000, steps);
    let trajectory_2 = logistic_map(3.9, 0.4001, steps);

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_logistic_sensitivity.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "time,trajectory_1,trajectory_2,absolute_difference")?;

    let mut max_diff = 0.0_f64;
    let mut sum_diff = 0.0_f64;

    for i in 0..steps {
        let diff = (trajectory_1[i] - trajectory_2[i]).abs();
        max_diff = max_diff.max(diff);
        sum_diff += diff;

        writeln!(
            writer,
            "{},{:.8},{:.8},{:.8}",
            i + 1,
            trajectory_1[i],
            trajectory_2[i],
            diff
        )?;
    }

    let summary_file = File::create("outputs/tables/rust_complexity_math_summary.csv")?;
    let mut summary_writer = BufWriter::new(summary_file);

    writeln!(summary_writer, "metric,value")?;
    writeln!(summary_writer, "maximum_absolute_difference,{:.8}", max_diff)?;
    writeln!(summary_writer, "mean_absolute_difference,{:.8}", sum_diff / steps as f64)?;
    writeln!(summary_writer, "trajectory_entropy,{:.8}", entropy(&trajectory_1, 10))?;

    println!("Rust complex systems mathematics diagnostics complete.");
    println!("outputs/tables/rust_logistic_sensitivity.csv");
    println!("outputs/tables/rust_complexity_math_summary.csv");

    Ok(())
}
