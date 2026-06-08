use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Summary {
    policy: &'static str,
    average_score: f64,
    worst_case_score: f64,
    best_case_score: f64,
    maximum_regret: f64,
    acceptable_share: f64,
    robustness_score: f64,
}

fn main() -> std::io::Result<()> {
    let summaries = vec![
        Summary { policy: "adaptive_pathway", average_score: 0.617, worst_case_score: 0.557, best_case_score: 0.684, maximum_regret: 0.000, acceptable_share: 1.000, robustness_score: 0.591 },
        Summary { policy: "targeted_intervention", average_score: 0.550, worst_case_score: 0.493, best_case_score: 0.622, maximum_regret: 0.093, acceptable_share: 0.833, robustness_score: 0.502 },
        Summary { policy: "universal_program", average_score: 0.545, worst_case_score: 0.473, best_case_score: 0.628, maximum_regret: 0.112, acceptable_share: 0.667, robustness_score: 0.485 },
        Summary { policy: "status_quo_maintenance", average_score: 0.380, worst_case_score: 0.338, best_case_score: 0.423, maximum_regret: 0.275, acceptable_share: 0.000, robustness_score: 0.292 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_policy_robustness_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "policy,average_score,worst_case_score,best_case_score,maximum_regret,acceptable_scenario_share,robustness_score")?;

    for item in &summaries {
        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6}",
            item.policy,
            item.average_score,
            item.worst_case_score,
            item.best_case_score,
            item.maximum_regret,
            item.acceptable_share,
            item.robustness_score
        )?;
    }

    println!("Rust policy robustness CLI complete.");
    println!("outputs/tables/rust_policy_robustness_summary.csv");

    Ok(())
}
