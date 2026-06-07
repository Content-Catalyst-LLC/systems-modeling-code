use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    grid_size: usize,
    hazard_multiplier: f64,
    vulnerability_multiplier: f64,
    population_multiplier: f64,
    service_capacity_multiplier: f64,
    service_shift: i32,
}

struct Service {
    id: &'static str,
    x: f64,
    y: f64,
    capacity: f64,
}

struct Summary {
    scenario: &'static str,
    cell_count: usize,
    population: f64,
    total_risk: f64,
    average_risk: f64,
    average_access: f64,
    average_gap: f64,
}

fn distance(x1: f64, y1: f64, x2: f64, y2: f64) -> f64 {
    ((x1 - x2).powi(2) + (y1 - y2).powi(2)).sqrt()
}

fn services(shift: i32, multiplier: f64) -> Vec<Service> {
    vec![
        Service { id: "clinic_a", x: (5 + shift) as f64, y: 6.0, capacity: 900.0 * multiplier },
        Service { id: "clinic_b", x: 9.0, y: (20 - shift) as f64, capacity: 650.0 * multiplier },
        Service { id: "clinic_c", x: (18 - shift) as f64, y: (10 + shift) as f64, capacity: 800.0 * multiplier },
        Service { id: "clinic_d", x: 22.0, y: 21.0, capacity: 500.0 * multiplier },
    ]
}

fn simulate(s: &Scenario) -> Summary {
    let center = (s.grid_size as f64 + 1.0) / 2.0;
    let service_list = services(s.service_shift, s.service_capacity_multiplier);

    let mut cell_count = 0_usize;
    let mut population_total = 0.0_f64;
    let mut risk_total = 0.0_f64;
    let mut access_total = 0.0_f64;
    let mut gap_total = 0.0_f64;

    for x in 1..=s.grid_size {
        for y in 1..=s.grid_size {
            let xf = x as f64;
            let yf = y as f64;

            let d_center = distance(xf, yf, center, center);
            let d_river = (yf - (0.45 * xf + 4.0)).abs();

            let population = ((120.0 + 500.0 * (-d_center / 7.0).exp() + (xf * yf).sin() * 25.0) * s.population_multiplier).max(0.0);
            let hazard = (((-d_river / 3.0).exp() + 0.06) * s.hazard_multiplier).min(1.0);
            let vulnerability = ((0.25 + 0.45 * (-d_center / 9.0).exp() + 0.03 * (xf + yf).sin()) * s.vulnerability_multiplier).clamp(0.0, 1.0);
            let risk = hazard * population * vulnerability;

            let mut access = 0.0_f64;
            for service in &service_list {
                let d = distance(xf, yf, service.x, service.y);
                access += service.capacity * (1.0 / (1.0 + d * d));
                let _ = service.id;
            }

            let gap = population / (access + 1.0);

            cell_count += 1;
            population_total += population;
            risk_total += risk;
            access_total += access;
            gap_total += gap;
        }
    }

    let count = (cell_count as f64).max(1.0);

    Summary {
        scenario: s.name,
        cell_count,
        population: population_total,
        total_risk: risk_total,
        average_risk: risk_total / count,
        average_access: access_total / count,
        average_gap: gap_total / count,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_spatial_system", grid_size: 25, hazard_multiplier: 1.00, vulnerability_multiplier: 1.00, population_multiplier: 1.00, service_capacity_multiplier: 1.00, service_shift: 0 },
        Scenario { name: "higher_hazard_system", grid_size: 25, hazard_multiplier: 1.35, vulnerability_multiplier: 1.00, population_multiplier: 1.00, service_capacity_multiplier: 1.00, service_shift: 0 },
        Scenario { name: "high_vulnerability_system", grid_size: 25, hazard_multiplier: 1.00, vulnerability_multiplier: 1.35, population_multiplier: 1.00, service_capacity_multiplier: 1.00, service_shift: 0 },
        Scenario { name: "low_access_system", grid_size: 25, hazard_multiplier: 1.00, vulnerability_multiplier: 1.00, population_multiplier: 1.00, service_capacity_multiplier: 0.65, service_shift: 0 },
        Scenario { name: "resilient_service_system", grid_size: 25, hazard_multiplier: 0.90, vulnerability_multiplier: 0.90, population_multiplier: 1.00, service_capacity_multiplier: 1.30, service_shift: 3 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_geospatial_priority_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,cell_count,population,total_risk_score,average_risk_score,average_accessibility,average_service_gap_score,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.average_risk > 140.0 {
            "elevated spatial risk pressure"
        } else {
            "standard spatial pressure"
        };

        writeln!(
            writer,
            "{},{},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.cell_count,
            result.population,
            result.total_risk,
            result.average_risk,
            result.average_access,
            result.average_gap,
            label
        )?;
    }

    println!("Rust geospatial diagnostics complete.");
    println!("outputs/tables/rust_geospatial_priority_summary.csv");

    Ok(())
}
