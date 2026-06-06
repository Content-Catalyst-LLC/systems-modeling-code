use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

#[derive(Clone)]
struct Scenario {
    name: &'static str,
    n_agents: usize,
    n_steps: usize,
    initial_adopters: usize,
    threshold_low: f64,
    threshold_high: f64,
    neighbor_radius: usize,
    seed: u64,
}

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn adoption_rate(values: &[bool]) -> f64 {
    values.iter().filter(|value| **value).count() as f64 / values.len() as f64
}

fn simulate(s: &Scenario) -> (f64, f64, usize, usize, f64) {
    let mut seed = s.seed;

    let mut thresholds = vec![0.0_f64; s.n_agents];
    for i in 0..s.n_agents {
        thresholds[i] = s.threshold_low + lcg(&mut seed) * (s.threshold_high - s.threshold_low);
    }

    let mut adopted = vec![false; s.n_agents];
    let mut indices: Vec<usize> = (0..s.n_agents).collect();

    for i in 0..s.n_agents {
        let j = (lcg(&mut seed) * s.n_agents as f64) as usize % s.n_agents;
        indices.swap(i, j);
    }

    for i in 0..s.initial_adopters.min(s.n_agents) {
        adopted[indices[i]] = true;
    }

    let initial_rate = adoption_rate(&adopted);
    let mut final_rate = initial_rate;
    let mut peak_new = 0usize;
    let mut time_to_half = 0usize;

    for time in 1..=s.n_steps {
        let previous = adopted.clone();

        for i in 0..s.n_agents {
            if previous[i] {
                continue;
            }

            let mut local_count = 0usize;
            let mut adopted_count = 0usize;

            for offset in 1..=s.neighbor_radius {
                let left = (i + s.n_agents - offset) % s.n_agents;
                let right = (i + offset) % s.n_agents;

                local_count += 2;
                if previous[left] {
                    adopted_count += 1;
                }
                if previous[right] {
                    adopted_count += 1;
                }
            }

            let local_share = adopted_count as f64 / local_count as f64;
            if local_share >= thresholds[i] {
                adopted[i] = true;
            }
        }

        let new_adopters = adopted
            .iter()
            .zip(previous.iter())
            .filter(|(now, before)| **now && !**before)
            .count();

        if new_adopters > peak_new {
            peak_new = new_adopters;
        }

        final_rate = adoption_rate(&adopted);
        if time_to_half == 0 && final_rate >= 0.5 {
            time_to_half = time;
        }
    }

    (
        initial_rate,
        final_rate,
        peak_new,
        time_to_half,
        thresholds.iter().sum::<f64>() / thresholds.len() as f64,
    )
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_threshold_adoption", n_agents: 180, n_steps: 50, initial_adopters: 12, threshold_low: 0.10, threshold_high: 0.70, neighbor_radius: 2, seed: 101 },
        Scenario { name: "low_threshold_population", n_agents: 180, n_steps: 50, initial_adopters: 12, threshold_low: 0.05, threshold_high: 0.45, neighbor_radius: 2, seed: 102 },
        Scenario { name: "high_threshold_population", n_agents: 180, n_steps: 50, initial_adopters: 12, threshold_low: 0.35, threshold_high: 0.85, neighbor_radius: 2, seed: 103 },
        Scenario { name: "wider_neighborhood", n_agents: 180, n_steps: 50, initial_adopters: 12, threshold_low: 0.10, threshold_high: 0.70, neighbor_radius: 4, seed: 104 },
        Scenario { name: "more_initial_adopters", n_agents: 180, n_steps: 50, initial_adopters: 28, threshold_low: 0.10, threshold_high: 0.70, neighbor_radius: 2, seed: 105 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_abm_threshold_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,initial_adoption_rate,final_adoption_rate,peak_new_adopters,time_to_half_adoption,mean_threshold")?;

    for scenario in &scenarios {
        let (initial_rate, final_rate, peak_new, time_to_half, mean_threshold) = simulate(scenario);
        writeln!(
            writer,
            "{},{:.6},{:.6},{},{},{:.6}",
            scenario.name,
            initial_rate,
            final_rate,
            peak_new,
            time_to_half,
            mean_threshold
        )?;
    }

    println!("Rust ABM diagnostics complete.");
    println!("outputs/tables/rust_abm_threshold_diagnostics.csv");

    Ok(())
}
