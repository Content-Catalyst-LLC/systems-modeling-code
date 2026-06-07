use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    n_steps: usize,
    demand_sensitivity: f64,
    investment_sensitivity: f64,
    interest_rate: f64,
    depreciation: f64,
    credit_sensitivity: f64,
    shock_step: usize,
    shock_size: f64,
}

struct Summary {
    scenario: &'static str,
    final_output: f64,
    final_capital: f64,
    final_debt: f64,
    final_fragility: f64,
    maximum_fragility: f64,
    minimum_output: f64,
    average_output: f64,
}

fn deterministic_noise(step: usize) -> f64 {
    (step as f64 * 1.61803398875).sin() * 0.35
}

fn simulate(s: &Scenario) -> Summary {
    let mut output = 100.0_f64;
    let mut capital = 190.0_f64;
    let mut debt = 60.0_f64;
    let government = 22.0_f64;

    let mut maximum_fragility = debt / capital;
    let mut minimum_output = output;
    let mut total_output = 0.0_f64;

    for step in 1..=s.n_steps {
        let consumption = (18.0 + s.demand_sensitivity * output - 0.025 * debt).max(0.0);
        let investment = (s.investment_sensitivity * output - s.interest_rate * debt).max(0.0);

        if step > 1 {
            capital = (capital + investment - s.depreciation * capital).max(0.0);

            let new_credit = (s.credit_sensitivity * investment).max(0.0);
            let repayment = 0.025 * debt;
            debt = (debt + new_credit - repayment).max(0.0);

            let shock = if step == s.shock_step { s.shock_size } else { 0.0 };
            output = (0.33 * capital + consumption + government + shock + deterministic_noise(step)).max(0.0);
        }

        let fragility = debt / capital.max(1.0);
        maximum_fragility = maximum_fragility.max(fragility);
        minimum_output = minimum_output.min(output);
        total_output += output;
    }

    Summary {
        scenario: s.name,
        final_output: output,
        final_capital: capital,
        final_debt: debt,
        final_fragility: debt / capital.max(1.0),
        maximum_fragility,
        minimum_output,
        average_output: total_output / s.n_steps as f64,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_feedback", n_steps: 120, demand_sensitivity: 0.62, investment_sensitivity: 0.16, interest_rate: 0.035, depreciation: 0.045, credit_sensitivity: 0.10, shock_step: 70, shock_size: -8.0 },
        Scenario { name: "higher_investment", n_steps: 120, demand_sensitivity: 0.62, investment_sensitivity: 0.21, interest_rate: 0.035, depreciation: 0.045, credit_sensitivity: 0.10, shock_step: 70, shock_size: -8.0 },
        Scenario { name: "tighter_credit", n_steps: 120, demand_sensitivity: 0.62, investment_sensitivity: 0.16, interest_rate: 0.055, depreciation: 0.045, credit_sensitivity: 0.10, shock_step: 70, shock_size: -8.0 },
        Scenario { name: "larger_shock", n_steps: 120, demand_sensitivity: 0.62, investment_sensitivity: 0.16, interest_rate: 0.035, depreciation: 0.045, credit_sensitivity: 0.10, shock_step: 70, shock_size: -18.0 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_economic_feedback_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_output,final_capital,final_debt,final_fragility,maximum_fragility,minimum_output,average_output,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.maximum_fragility > 0.75 {
            "high fragility pathway"
        } else {
            "moderate fragility pathway"
        };

        writeln!(
            writer,
            "{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
            result.scenario,
            result.final_output,
            result.final_capital,
            result.final_debt,
            result.final_fragility,
            result.maximum_fragility,
            result.minimum_output,
            result.average_output,
            label
        )?;
    }

    println!("Rust economic diagnostics complete.");
    println!("outputs/tables/rust_economic_feedback_summary.csv");

    Ok(())
}
