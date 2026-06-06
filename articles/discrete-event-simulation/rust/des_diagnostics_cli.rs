use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    arrival_rate: f64,
    service_rate: f64,
    entities: usize,
    seed: u64,
}

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn exponential(seed: &mut u64, rate: f64) -> f64 {
    let draw = 1.0 - lcg(seed).max(1e-12);
    -draw.ln() / rate
}

fn simulate(s: &Scenario) -> (f64, f64, f64, f64) {
    let mut seed = s.seed;

    let mut arrival_time = vec![0.0_f64; s.entities];
    let mut service_time = vec![0.0_f64; s.entities];
    let mut service_start = vec![0.0_f64; s.entities];
    let mut departure_time = vec![0.0_f64; s.entities];
    let mut waiting_time = vec![0.0_f64; s.entities];

    for i in 0..s.entities {
        if i == 0 {
            arrival_time[i] = exponential(&mut seed, s.arrival_rate);
        } else {
            arrival_time[i] = arrival_time[i - 1] + exponential(&mut seed, s.arrival_rate);
        }
        service_time[i] = exponential(&mut seed, s.service_rate);
    }

    service_start[0] = arrival_time[0];
    departure_time[0] = service_start[0] + service_time[0];

    for i in 1..s.entities {
        service_start[i] = arrival_time[i].max(departure_time[i - 1]);
        departure_time[i] = service_start[i] + service_time[i];
        waiting_time[i] = service_start[i] - arrival_time[i];
    }

    let average_wait = waiting_time.iter().sum::<f64>() / s.entities as f64;
    let maximum_wait = waiting_time.iter().fold(0.0_f64, |acc, value| acc.max(*value));
    let service_level_share = waiting_time.iter().filter(|value| **value <= 12.0).count() as f64 / s.entities as f64;
    let implied_utilization = s.arrival_rate / s.service_rate;

    (average_wait, maximum_wait, service_level_share, implied_utilization)
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_single_server", arrival_rate: 0.18, service_rate: 0.22, entities: 240, seed: 42 },
        Scenario { name: "higher_arrival_pressure", arrival_rate: 0.21, service_rate: 0.22, entities: 240, seed: 43 },
        Scenario { name: "faster_service", arrival_rate: 0.18, service_rate: 0.30, entities: 240, seed: 44 },
        Scenario { name: "stress_surge", arrival_rate: 0.25, service_rate: 0.22, entities: 240, seed: 45 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_des_queue_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,completed_entities,average_waiting_time,maximum_waiting_time,service_level_share,implied_utilization")?;

    for scenario in &scenarios {
        let (avg_wait, max_wait, service_share, utilization) = simulate(scenario);
        writeln!(
            writer,
            "{},{},{:.6},{:.6},{:.6},{:.6}",
            scenario.name,
            scenario.entities,
            avg_wait,
            max_wait,
            service_share,
            utilization
        )?;
    }

    println!("Rust DES diagnostics complete.");
    println!("outputs/tables/rust_des_queue_diagnostics.csv");

    Ok(())
}
