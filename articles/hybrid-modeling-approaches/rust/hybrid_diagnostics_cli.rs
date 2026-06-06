use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    n_agents: usize,
    n_steps: usize,
    service_capacity: usize,
    pressure_sensitivity: f64,
    baseline_low: f64,
    baseline_high: f64,
    seed: u64,
}

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn clamp(value: f64) -> f64 {
    value.max(0.0).min(1.0)
}

fn simulate(s: &Scenario) -> (usize, f64, usize, f64, usize) {
    let mut seed = s.seed;
    let mut propensities = vec![0.0_f64; s.n_agents];

    for i in 0..s.n_agents {
        propensities[i] = s.baseline_low + lcg(&mut seed) * (s.baseline_high - s.baseline_low);
    }

    let mut queue_length = 0usize;
    let mut total_queue = 0usize;
    let mut maximum_queue = 0usize;
    let mut total_utilization = 0.0_f64;
    let mut total_arrivals = 0usize;

    for _ in 0..s.n_steps {
        let pressure = queue_length as f64 / s.service_capacity as f64;
        let mut arrivals = 0usize;

        for propensity in &propensities {
            let effective = clamp(*propensity - s.pressure_sensitivity * pressure);
            if lcg(&mut seed) < effective {
                arrivals += 1;
            }
        }

        let available_work = queue_length + arrivals;
        let served = available_work.min(s.service_capacity);
        queue_length = available_work - served;

        total_arrivals += arrivals;
        total_queue += queue_length;
        maximum_queue = maximum_queue.max(queue_length);
        total_utilization += served as f64 / s.service_capacity as f64;
    }

    (
        total_arrivals,
        total_queue as f64 / s.n_steps as f64,
        maximum_queue,
        total_utilization / s.n_steps as f64,
        queue_length,
    )
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_hybrid_agent_queue", n_agents: 160, n_steps: 80, service_capacity: 28, pressure_sensitivity: 0.18, baseline_low: 0.10, baseline_high: 0.42, seed: 60606 },
        Scenario { name: "low_capacity", n_agents: 160, n_steps: 80, service_capacity: 18, pressure_sensitivity: 0.18, baseline_low: 0.10, baseline_high: 0.42, seed: 60607 },
        Scenario { name: "high_capacity", n_agents: 160, n_steps: 80, service_capacity: 42, pressure_sensitivity: 0.18, baseline_low: 0.10, baseline_high: 0.42, seed: 60608 },
        Scenario { name: "strong_pressure_feedback", n_agents: 160, n_steps: 80, service_capacity: 28, pressure_sensitivity: 0.35, baseline_low: 0.10, baseline_high: 0.42, seed: 60610 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_hybrid_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,total_arrivals,average_queue_length,maximum_queue_length,average_utilization,final_queue_length")?;

    for scenario in &scenarios {
        let (total_arrivals, average_queue, maximum_queue, average_utilization, final_queue) = simulate(scenario);
        writeln!(
            writer,
            "{},{},{:.6},{},{:.6},{}",
            scenario.name,
            total_arrivals,
            average_queue,
            maximum_queue,
            average_utilization,
            final_queue
        )?;
    }

    println!("Rust hybrid diagnostics complete.");
    println!("outputs/tables/rust_hybrid_diagnostics.csv");

    Ok(())
}
