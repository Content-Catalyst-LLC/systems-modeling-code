use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    delay: usize,
    correction_strength: f64,
    counterresponse_strength: f64,
    perception_smoothing: f64,
}

struct Summary {
    scenario: &'static str,
    initial_state: f64,
    final_state: f64,
    minimum_state: f64,
    maximum_state: f64,
    target_crossings: usize,
    maximum_overshoot: f64,
    mean_absolute_target_gap: f64,
    cumulative_intervention: f64,
    cumulative_counterresponse: f64,
    resistance_ratio: f64,
}

fn target_crossings(values: &[f64], target: f64) -> usize {
    let mut crossings = 0_usize;

    for i in 1..values.len() {
        let left_gap = values[i - 1] - target;
        let right_gap = values[i] - target;

        if left_gap == 0.0 || right_gap == 0.0 {
            continue;
        }

        if (left_gap < 0.0 && right_gap > 0.0) || (left_gap > 0.0 && right_gap < 0.0) {
            crossings += 1;
        }
    }

    crossings
}

fn simulate(s: &Scenario, steps: usize) -> Summary {
    let target = 50.0_f64;
    let mut state = vec![0.0_f64; steps];
    let mut perceived = vec![0.0_f64; steps];
    let mut intervention = vec![0.0_f64; steps];
    let mut counterresponse = vec![0.0_f64; steps];

    state[0] = 80.0;
    perceived[0] = 80.0;

    for t in 1..steps {
        perceived[t] = s.perception_smoothing * state[t - 1] + (1.0 - s.perception_smoothing) * perceived[t - 1];

        let observed_index = if t >= s.delay { t - s.delay } else { 0 };
        let observed_gap = perceived[observed_index] - target;

        let action = s.correction_strength * observed_gap.max(0.0);
        let response = s.counterresponse_strength * action;
        let natural_pressure = 2.0 + 0.025 * state[t - 1];

        intervention[t] = action;
        counterresponse[t] = response;
        state[t] = (state[t - 1] + natural_pressure + response - action).max(0.0);
    }

    let mut minimum_state = state[0];
    let mut maximum_state = state[0];
    let mut gap_total = 0.0_f64;
    let mut cumulative_intervention = 0.0_f64;
    let mut cumulative_counterresponse = 0.0_f64;

    for i in 0..steps {
        minimum_state = minimum_state.min(state[i]);
        maximum_state = maximum_state.max(state[i]);
        gap_total += (state[i] - target).abs();
        cumulative_intervention += intervention[i];
        cumulative_counterresponse += counterresponse[i];
    }

    let resistance_ratio = if cumulative_intervention > 0.0 {
        cumulative_counterresponse / cumulative_intervention
    } else {
        0.0
    };

    Summary {
        scenario: s.name,
        initial_state: state[0],
        final_state: state[steps - 1],
        minimum_state,
        maximum_state,
        target_crossings: target_crossings(&state, target),
        maximum_overshoot: (maximum_state - target).max(0.0),
        mean_absolute_target_gap: gap_total / steps as f64,
        cumulative_intervention,
        cumulative_counterresponse,
        resistance_ratio,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "timely_moderate_response", delay: 1, correction_strength: 0.18, counterresponse_strength: 0.00, perception_smoothing: 0.75 },
        Scenario { name: "delayed_response", delay: 6, correction_strength: 0.18, counterresponse_strength: 0.00, perception_smoothing: 0.55 },
        Scenario { name: "overcorrection", delay: 6, correction_strength: 0.34, counterresponse_strength: 0.00, perception_smoothing: 0.55 },
        Scenario { name: "undercorrection", delay: 6, correction_strength: 0.09, counterresponse_strength: 0.00, perception_smoothing: 0.55 },
        Scenario { name: "policy_resistance", delay: 6, correction_strength: 0.24, counterresponse_strength: 0.42, perception_smoothing: 0.55 },
        Scenario { name: "slow_recognition_high_resistance", delay: 10, correction_strength: 0.24, counterresponse_strength: 0.55, perception_smoothing: 0.35 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_delay_oscillation_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,initial_state,final_state,minimum_state,maximum_state,target_crossings,maximum_overshoot_above_target,mean_absolute_target_gap,cumulative_intervention,cumulative_counterresponse,resistance_ratio"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario, 100);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{},{:.6},{:.6},{:.6},{:.6},{:.6}",
            result.scenario,
            result.initial_state,
            result.final_state,
            result.minimum_state,
            result.maximum_state,
            result.target_crossings,
            result.maximum_overshoot,
            result.mean_absolute_target_gap,
            result.cumulative_intervention,
            result.cumulative_counterresponse,
            result.resistance_ratio
        )?;
    }

    println!("Rust delay-policy diagnostics complete.");
    println!("outputs/tables/rust_delay_oscillation_summary.csv");

    Ok(())
}
