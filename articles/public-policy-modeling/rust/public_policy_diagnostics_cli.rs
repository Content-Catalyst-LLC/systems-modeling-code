use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    target_state: f64,
    system_state: f64,
    institutional_capacity: f64,
    trust: f64,
    administrative_burden: f64,
    policy_intensity: f64,
    max_policy: f64,
    min_policy: f64,
    policy_increase_rate: f64,
    policy_decrease_rate: f64,
    policy_effect: f64,
    capacity_learning_rate: f64,
    burden_growth: f64,
    burden_relief: f64,
    side_effect_rate: f64,
}

struct Summary {
    scenario: &'static str,
    final_system_state: f64,
    final_policy_intensity: f64,
    final_capacity: f64,
    final_trust: f64,
    maximum_burden: f64,
    maximum_side_effect: f64,
    average_uptake: f64,
    average_policy_intensity: f64,
}

fn bounded(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn deterministic_noise(step: usize) -> f64 {
    (step as f64 * 1.61803398875).sin() * 0.12
}

fn simulate(s: &Scenario) -> Summary {
    let mut system_state = s.system_state;
    let mut capacity = s.institutional_capacity;
    let mut trust = s.trust;
    let mut burden = s.administrative_burden;
    let mut policy = s.policy_intensity;
    let mut side_effect = 0.0_f64;

    let mut maximum_burden = burden;
    let mut maximum_side_effect = side_effect;
    let mut total_uptake = 0.0_f64;
    let mut total_policy = 0.0_f64;

    for step in 0..s.steps {
        let uptake = bounded(0.42 + 0.30 * trust + 0.035 * capacity - 0.45 * burden, 0.0, 1.0);
        let gap = s.target_state - system_state;

        if gap > 0.0 {
            policy = (policy + s.policy_increase_rate).min(s.max_policy);
        } else {
            policy = (policy - s.policy_decrease_rate).max(s.min_policy);
        }

        let next_state = system_state
            + s.policy_effect * policy * uptake
            - 0.12 * system_state
            + 0.05 * capacity
            + deterministic_noise(step);

        let next_capacity = capacity + s.capacity_learning_rate * (system_state - capacity);
        let next_burden = (burden + s.burden_growth * policy - s.burden_relief * capacity).max(0.0);
        let next_side_effect = (side_effect + s.side_effect_rate * policy - 0.06 * side_effect).max(0.0);
        let next_trust = bounded(trust + 0.015 * uptake - 0.018 * next_burden - 0.010 * next_side_effect, 0.0, 1.0);

        maximum_burden = maximum_burden.max(burden);
        maximum_side_effect = maximum_side_effect.max(side_effect);
        total_uptake += uptake;
        total_policy += policy;

        system_state = next_state.max(0.0);
        capacity = next_capacity.max(0.0);
        burden = next_burden;
        side_effect = next_side_effect;
        trust = next_trust;
    }

    Summary {
        scenario: s.name,
        final_system_state: system_state,
        final_policy_intensity: policy,
        final_capacity: capacity,
        final_trust: trust,
        maximum_burden,
        maximum_side_effect,
        average_uptake: total_uptake / s.steps as f64,
        average_policy_intensity: total_policy / s.steps as f64,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_adaptive_policy", steps: 100, target_state: 16.0, system_state: 12.0, institutional_capacity: 7.0, trust: 0.58, administrative_burden: 0.25, policy_intensity: 1.0, max_policy: 2.0, min_policy: 0.25, policy_increase_rate: 0.08, policy_decrease_rate: 0.05, policy_effect: 0.55, capacity_learning_rate: 0.09, burden_growth: 0.05, burden_relief: 0.025, side_effect_rate: 0.08 },
        Scenario { name: "aggressive_policy_rule", steps: 100, target_state: 16.0, system_state: 12.0, institutional_capacity: 7.0, trust: 0.58, administrative_burden: 0.25, policy_intensity: 1.0, max_policy: 2.4, min_policy: 0.25, policy_increase_rate: 0.14, policy_decrease_rate: 0.05, policy_effect: 0.55, capacity_learning_rate: 0.09, burden_growth: 0.05, burden_relief: 0.025, side_effect_rate: 0.08 },
        Scenario { name: "low_capacity_learning", steps: 100, target_state: 16.0, system_state: 12.0, institutional_capacity: 7.0, trust: 0.58, administrative_burden: 0.25, policy_intensity: 1.0, max_policy: 2.0, min_policy: 0.25, policy_increase_rate: 0.08, policy_decrease_rate: 0.05, policy_effect: 0.55, capacity_learning_rate: 0.035, burden_growth: 0.05, burden_relief: 0.025, side_effect_rate: 0.08 },
        Scenario { name: "high_burden_design", steps: 100, target_state: 16.0, system_state: 12.0, institutional_capacity: 7.0, trust: 0.58, administrative_burden: 0.25, policy_intensity: 1.0, max_policy: 2.0, min_policy: 0.25, policy_increase_rate: 0.08, policy_decrease_rate: 0.05, policy_effect: 0.55, capacity_learning_rate: 0.09, burden_growth: 0.10, burden_relief: 0.025, side_effect_rate: 0.08 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_public_policy_adaptive_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_system_state,final_policy_intensity,final_capacity,final_trust,maximum_burden,maximum_side_effect,average_uptake,average_policy_intensity,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.maximum_burden > 1.0 || result.maximum_side_effect > 1.0 {
            "high burden policy pathway"
        } else {
            "manageable policy pathway"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.final_system_state,
            result.final_policy_intensity,
            result.final_capacity,
            result.final_trust,
            result.maximum_burden,
            result.maximum_side_effect,
            result.average_uptake,
            result.average_policy_intensity,
            label
        )?;
    }

    println!("Rust public policy diagnostics complete.");
    println!("outputs/tables/rust_public_policy_adaptive_summary.csv");

    Ok(())
}
