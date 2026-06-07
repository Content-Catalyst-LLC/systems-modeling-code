use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    population: f64,
    housing: f64,
    transport: f64,
    service_capacity: f64,
    growth_pressure: f64,
    accessibility_attraction: f64,
    congestion_penalty: f64,
    housing_constraint_penalty: f64,
    housing_build_rate: f64,
    transport_investment_rate: f64,
    service_investment_rate: f64,
    periodic_policy_investment: f64,
    policy_interval: usize,
    pressure_penalty: f64,
}

struct Summary {
    scenario: &'static str,
    final_population: f64,
    final_housing: f64,
    final_transport: f64,
    final_service_capacity: f64,
    final_accessibility: f64,
    maximum_service_pressure: f64,
    maximum_housing_gap: f64,
}

fn deterministic_noise(step: usize) -> f64 {
    (step as f64 * 1.61803398875).sin() * 0.10
}

fn simulate(s: &Scenario) -> Summary {
    let mut population = s.population;
    let mut housing = s.housing;
    let mut transport = s.transport;
    let mut service_capacity = s.service_capacity;

    let mut maximum_service_pressure = 0.0_f64;
    let mut maximum_housing_gap = 0.0_f64;
    let mut final_accessibility = 0.0_f64;

    for step in 1..=s.steps {
        let accessibility = transport / (1.0 + 0.010 * population);
        let congestion = population / transport.max(1.0);
        let housing_gap = (population - housing).max(0.0);
        let service_pressure = population / service_capacity.max(1.0);

        maximum_service_pressure = maximum_service_pressure.max(service_pressure);
        maximum_housing_gap = maximum_housing_gap.max(housing_gap);
        final_accessibility = accessibility;

        let policy_investment = if step % s.policy_interval == 0 {
            s.periodic_policy_investment
        } else {
            0.0
        };

        let pressure_drag = s.pressure_penalty * (service_pressure - 1.0).max(0.0);
        let congestion_drag = s.congestion_penalty * (congestion - 1.0).max(0.0);
        let housing_drag = s.housing_constraint_penalty * housing_gap / 20.0;

        let population_change = s.growth_pressure
            + s.accessibility_attraction * accessibility / 55.0
            - congestion_drag
            - housing_drag
            - pressure_drag
            + deterministic_noise(step);

        population = (population + population_change).max(0.0);
        housing = (housing + s.housing_build_rate + 0.020 * population - 0.004 * housing).max(0.0);
        transport = (transport + s.transport_investment_rate + 0.010 * housing - 0.030 * (congestion - 1.0).max(0.0)).max(1.0);
        service_capacity = (service_capacity + s.service_investment_rate + policy_investment - 0.003 * service_capacity).max(1.0);
    }

    Summary {
        scenario: s.name,
        final_population: population,
        final_housing: housing,
        final_transport: transport,
        final_service_capacity: service_capacity,
        final_accessibility,
        maximum_service_pressure,
        maximum_housing_gap,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_neighborhood", steps: 100, population: 100.0, housing: 112.0, transport: 90.0, service_capacity: 120.0, growth_pressure: 1.10, accessibility_attraction: 1.25, congestion_penalty: 0.70, housing_constraint_penalty: 0.45, housing_build_rate: 0.65, transport_investment_rate: 0.45, service_investment_rate: 0.35, periodic_policy_investment: 8.0, policy_interval: 20, pressure_penalty: 0.70 },
        Scenario { name: "strong_growth_pressure", steps: 100, population: 100.0, housing: 112.0, transport: 90.0, service_capacity: 120.0, growth_pressure: 1.65, accessibility_attraction: 1.25, congestion_penalty: 0.70, housing_constraint_penalty: 0.45, housing_build_rate: 0.65, transport_investment_rate: 0.45, service_investment_rate: 0.35, periodic_policy_investment: 8.0, policy_interval: 20, pressure_penalty: 0.70 },
        Scenario { name: "housing_constraint", steps: 100, population: 100.0, housing: 106.0, transport: 90.0, service_capacity: 120.0, growth_pressure: 1.10, accessibility_attraction: 1.25, congestion_penalty: 0.70, housing_constraint_penalty: 0.55, housing_build_rate: 0.25, transport_investment_rate: 0.45, service_investment_rate: 0.35, periodic_policy_investment: 8.0, policy_interval: 20, pressure_penalty: 0.70 },
        Scenario { name: "transport_investment", steps: 100, population: 100.0, housing: 112.0, transport: 90.0, service_capacity: 120.0, growth_pressure: 1.10, accessibility_attraction: 1.25, congestion_penalty: 0.70, housing_constraint_penalty: 0.45, housing_build_rate: 0.65, transport_investment_rate: 1.15, service_investment_rate: 0.85, periodic_policy_investment: 10.0, policy_interval: 20, pressure_penalty: 0.70 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_urban_system_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_population,final_housing,final_transport,final_service_capacity,final_accessibility,maximum_service_pressure,maximum_housing_gap,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.maximum_service_pressure > 1.0 || result.maximum_housing_gap > 10.0 {
            "capacity constrained pathway"
        } else {
            "managed growth pathway"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.final_population,
            result.final_housing,
            result.final_transport,
            result.final_service_capacity,
            result.final_accessibility,
            result.maximum_service_pressure,
            result.maximum_housing_gap,
            label
        )?;
    }

    println!("Rust urban diagnostics complete.");
    println!("outputs/tables/rust_urban_system_summary.csv");

    Ok(())
}
