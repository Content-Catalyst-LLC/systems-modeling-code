use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Summary {
    scenario: &'static str,
    final_adoption_share: f64,
    final_adopter_count: i32,
    maximum_adoption_gap: f64,
    time_to_25_percent: i32,
    time_to_50_percent: i32,
    peak_growth: f64,
}

fn main() -> std::io::Result<()> {
    let summaries = vec![
        Summary { scenario: "baseline_diffusion", final_adoption_share: 0.520000, final_adopter_count: 62, maximum_adoption_gap: 0.250000, time_to_25_percent: 8, time_to_50_percent: 26, peak_growth: 0.045000 },
        Summary { scenario: "high_social_influence", final_adoption_share: 0.720000, final_adopter_count: 86, maximum_adoption_gap: 0.300000, time_to_25_percent: 5, time_to_50_percent: 14, peak_growth: 0.080000 },
        Summary { scenario: "high_cost_barrier", final_adoption_share: 0.280000, final_adopter_count: 34, maximum_adoption_gap: 0.180000, time_to_25_percent: 30, time_to_50_percent: -1, peak_growth: 0.030000 },
        Summary { scenario: "targeted_seeding", final_adoption_share: 0.610000, final_adopter_count: 73, maximum_adoption_gap: 0.220000, time_to_25_percent: 6, time_to_50_percent: 21, peak_growth: 0.055000 },
        Summary { scenario: "network_fragmentation", final_adoption_share: 0.460000, final_adopter_count: 55, maximum_adoption_gap: 0.420000, time_to_25_percent: 12, time_to_50_percent: -1, peak_growth: 0.040000 },
        Summary { scenario: "trust_and_resistance", final_adoption_share: 0.340000, final_adopter_count: 41, maximum_adoption_gap: 0.310000, time_to_25_percent: 24, time_to_50_percent: -1, peak_growth: 0.025000 },
        Summary { scenario: "bridge_and_equity_seeding", final_adoption_share: 0.660000, final_adopter_count: 79, maximum_adoption_gap: 0.190000, time_to_25_percent: 5, time_to_50_percent: 18, peak_growth: 0.060000 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_adoption_diffusion_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "scenario,final_adoption_share,final_adopter_count,maximum_adoption_gap,time_to_25_percent,time_to_50_percent,peak_growth")?;

    for item in &summaries {
        writeln!(
            writer,
            "{},{:.6},{},{:.6},{},{},{:.6}",
            item.scenario,
            item.final_adoption_share,
            item.final_adopter_count,
            item.maximum_adoption_gap,
            item.time_to_25_percent,
            item.time_to_50_percent,
            item.peak_growth
        )?;
    }

    println!("Rust adoption diffusion CLI complete.");
    println!("outputs/tables/rust_adoption_diffusion_summary.csv");

    Ok(())
}
