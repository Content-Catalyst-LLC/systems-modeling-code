use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Policy {
    name: &'static str,
    policy_drag: f64,
    resilience_buffer: f64,
}

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn resilience_score(final_state: f64, maximum_state: f64, cumulative_cost: f64) -> f64 {
    let score = 100.0 - 0.8 * final_state - 0.3 * maximum_state - 0.2 * cumulative_cost;
    score.max(0.0).min(100.0)
}

fn simulate_policy(growth: f64, policy_drag: f64, external_shock: f64, shock_time: usize, resilience_buffer: f64) -> (f64, f64, f64, f64) {
    let mut state = 20.0_f64;
    let mut maximum_state = state;
    let mut cumulative_cost = 0.0_f64;

    for time in 1..=60 {
        state = state + growth * state - policy_drag * state;

        if time == shock_time {
            state = (state - external_shock / resilience_buffer.max(1.0)).max(0.0);
        }

        let policy_cost = 4.0 * policy_drag + 0.08 * resilience_buffer;
        let stress_cost = 0.03 * (state - 35.0).max(0.0).powi(2);
        cumulative_cost += policy_cost + stress_cost;
        maximum_state = maximum_state.max(state);
    }

    let score = resilience_score(state, maximum_state, cumulative_cost);
    (state, maximum_state, cumulative_cost, score)
}

fn main() -> std::io::Result<()> {
    let policies = vec![
        Policy { name: "Policy_A_low_intervention", policy_drag: 0.010, resilience_buffer: 4.0 },
        Policy { name: "Policy_B_moderate_intervention", policy_drag: 0.025, resilience_buffer: 7.0 },
        Policy { name: "Policy_C_high_resilience", policy_drag: 0.020, resilience_buffer: 12.0 },
    ];

    let mut seed = 4242_u64;

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_scenario_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario_id,policy,growth,external_shock,shock_time,final_state,maximum_state,cumulative_cost,resilience_score")?;

    for scenario_id in 1..=300 {
        let growth = 0.030 + lcg(&mut seed) * 0.045;
        let external_shock = lcg(&mut seed) * 18.0;
        let shock_time = 20 + (lcg(&mut seed) * 26.0).floor() as usize;

        for policy in &policies {
            let (final_state, maximum_state, cumulative_cost, score) =
                simulate_policy(growth, policy.policy_drag, external_shock, shock_time, policy.resilience_buffer);

            writeln!(
                writer,
                "{},{},{:.6},{:.6},{},{:.6},{:.6},{:.6},{:.6}",
                scenario_id,
                policy.name,
                growth,
                external_shock,
                shock_time,
                final_state,
                maximum_state,
                cumulative_cost,
                score
            )?;
        }
    }

    println!("Rust scenario diagnostics complete.");
    println!("outputs/tables/rust_scenario_diagnostics.csv");

    Ok(())
}
