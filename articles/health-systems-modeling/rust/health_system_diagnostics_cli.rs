use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    initial_capacity: f64,
    initial_demand: f64,
    initial_trust: f64,
    demand_growth: f64,
    prevention_effect: f64,
    workforce_recovery: f64,
    burnout_sensitivity: f64,
    attrition_sensitivity: f64,
    hiring_rate: f64,
    access_barrier: f64,
    trust_loss_rate: f64,
    trust_gain_rate: f64,
    surge_start: usize,
    surge_end: usize,
    surge_intensity: f64,
}

struct Summary {
    scenario: &'static str,
    final_capacity: f64,
    final_backlog: f64,
    final_trust: f64,
    maximum_pressure: f64,
    maximum_burnout: f64,
    total_unmet_need: f64,
    average_access_gap: f64,
    minimum_trust: f64,
}

fn bounded(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn deterministic_noise(step: usize) -> f64 {
    (step as f64 * 1.61803398875).sin() * 0.004
}

fn simulate(s: &Scenario) -> Summary {
    let mut capacity = s.initial_capacity;
    let mut demand = s.initial_demand;
    let mut trust = s.initial_trust;
    let mut backlog = 0.0_f64;
    let mut burnout = 0.12_f64;

    let mut maximum_pressure = 0.0_f64;
    let mut maximum_burnout = burnout;
    let mut total_unmet_need = 0.0_f64;
    let mut total_access_gap = 0.0_f64;
    let mut minimum_trust = trust;

    for step in 0..s.steps {
        let pressure = demand / capacity.max(1.0);
        let slack = (1.0 - pressure).max(0.0);
        burnout = (burnout + s.burnout_sensitivity * (pressure - 1.0).max(0.0) - s.workforce_recovery * slack).max(0.0);
        let attrition = s.attrition_sensitivity * burnout * capacity;
        let surge = if step >= s.surge_start && step <= s.surge_end { s.surge_intensity } else { 0.0 };
        let effective_capacity = (capacity + s.hiring_rate - attrition - 0.10 * (pressure - 1.0).max(0.0) * capacity).max(0.0);
        let served = demand.min(effective_capacity);
        let unmet_need = (demand - served).max(0.0);
        let access_gap = s.access_barrier * demand + unmet_need;
        backlog = (backlog + demand - served).max(0.0);

        trust = bounded(
            trust + s.trust_gain_rate * slack - s.trust_loss_rate * (pressure - 1.0).max(0.0) - 0.004 * access_gap / demand.max(1.0) + deterministic_noise(step),
            0.0,
            1.0,
        );

        maximum_pressure = maximum_pressure.max(pressure);
        maximum_burnout = maximum_burnout.max(burnout);
        total_unmet_need += unmet_need;
        total_access_gap += access_gap;
        minimum_trust = minimum_trust.min(trust);

        capacity = effective_capacity;
        let prevention_reduction = s.prevention_effect * (step as f64 + 1.0);
        demand = (s.initial_demand + s.demand_growth * (step as f64 + 1.0) + surge - prevention_reduction + 0.08 * backlog).max(0.0);
    }

    Summary {
        scenario: s.name,
        final_capacity: capacity,
        final_backlog: backlog,
        final_trust: trust,
        maximum_pressure,
        maximum_burnout,
        total_unmet_need,
        average_access_gap: total_access_gap / s.steps as f64,
        minimum_trust,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_health_system", steps: 120, initial_capacity: 100.0, initial_demand: 92.0, initial_trust: 0.64, demand_growth: 0.35, prevention_effect: 0.015, workforce_recovery: 0.035, burnout_sensitivity: 0.085, attrition_sensitivity: 0.030, hiring_rate: 0.50, access_barrier: 0.18, trust_loss_rate: 0.020, trust_gain_rate: 0.012, surge_start: 45, surge_end: 65, surge_intensity: 18.0 },
        Scenario { name: "higher_demand_growth", steps: 120, initial_capacity: 100.0, initial_demand: 92.0, initial_trust: 0.64, demand_growth: 0.65, prevention_effect: 0.015, workforce_recovery: 0.035, burnout_sensitivity: 0.085, attrition_sensitivity: 0.030, hiring_rate: 0.50, access_barrier: 0.18, trust_loss_rate: 0.020, trust_gain_rate: 0.012, surge_start: 45, surge_end: 65, surge_intensity: 18.0 },
        Scenario { name: "stronger_prevention", steps: 120, initial_capacity: 100.0, initial_demand: 92.0, initial_trust: 0.70, demand_growth: 0.35, prevention_effect: 0.060, workforce_recovery: 0.035, burnout_sensitivity: 0.085, attrition_sensitivity: 0.030, hiring_rate: 0.50, access_barrier: 0.16, trust_loss_rate: 0.018, trust_gain_rate: 0.018, surge_start: 45, surge_end: 65, surge_intensity: 18.0 },
        Scenario { name: "larger_surge", steps: 120, initial_capacity: 100.0, initial_demand: 92.0, initial_trust: 0.64, demand_growth: 0.35, prevention_effect: 0.015, workforce_recovery: 0.035, burnout_sensitivity: 0.085, attrition_sensitivity: 0.030, hiring_rate: 0.50, access_barrier: 0.18, trust_loss_rate: 0.020, trust_gain_rate: 0.012, surge_start: 45, surge_end: 65, surge_intensity: 32.0 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_health_system_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_capacity,final_backlog,final_trust,maximum_pressure,maximum_burnout,total_unmet_need,average_access_gap,minimum_trust,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.maximum_pressure > 1.25 || result.total_unmet_need > 1000.0 || result.minimum_trust < 0.35 {
            "high strain health system pathway"
        } else {
            "manageable health system pathway"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.final_capacity,
            result.final_backlog,
            result.final_trust,
            result.maximum_pressure,
            result.maximum_burnout,
            result.total_unmet_need,
            result.average_access_gap,
            result.minimum_trust,
            label
        )?;
    }

    println!("Rust health system diagnostics complete.");
    println!("outputs/tables/rust_health_system_summary.csv");

    Ok(())
}
