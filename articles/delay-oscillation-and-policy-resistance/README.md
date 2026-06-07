# Delay, Oscillation, and Policy Resistance

Advanced companion code for the article **Delay, Oscillation, and Policy Resistance**.

GitHub folder:

```text
articles/delay-oscillation-and-policy-resistance/
```

This companion folder turns delay, oscillation, and policy-resistance concepts into reproducible systems-modeling workflows. It includes delayed-feedback simulation, perceived-versus-actual state modeling, overcorrection and undercorrection scenarios, target-crossing diagnostics, overshoot metrics, policy-resistance counterresponse, intervention pipelines, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level delayed-feedback simulation engine
cpp/        Delay and counterresponse scenario scanner
data/       Delay taxonomy, scenario definitions, parameters, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Delayed-feedback recurrence solver
go/         Delay and policy-resistance diagnostics runner
julia/      Delay/oscillation ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library delay/oscillation workflow
r/          Base R delayed-feedback diagnostics workflow
rust/       Command-line delay diagnostics scaffold
sql/        SQLite schema and delay/policy-resistance analysis queries
```

## Professional modeling capabilities

- Information-delay and perception-lag modeling
- Delayed corrective-feedback simulation
- Oscillation and target-crossing diagnostics
- Overshoot and undershoot metrics
- Correction-strength sensitivity
- Policy-resistance counterresponse modeling
- Cumulative intervention and counterresponse accounting
- Resistance-ratio diagnostics
- Scenario comparisons
- Validation checks
- SQL model-run schema
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/delay_oscillation_policy_resistance_workflow.py
Rscript r/delay_oscillation_policy_resistance_diagnostics.R
sqlite3 outputs/tables/delay_oscillation_policy_resistance.sqlite < sql/delay_oscillation_policy_resistance_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/delay_oscillation_engine.c -lm -o outputs/delay_oscillation_engine && ./outputs/delay_oscillation_engine > outputs/tables/c_delay_oscillation_engine.csv
g++ -std=c++17 cpp/delay_policy_resistance_scanner.cpp -o outputs/delay_policy_resistance_scanner && ./outputs/delay_policy_resistance_scanner > outputs/tables/cpp_delay_policy_resistance_scanner.csv
gfortran fortran/delayed_feedback_recurrence_solver.f90 -o outputs/delayed_feedback_recurrence_solver && ./outputs/delayed_feedback_recurrence_solver > outputs/tables/fortran_delayed_feedback_recurrence.csv
go run go/delay_policy_diagnostics_runner.go
rustc rust/delay_policy_diagnostics_cli.rs -o outputs/delay_policy_diagnostics_cli && ./outputs/delay_policy_diagnostics_cli
julia julia/delay_oscillation_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate delayed feedback, oscillation, target crossings, overshoot, perceived-state delay, correction strength, policy-resistance counterresponse, and reproducible workflow organization. They are not calibrated empirical models of any real public policy, infrastructure, health, environmental, climate, organizational, or economic system. Applied use requires domain data, structural review, validation evidence, justified delay assumptions, uncertainty communication, stakeholder review, and boundary critique.
