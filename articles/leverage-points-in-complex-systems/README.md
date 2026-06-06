# Leverage Points in Complex Systems

Advanced companion code for the article **Leverage Points in Complex Systems**.

GitHub folder:

```text
articles/leverage-points-in-complex-systems/
```

This companion folder turns leverage-point concepts into reproducible systems-modeling workflows. It includes shallow-versus-deep intervention models, parameter-change scenarios, buffer and delay diagnostics, feedback-gain interventions, information-flow interventions, rule-change workflows, self-organization scenarios, goal-shift scenarios, leverage-ratio metrics, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level shallow-versus-deep intervention engine
cpp/        Leverage intervention ensemble scanner
data/       Leverage hierarchy, scenarios, domain examples, validation targets
docs/       Leverage modeling protocol, assumptions, validation, responsible use
fortran/    Intervention recurrence solver
go/         Leverage diagnostics runner
julia/      Intervention-depth ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library leverage-point modeling workflow
r/          Base R intervention-depth diagnostics workflow
rust/       Command-line leverage diagnostics scaffold
sql/        SQLite schema and leverage-point analysis queries
```

## Professional modeling capabilities

- Meadows-style leverage hierarchy inventory
- Shallow-versus-deep intervention comparison
- Parameter-change scenarios
- Buffer and delay diagnostics
- Feedback-gain intervention analysis
- Information-flow intervention analysis
- Rule-change intervention analysis
- Self-organization and learning scenarios
- Goal-shift intervention analysis
- Cumulative intervention accounting
- Behavior-change and leverage-ratio metrics
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
python3 python/leverage_points_modeling_workflow.py
Rscript r/leverage_points_intervention_diagnostics.R
sqlite3 outputs/tables/leverage_points_modeling.sqlite < sql/leverage_points_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/leverage_points_engine.c -lm -o outputs/leverage_points_engine && ./outputs/leverage_points_engine > outputs/tables/c_leverage_points_engine.csv
g++ -std=c++17 cpp/leverage_intervention_scanner.cpp -o outputs/leverage_intervention_scanner && ./outputs/leverage_intervention_scanner > outputs/tables/cpp_leverage_intervention_scanner.csv
gfortran fortran/leverage_recurrence_solver.f90 -o outputs/leverage_recurrence_solver && ./outputs/leverage_recurrence_solver > outputs/tables/fortran_leverage_recurrence.csv
go run go/leverage_diagnostics_runner.go
rustc rust/leverage_diagnostics_cli.rs -o outputs/leverage_diagnostics_cli && ./outputs/leverage_diagnostics_cli
julia julia/leverage_points_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate intervention-depth comparison, leverage-ratio diagnostics, feedback gain, information delay, rule logic, self-organization, goal shifts, and reproducible workflow organization. They are not calibrated empirical models of any real climate, infrastructure, economic, health, environmental, organizational, or policy system. Applied use requires domain data, structural review, validation evidence, justified intervention assumptions, uncertainty communication, stakeholder review, and boundary critique.
