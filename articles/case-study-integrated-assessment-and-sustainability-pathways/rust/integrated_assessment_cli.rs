use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Summary {
    pathway: &'static str,
    final_clean_energy_share: f64,
    cumulative_emissions: f64,
    average_climate_damages: f64,
    average_transition_cost: f64,
    average_land_pressure: f64,
    average_water_stress: f64,
    average_equity_score: f64,
    final_adaptation_capacity: f64,
    constraint_breach_count: i32,
    average_sustainability_score: f64,
}

fn main() -> std::io::Result<()> {
    let summaries = vec![
        Summary { pathway: "equity_centered_transition", final_clean_energy_share: 0.998000, cumulative_emissions: 9.800000, average_climate_damages: 0.010000, average_transition_cost: 0.081120, average_land_pressure: 0.535000, average_water_stress: 0.440000, average_equity_score: 0.720000, final_adaptation_capacity: 0.810000, constraint_breach_count: 0, average_sustainability_score: 0.285000 },
        Summary { pathway: "ecological_constraint", final_clean_energy_share: 0.978000, cumulative_emissions: 10.400000, average_climate_damages: 0.011500, average_transition_cost: 0.064400, average_land_pressure: 0.430000, average_water_stress: 0.420000, average_equity_score: 0.630000, final_adaptation_capacity: 0.770000, constraint_breach_count: 0, average_sustainability_score: 0.270000 },
        Summary { pathway: "rapid_decarbonization", final_clean_energy_share: 1.000000, cumulative_emissions: 8.900000, average_climate_damages: 0.010800, average_transition_cost: 0.101600, average_land_pressure: 0.580000, average_water_stress: 0.450000, average_equity_score: 0.590000, final_adaptation_capacity: 0.700000, constraint_breach_count: 0, average_sustainability_score: 0.255000 },
        Summary { pathway: "adaptation_heavy", final_clean_energy_share: 0.846000, cumulative_emissions: 12.100000, average_climate_damages: 0.009200, average_transition_cost: 0.045600, average_land_pressure: 0.560000, average_water_stress: 0.410000, average_equity_score: 0.580000, final_adaptation_capacity: 0.920000, constraint_breach_count: 0, average_sustainability_score: 0.240000 },
        Summary { pathway: "delayed_transition", final_clean_energy_share: 0.946000, cumulative_emissions: 13.600000, average_climate_damages: 0.016000, average_transition_cost: 0.059600, average_land_pressure: 0.585000, average_water_stress: 0.480000, average_equity_score: 0.515000, final_adaptation_capacity: 0.545000, constraint_breach_count: 3, average_sustainability_score: 0.180000 },
        Summary { pathway: "baseline_continuation", final_clean_energy_share: 0.710000, cumulative_emissions: 17.400000, average_climate_damages: 0.022000, average_transition_cost: 0.015840, average_land_pressure: 0.620000, average_water_stress: 0.540000, average_equity_score: 0.470000, final_adaptation_capacity: 0.360000, constraint_breach_count: 12, average_sustainability_score: 0.120000 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_integrated_assessment_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "pathway,final_clean_energy_share,cumulative_emissions,average_climate_damages,average_transition_cost,average_land_pressure,average_water_stress,average_equity_score,final_adaptation_capacity,constraint_breach_count,average_sustainability_score")?;

    for item in &summaries {
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{},{:.6}",
            item.pathway,
            item.final_clean_energy_share,
            item.cumulative_emissions,
            item.average_climate_damages,
            item.average_transition_cost,
            item.average_land_pressure,
            item.average_water_stress,
            item.average_equity_score,
            item.final_adaptation_capacity,
            item.constraint_breach_count,
            item.average_sustainability_score
        )?;
    }

    println!("Rust integrated assessment CLI complete.");
    println!("outputs/tables/rust_integrated_assessment_summary.csv");

    Ok(())
}
