# Economic Systems Modeling

Advanced companion code for the article **Economic Systems Modeling**.

GitHub folder:

```text
articles/economic-systems-modeling/
```

This companion folder turns economic systems concepts into reproducible systems-modeling workflows. It includes demand-investment feedback simulations, capital accumulation, credit and debt dynamics, fragility diagnostics, sectoral-balance examples, scenario comparisons, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level economic feedback engine
cpp/        Economic scenario scanner
data/       Economic concepts, scenarios, model components, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Capital-debt recurrence solver
go/         Economic feedback diagnostics runner
julia/      Economic feedback ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library economic systems workflow
r/          Base R demand-investment feedback diagnostics workflow
rust/       Command-line economic diagnostics scaffold
sql/        SQLite schema and economic systems analysis queries
```

## Professional modeling capabilities

- Demand-investment feedback simulation
- Capital accumulation and depreciation
- Consumption, government demand, and investment diagnostics
- Credit expansion and debt-service tracking
- Fragility ratio diagnostics
- Shock response and scenario comparison
- Stock-flow and sectoral-balance examples
- Economic component and feedback taxonomies
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
python3 python/economic_systems_modeling_workflow.py
Rscript r/economic_systems_feedback_diagnostics.R
sqlite3 outputs/tables/economic_systems_modeling.sqlite < sql/economic_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/economic_feedback_engine.c -lm -o outputs/economic_feedback_engine && ./outputs/economic_feedback_engine > outputs/tables/c_economic_feedback_engine.csv
g++ -std=c++17 cpp/economic_scenario_scanner.cpp -o outputs/economic_scenario_scanner && ./outputs/economic_scenario_scanner > outputs/tables/cpp_economic_scenario_scanner.csv
gfortran fortran/economic_recurrence_solver.f90 -o outputs/economic_recurrence_solver && ./outputs/economic_recurrence_solver > outputs/tables/fortran_economic_recurrence.csv
go run go/economic_diagnostics_runner.go
rustc rust/economic_diagnostics_cli.rs -o outputs/economic_diagnostics_cli && ./outputs/economic_diagnostics_cli
julia julia/economic_feedback_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate economic feedback, accumulation, credit fragility, shock propagation, scenario comparison, validation, and reproducible workflow organization. They are not calibrated empirical models of any real economy, market, region, sector, institution, public policy, financial system, or sustainability pathway. Applied use requires domain evidence, data audit, calibration, validation, uncertainty analysis, distributional review, and responsible communication.
