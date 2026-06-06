use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    feedback_gain: f64,
    external_correction: f64,
    information_delay: usize,
    information_quality: f64,
    buffer_capacity: f64,
    rule_threshold: f64,
    rule_feedback_gain: f64,
    self_organization_rate: f64,
    goal_weight_resilience: f64,
    implementation_delay: usize,
    has_rule: bool,
}

struct ResultRow {
    initial_state: f64,
    final_state: f64,
    maximum_state: f64,
    mean_pressure: f64,
    final_resilience: f64,
    final_learning_capacity: f64,
    cumulative_intervention: f64,
}

fn simulate(s: &Scenario, steps: usize) -> ResultRow {
    let mut state = vec![0.0_f64; steps];
    let mut pressure = vec![0.0_f64; steps];
    let mut resilience = vec![0.0_f64; steps];
    let mut learning = vec![0.0_f64; steps];
    let mut intervention = vec![0.0_f64; steps];
    let mut buffer_remaining = vec![0.0_f64; steps];

    state[0] = 70.0;
    pressure[0] = 50.0;
    resilience[0] = 30.0;
    buffer_remaining[0] = s.buffer_capacity;

    for t in 1..steps {
        let observed_index = if t >= s.information_delay { t - s.information_delay } else { 0 };
        let delayed_signal = state[observed_index];
        let current_signal = state[t - 1];
        let observed_state = s.information_quality * current_signal + (1.0 - s.information_quality) * delayed_signal;

        let mut current_gain = s.feedback_gain;
        if s.has_rule && observed_state > s.rule_threshold {
            current_gain = s.rule_feedback_gain;
        }

        learning[t] = (learning[t - 1] + s.self_organization_rate * (100.0 - learning[t - 1]) / 8.0).min(100.0);

        let resilience_gap = (100.0 - resilience[t - 1]).max(0.0);
        let resilience_investment = s.goal_weight_resilience * resilience_gap;

        let buffer_absorption = buffer_remaining[t - 1].min(0.10 * pressure[t - 1]);
        buffer_remaining[t] = (buffer_remaining[t - 1] - buffer_absorption + 0.02 * s.buffer_capacity).max(0.0);

        let mut correction = 0.0;
        if t + 1 >= s.implementation_delay {
            correction = s.external_correction
                + 0.05 * (observed_state - 40.0).max(0.0)
                + resilience_investment
                + 0.04 * learning[t];
        }

        intervention[t] = correction;

        pressure[t] = (0.91 * pressure[t - 1]
            + 0.07 * state[t - 1]
            - 0.30 * correction
            - 0.08 * buffer_absorption
            - 0.04 * resilience[t - 1])
            .max(0.0);

        resilience[t] = (resilience[t - 1]
            + 0.18 * resilience_investment
            + 0.05 * learning[t]
            - 0.025 * pressure[t - 1])
            .max(0.0)
            .min(100.0);

        state[t] = (current_gain * state[t - 1]
            + 0.24 * pressure[t]
            - 0.34 * correction
            - 0.08 * buffer_absorption
            - 0.045 * resilience[t])
            .max(0.0);
    }

    let mut maximum_state = state[0];
    let mut mean_pressure = 0.0;
    let mut cumulative_intervention = 0.0;

    for i in 0..steps {
        maximum_state = maximum_state.max(state[i]);
        mean_pressure += pressure[i];
        cumulative_intervention += intervention[i];
    }

    mean_pressure /= steps as f64;

    ResultRow {
        initial_state: state[0],
        final_state: state[steps - 1],
        maximum_state,
        mean_pressure,
        final_resilience: resilience[steps - 1],
        final_learning_capacity: learning[steps - 1],
        cumulative_intervention,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline", feedback_gain: 0.96, external_correction: 2.0, information_delay: 6, information_quality: 0.70, buffer_capacity: 0.0, rule_threshold: 0.0, rule_feedback_gain: 0.96, self_organization_rate: 0.00, goal_weight_resilience: 0.00, implementation_delay: 1, has_rule: false },
        Scenario { name: "parameter_intervention", feedback_gain: 0.96, external_correction: 5.0, information_delay: 6, information_quality: 0.70, buffer_capacity: 0.0, rule_threshold: 0.0, rule_feedback_gain: 0.96, self_organization_rate: 0.00, goal_weight_resilience: 0.00, implementation_delay: 1, has_rule: false },
        Scenario { name: "feedback_intervention", feedback_gain: 0.78, external_correction: 2.0, information_delay: 6, information_quality: 0.70, buffer_capacity: 0.0, rule_threshold: 0.0, rule_feedback_gain: 0.78, self_organization_rate: 0.00, goal_weight_resilience: 0.00, implementation_delay: 1, has_rule: false },
        Scenario { name: "rule_intervention", feedback_gain: 0.96, external_correction: 2.0, information_delay: 2, information_quality: 0.85, buffer_capacity: 0.0, rule_threshold: 45.0, rule_feedback_gain: 0.70, self_organization_rate: 0.00, goal_weight_resilience: 0.00, implementation_delay: 1, has_rule: true },
        Scenario { name: "goal_intervention", feedback_gain: 0.90, external_correction: 2.0, information_delay: 2, information_quality: 0.90, buffer_capacity: 10.0, rule_threshold: 45.0, rule_feedback_gain: 0.72, self_organization_rate: 0.12, goal_weight_resilience: 0.10, implementation_delay: 1, has_rule: true },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_leverage_intervention_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,initial_state,final_state,maximum_state,mean_pressure,final_resilience,final_learning_capacity,cumulative_intervention,behavior_change_from_baseline,leverage_ratio"
    )?;

    let mut results: Vec<(&str, ResultRow)> = Vec::new();

    for scenario in &scenarios {
        results.push((scenario.name, simulate(scenario, 96)));
    }

    let baseline_final = results.iter().find(|(name, _)| *name == "baseline").unwrap().1.final_state;

    for (name, result) in results {
        let behavior_change = baseline_final - result.final_state;
        let leverage_ratio = if result.cumulative_intervention > 0.0 {
            behavior_change / result.cumulative_intervention
        } else {
            0.0
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6}",
            name,
            result.initial_state,
            result.final_state,
            result.maximum_state,
            result.mean_pressure,
            result.final_resilience,
            result.final_learning_capacity,
            result.cumulative_intervention,
            behavior_change,
            leverage_ratio
        )?;
    }

    println!("Rust leverage diagnostics complete.");
    println!("outputs/tables/rust_leverage_intervention_summary.csv");

    Ok(())
}
