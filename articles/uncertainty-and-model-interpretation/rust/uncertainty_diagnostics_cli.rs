use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Policy {
    name: &'static str,
    policy_strength: f64,
    adaptive_capacity: f64,
}

fn lcg(seed: &mut u64) -> f64 {
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    ((*seed >> 33) as f64) / ((1u64 << 31) as f64)
}

fn simulate_policy(growth: f64, shock_intensity: f64, shock_timing: usize, policy_strength: f64, adaptive_capacity: f64) -> (f64, f64, f64, f64) {
    let mut state = 20.0_f64;
    let mut maximum_state = state;
    let mut cumulative_stress = 0.0_f64;

    for time in 1..=60 {
        let shock_wave = if time == shock_timing { shock_intensity } else { 0.0 };
        let adaptation_effect = adaptive_capacity * (state - 35.0).max(0.0);

        state = state + growth * state - policy_strength * state - adaptation_effect - shock_wave;
        state = state.max(0.0);
        maximum_state = maximum_state.max(state);
        cumulative_stress += (state - 40.0).max(0.0);
    }

    let score = (100.0 - 0.60 * state - 0.25 * maximum_state - 0.10 * cumulative_stress)
        .max(0.0)
        .min(100.0);

    (state, maximum_state, cumulative_stress, score)
}

fn main() -> std::io::Result<()> {
    let policies = vec![
        Policy { name: "Policy_A_low_control", policy_strength: 0.025, adaptive_capacity: 0.010 },
        Policy { name: "Policy_B_balanced", policy_strength: 0.045, adaptive_capacity: 0.020 },
        Policy { name: "Policy_C_high_adaptation", policy_strength: 0.035, adaptive_capacity: 0.045 },
        Policy { name: "Policy_D_precautionary", policy_strength: 0.055, adaptive_capacity: 0.040 },
    ];

    let mut seed = 42_u64;

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_uncertainty_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario_id,policy,growth,shock_intensity,shock_timing,final_state,maximum_state,cumulative_stress,resilience_score")?;

    for scenario_id in 1..=500 {
        let growth = 0.035 + lcg(&mut seed) * (0.095 - 0.035);
        let shock_intensity = lcg(&mut seed) * 24.0;
        let shock_timing = 20 + (lcg(&mut seed) * 26.0).floor() as usize;

        for policy in &policies {
            let (final_state, maximum_state, cumulative_stress, score) =
                simulate_policy(growth, shock_intensity, shock_timing, policy.policy_strength, policy.adaptive_capacity);

            writeln!(
                writer,
                "{},{},{:.6},{:.6},{},{:.6},{:.6},{:.6},{:.6}",
                scenario_id,
                policy.name,
                growth,
                shock_intensity,
                shock_timing,
                final_state,
                maximum_state,
                cumulative_stress,
                score
            )?;
        }
    }

    println!("Rust uncertainty diagnostics complete.");
    println!("outputs/tables/rust_uncertainty_diagnostics.csv");

    Ok(())
}
