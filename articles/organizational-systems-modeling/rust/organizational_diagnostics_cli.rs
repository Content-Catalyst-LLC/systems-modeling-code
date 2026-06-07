use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    initial_capacity: f64,
    initial_workload: f64,
    initial_trust: f64,
    demand_growth: f64,
    hiring_rate: f64,
    learning_rate: f64,
    burnout_sensitivity: f64,
    recovery_rate: f64,
    attrition_sensitivity: f64,
    coordination_burden_rate: f64,
    trust_loss_rate: f64,
    trust_gain_rate: f64,
}

struct Summary {
    scenario: &'static str,
    final_capacity: f64,
    final_workload: f64,
    final_backlog: f64,
    final_trust: f64,
    maximum_pressure: f64,
    maximum_burnout: f64,
    total_attrition: f64,
    average_delivery: f64,
    minimum_trust: f64,
}

fn bounded(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn deterministic_noise(step: usize) -> f64 {
    (step as f64 * 1.61803398875).sin() * 0.005
}

fn simulate(s: &Scenario) -> Summary {
    let mut capacity = s.initial_capacity;
    let mut workload = s.initial_workload;
    let mut trust = s.initial_trust;
    let mut backlog = 0.0_f64;
    let mut burnout = 0.10_f64;

    let mut maximum_pressure = 0.0_f64;
    let mut maximum_burnout = burnout;
    let mut total_attrition = 0.0_f64;
    let mut total_delivery = 0.0_f64;
    let mut minimum_trust = trust;

    for step in 0..s.steps {
        let pressure = workload / capacity.max(1.0);
        let slack = (1.0 - pressure).max(0.0);
        let learning = s.learning_rate * capacity * slack * trust;
        let coordination_burden = s.coordination_burden_rate * (pressure - 1.0).max(0.0) * capacity;

        burnout = (burnout + s.burnout_sensitivity * (pressure - 1.0).max(0.0) - s.recovery_rate * slack).max(0.0);
        let attrition = s.attrition_sensitivity * burnout * capacity;
        let effective_capacity = (capacity + s.hiring_rate + learning - attrition - coordination_burden).max(0.0);
        let delivery = workload.min(effective_capacity);
        backlog = (backlog + workload - delivery).max(0.0);

        trust = bounded(
            trust + s.trust_gain_rate * slack - s.trust_loss_rate * (pressure - 1.0).max(0.0) - 0.005 * burnout + deterministic_noise(step),
            0.0,
            1.0,
        );

        maximum_pressure = maximum_pressure.max(pressure);
        maximum_burnout = maximum_burnout.max(burnout);
        total_attrition += attrition;
        total_delivery += delivery;
        minimum_trust = minimum_trust.min(trust);

        capacity = effective_capacity;
        workload = s.initial_workload + s.demand_growth * (step as f64 + 1.0) + 0.10 * backlog;
    }

    Summary {
        scenario: s.name,
        final_capacity: capacity,
        final_workload: workload,
        final_backlog: backlog,
        final_trust: trust,
        maximum_pressure,
        maximum_burnout,
        total_attrition,
        average_delivery: total_delivery / s.steps as f64,
        minimum_trust,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_organization", steps: 100, initial_capacity: 100.0, initial_workload: 95.0, initial_trust: 0.62, demand_growth: 0.45, hiring_rate: 0.65, learning_rate: 0.035, burnout_sensitivity: 0.090, recovery_rate: 0.040, attrition_sensitivity: 0.035, coordination_burden_rate: 0.10, trust_loss_rate: 0.030, trust_gain_rate: 0.010 },
        Scenario { name: "high_demand_growth", steps: 100, initial_capacity: 100.0, initial_workload: 95.0, initial_trust: 0.62, demand_growth: 0.85, hiring_rate: 0.65, learning_rate: 0.035, burnout_sensitivity: 0.090, recovery_rate: 0.040, attrition_sensitivity: 0.035, coordination_burden_rate: 0.10, trust_loss_rate: 0.030, trust_gain_rate: 0.010 },
        Scenario { name: "faster_hiring", steps: 100, initial_capacity: 100.0, initial_workload: 95.0, initial_trust: 0.62, demand_growth: 0.45, hiring_rate: 1.25, learning_rate: 0.035, burnout_sensitivity: 0.090, recovery_rate: 0.040, attrition_sensitivity: 0.035, coordination_burden_rate: 0.10, trust_loss_rate: 0.030, trust_gain_rate: 0.010 },
        Scenario { name: "high_coordination_burden", steps: 100, initial_capacity: 100.0, initial_workload: 95.0, initial_trust: 0.62, demand_growth: 0.45, hiring_rate: 0.65, learning_rate: 0.035, burnout_sensitivity: 0.090, recovery_rate: 0.040, attrition_sensitivity: 0.035, coordination_burden_rate: 0.22, trust_loss_rate: 0.030, trust_gain_rate: 0.010 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_organizational_system_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_capacity,final_workload,final_backlog,final_trust,maximum_pressure,maximum_burnout,total_attrition,average_delivery,minimum_trust,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.maximum_pressure > 1.25 || result.maximum_burnout > 0.60 || result.minimum_trust < 0.30 {
            "unsustainable operating pathway"
        } else {
            "manageable operating pathway"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.final_capacity,
            result.final_workload,
            result.final_backlog,
            result.final_trust,
            result.maximum_pressure,
            result.maximum_burnout,
            result.total_attrition,
            result.average_delivery,
            result.minimum_trust,
            label
        )?;
    }

    println!("Rust organizational diagnostics complete.");
    println!("outputs/tables/rust_organizational_system_summary.csv");

    Ok(())
}
