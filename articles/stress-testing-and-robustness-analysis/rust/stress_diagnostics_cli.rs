use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Strategy {
    name: &'static str,
    redundancy: f64,
    adaptive_response: f64,
}

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn simulate_strategy(
    demand_growth: f64,
    capacity_loss: f64,
    shock_duration: usize,
    recovery_drag: f64,
    redundancy: f64,
    adaptive_response: f64,
) -> (f64, f64, f64, f64) {
    let baseline_capacity = 100.0_f64;
    let mut demand = 55.0_f64;
    let mut capacity = baseline_capacity * (1.0 + redundancy);
    let mut minimum_service = 1.0_f64;
    let mut cumulative_unmet = 0.0_f64;
    let mut failure_count = 0_usize;
    let steps = 72_usize;
    let shock_start = 28_usize;

    for time in 1..=steps {
        demand *= 1.0 + demand_growth;
        let shock_active = time >= shock_start && time < shock_start + shock_duration;

        if time == shock_start {
            capacity = (capacity - capacity_loss).max(0.0);
        }

        if shock_active {
            demand *= 1.010;
        } else {
            let recovery_rate = (0.12 + adaptive_response - recovery_drag).max(0.0);
            let target_capacity = baseline_capacity * (1.0 + redundancy);
            capacity += recovery_rate * (target_capacity - capacity);
        }

        let service_ratio = if demand <= 0.0 { 1.0 } else { (capacity / demand).min(1.0) };
        let unmet = (demand - capacity).max(0.0);

        minimum_service = minimum_service.min(service_ratio);
        cumulative_unmet += unmet;

        if service_ratio < 0.85 {
            failure_count += 1;
        }
    }

    let score = (100.0 - 70.0 * (1.0 - minimum_service) - 0.05 * cumulative_unmet - 0.40 * failure_count as f64)
        .max(0.0)
        .min(100.0);

    (
        minimum_service,
        cumulative_unmet,
        failure_count as f64 / steps as f64,
        score,
    )
}

fn main() -> std::io::Result<()> {
    let strategies = vec![
        Strategy { name: "Strategy_A_efficiency", redundancy: 0.02, adaptive_response: 0.02 },
        Strategy { name: "Strategy_B_balanced_resilience", redundancy: 0.12, adaptive_response: 0.06 },
        Strategy { name: "Strategy_C_high_redundancy", redundancy: 0.25, adaptive_response: 0.03 },
        Strategy { name: "Strategy_D_adaptive_pathway", redundancy: 0.08, adaptive_response: 0.11 },
    ];

    let mut seed = 42_u64;

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_stress_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario_id,strategy,demand_growth,capacity_loss,shock_duration,recovery_drag,minimum_service_ratio,cumulative_unmet_demand,failure_frequency,resilience_score"
    )?;

    for scenario_id in 1..=600 {
        let demand_growth = 0.008 + lcg(&mut seed) * (0.035 - 0.008);
        let capacity_loss = lcg(&mut seed) * 45.0;
        let shock_duration = 1 + (lcg(&mut seed) * 20.0).floor() as usize;
        let recovery_drag = lcg(&mut seed) * 0.09;

        for strategy in &strategies {
            let (minimum_service, cumulative_unmet, failure_frequency, score) = simulate_strategy(
                demand_growth,
                capacity_loss,
                shock_duration,
                recovery_drag,
                strategy.redundancy,
                strategy.adaptive_response,
            );

            writeln!(
                writer,
                "{},{},{:.6},{:.6},{},{:.6},{:.6},{:.6},{:.6},{:.6}",
                scenario_id,
                strategy.name,
                demand_growth,
                capacity_loss,
                shock_duration,
                recovery_drag,
                minimum_service,
                cumulative_unmet,
                failure_frequency,
                score
            )?;
        }
    }

    println!("Rust stress diagnostics complete.");
    println!("outputs/tables/rust_stress_diagnostics.csv");

    Ok(())
}
