use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

#[derive(Clone)]
struct Scenario {
    name: &'static str,
    demand_growth: f64,
    capacity_growth: f64,
    rework_rate: f64,
    trust_loss_from_backlog: f64,
    trust_gain_from_service: f64,
    intervention_pressure: f64,
    systems_redesign_strength: f64,
    delay_factor: f64,
    uncertainty_humility: f64,
}

fn clamp(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn simulate(s: &Scenario) -> (f64, f64, f64, f64, f64) {
    let mut demand = 80.0;
    let mut capacity = 70.0;
    let mut backlog = 22.0;
    let mut trust = 58.0;
    let mut rework = 8.0;
    let mut learning = 22.0;

    let mut final_conceptual_score = 0.0;
    let mut final_modeled_score = 0.0;
    let mut max_backlog = backlog;
    let mut min_trust = trust;

    for _period in 0..=80 {
        let service_gap = (demand + backlog - capacity).max(0.0);
        let service_quality = clamp(100.0 - service_gap * 0.50 - rework * 0.35, 0.0, 100.0);

        let conceptual_score = clamp(
            50.0 + s.systems_redesign_strength * 24.0 + s.uncertainty_humility * 14.0 -
            s.intervention_pressure * 8.0 - service_gap * 0.08,
            0.0,
            100.0
        );

        let modeled_score = clamp(
            service_quality * 0.30 + trust * 0.25 + learning * 0.20 + capacity * 0.10 -
            backlog * 0.10 - rework * 0.15,
            0.0,
            100.0
        );

        final_conceptual_score = conceptual_score;
        final_modeled_score = modeled_score;
        max_backlog = f64::max(max_backlog, backlog);
        min_trust = f64::min(min_trust, trust);

        let pressure_gain = s.intervention_pressure * 4.0;
        let redesign_gain = s.systems_redesign_strength * 3.2;
        let delayed_learning_effect = learning * 0.03 * (1.0 - s.delay_factor);

        demand += s.demand_growth * demand;
        capacity += s.capacity_growth * capacity + redesign_gain + delayed_learning_effect - rework * 0.015;
        backlog += demand * 0.10 + rework * 0.30 - capacity * 0.09 - redesign_gain * 0.80;
        rework += service_gap * s.rework_rate + pressure_gain * 0.15 - redesign_gain * 0.45;
        trust += -backlog * s.trust_loss_from_backlog + service_quality * s.trust_gain_from_service + redesign_gain * 0.10;
        learning += s.uncertainty_humility * 1.3 + s.systems_redesign_strength * 1.1 - s.intervention_pressure * 0.45;

        demand = clamp(demand, 0.0, 200.0);
        capacity = clamp(capacity, 0.0, 200.0);
        backlog = clamp(backlog, 0.0, 200.0);
        trust = clamp(trust, 0.0, 100.0);
        rework = clamp(rework, 0.0, 120.0);
        learning = clamp(learning, 0.0, 100.0);
    }

    (
        final_conceptual_score,
        final_modeled_score,
        final_conceptual_score - final_modeled_score,
        max_backlog,
        min_trust,
    )
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "linear_pressure_frame", demand_growth: 0.018, capacity_growth: 0.006, rework_rate: 0.025, trust_loss_from_backlog: 0.010, trust_gain_from_service: 0.004, intervention_pressure: 0.82, systems_redesign_strength: 0.12, delay_factor: 0.70, uncertainty_humility: 0.18 },
        Scenario { name: "conceptual_systems_frame", demand_growth: 0.018, capacity_growth: 0.010, rework_rate: 0.018, trust_loss_from_backlog: 0.007, trust_gain_from_service: 0.006, intervention_pressure: 0.48, systems_redesign_strength: 0.54, delay_factor: 0.45, uncertainty_humility: 0.55 },
        Scenario { name: "formal_model_learning_frame", demand_growth: 0.018, capacity_growth: 0.014, rework_rate: 0.012, trust_loss_from_backlog: 0.005, trust_gain_from_service: 0.008, intervention_pressure: 0.28, systems_redesign_strength: 0.78, delay_factor: 0.25, uncertainty_humility: 0.82 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_systems_modeling_gap_cli.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,final_conceptual_score,final_modeled_score,conceptual_model_gap,maximum_backlog,minimum_trust")?;

    for scenario in &scenarios {
        let (conceptual, modeled, gap, max_backlog, min_trust) = simulate(scenario);
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6}",
            scenario.name, conceptual, modeled, gap, max_backlog, min_trust
        )?;
    }

    println!("Rust systems modeling gap CLI complete.");
    println!("outputs/tables/rust_systems_modeling_gap_cli.csv");

    Ok(())
}
