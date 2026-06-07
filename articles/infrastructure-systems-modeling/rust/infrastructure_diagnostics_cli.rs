use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    steps: usize,
    shock_start: usize,
    shock_end: usize,
    power_loss_rate: f64,
    power_recovery_rate: f64,
    communications_dependency: f64,
    water_power_dependency: f64,
    water_comms_dependency: f64,
    transport_power_dependency: f64,
    transport_comms_dependency: f64,
}

struct Summary {
    scenario: &'static str,
    final_composite_service: f64,
    minimum_power: f64,
    minimum_communications: f64,
    minimum_water: f64,
    minimum_transport: f64,
    maximum_unmet_service: f64,
    total_unmet_service: f64,
}

fn simulate(s: &Scenario) -> Summary {
    let mut power = 1.0_f64;
    let mut communications = 1.0_f64;
    let mut water = 1.0_f64;
    let mut transport = 1.0_f64;

    let mut minimum_power = 1.0_f64;
    let mut minimum_communications = 1.0_f64;
    let mut minimum_water = 1.0_f64;
    let mut minimum_transport = 1.0_f64;
    let mut maximum_unmet_service = 0.0_f64;
    let mut total_unmet_service = 0.0_f64;
    let mut final_composite_service = 1.0_f64;

    for time in 0..s.steps {
        if time >= s.shock_start && time <= s.shock_end {
            power = (power - s.power_loss_rate).max(0.45);
        } else if time > s.shock_end {
            power = (power + s.power_recovery_rate).min(1.0);
        } else {
            power = 1.0;
        }

        communications = (s.communications_dependency * power + (1.0 - s.communications_dependency) * communications).max(0.40);
        water = (s.water_power_dependency * power
            + s.water_comms_dependency * communications
            + (1.0 - s.water_power_dependency - s.water_comms_dependency) * water).max(0.35);
        transport = (s.transport_power_dependency * power
            + s.transport_comms_dependency * communications
            + (1.0 - s.transport_power_dependency - s.transport_comms_dependency) * transport).max(0.35);

        let composite = (power + communications + water + transport) / 4.0;
        let unmet = 1.0 - composite;

        minimum_power = minimum_power.min(power);
        minimum_communications = minimum_communications.min(communications);
        minimum_water = minimum_water.min(water);
        minimum_transport = minimum_transport.min(transport);
        maximum_unmet_service = maximum_unmet_service.max(unmet);
        total_unmet_service += unmet;
        final_composite_service = composite;
    }

    Summary {
        scenario: s.name,
        final_composite_service,
        minimum_power,
        minimum_communications,
        minimum_water,
        minimum_transport,
        maximum_unmet_service,
        total_unmet_service,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_cascade", steps: 80, shock_start: 20, shock_end: 36, power_loss_rate: 0.035, power_recovery_rate: 0.025, communications_dependency: 0.72, water_power_dependency: 0.55, water_comms_dependency: 0.25, transport_power_dependency: 0.30, transport_comms_dependency: 0.25 },
        Scenario { name: "larger_power_loss", steps: 80, shock_start: 20, shock_end: 36, power_loss_rate: 0.055, power_recovery_rate: 0.025, communications_dependency: 0.72, water_power_dependency: 0.55, water_comms_dependency: 0.25, transport_power_dependency: 0.30, transport_comms_dependency: 0.25 },
        Scenario { name: "faster_recovery", steps: 80, shock_start: 20, shock_end: 36, power_loss_rate: 0.035, power_recovery_rate: 0.045, communications_dependency: 0.72, water_power_dependency: 0.55, water_comms_dependency: 0.25, transport_power_dependency: 0.30, transport_comms_dependency: 0.25 },
        Scenario { name: "longer_shock", steps: 80, shock_start: 20, shock_end: 48, power_loss_rate: 0.035, power_recovery_rate: 0.025, communications_dependency: 0.72, water_power_dependency: 0.55, water_comms_dependency: 0.25, transport_power_dependency: 0.30, transport_comms_dependency: 0.25 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_infrastructure_cascade_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_composite_service,minimum_power,minimum_communications,minimum_water,minimum_transport,maximum_unmet_service,total_unmet_service,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.maximum_unmet_service > 0.35 {
            "severe cascade pathway"
        } else {
            "managed cascade pathway"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.final_composite_service,
            result.minimum_power,
            result.minimum_communications,
            result.minimum_water,
            result.minimum_transport,
            result.maximum_unmet_service,
            result.total_unmet_service,
            label
        )?;
    }

    println!("Rust infrastructure diagnostics complete.");
    println!("outputs/tables/rust_infrastructure_cascade_summary.csv");

    Ok(())
}
