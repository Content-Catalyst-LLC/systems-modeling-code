use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

fn linear_value(start: f64, stop: f64, index: usize, count: usize) -> f64 {
    let step = (stop - start) / (count as f64 - 1.0);
    start + index as f64 * step
}

fn main() -> std::io::Result<()> {
    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_bifurcation_order_parameter_branches.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "step,control_parameter,stable_state_positive,stable_state_negative,neutral_state,order_parameter_magnitude,phase_label"
    )?;

    let count = 301_usize;

    for index in 0..count {
        let control = linear_value(-1.5, 1.5, index, count);
        let mut positive = 0.0_f64;
        let mut negative = 0.0_f64;
        let mut magnitude = 0.0_f64;
        let mut label = "single neutral phase";

        if control > 0.0 {
            positive = control.sqrt();
            negative = -control.sqrt();
            magnitude = positive;
            label = "two ordered phases";
        }

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            index + 1,
            control,
            positive,
            negative,
            0.0_f64,
            magnitude,
            label
        )?;
    }

    println!("Rust phase-transition diagnostics complete.");
    println!("outputs/tables/rust_bifurcation_order_parameter_branches.csv");

    Ok(())
}
