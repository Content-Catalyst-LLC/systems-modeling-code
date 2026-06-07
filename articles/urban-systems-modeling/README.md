# Urban Systems Modeling

Advanced companion code for the article **Urban Systems Modeling**.

GitHub folder:

```text
articles/urban-systems-modeling/
```

This companion folder turns urban systems concepts into reproducible systems-modeling workflows. It includes urban growth simulations, accessibility and congestion feedback, housing capacity diagnostics, infrastructure service pressure, policy investment scenarios, equity and distributional-risk taxonomies, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level urban growth feedback engine
cpp/        Urban scenario scanner
data/       Urban components, scenarios, feedback loops, equity dimensions, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Urban capacity recurrence solver
go/         Urban diagnostics runner
julia/      Urban growth and infrastructure ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library urban systems workflow
r/          Base R urban growth and congestion diagnostics workflow
rust/       Command-line urban diagnostics scaffold
sql/        SQLite schema and urban systems analysis queries
```

## Professional modeling capabilities

- Urban growth feedback simulation
- Accessibility, congestion, housing capacity, and service pressure diagnostics
- Policy investment scenario comparison
- Land-use transportation and urban form taxonomies
- Infrastructure capacity and service-system examples
- Equity, segregation, environmental exposure, and displacement-risk concept tables
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
python3 python/urban_systems_modeling_workflow.py
Rscript r/urban_systems_growth_feedback_diagnostics.R
sqlite3 outputs/tables/urban_systems_modeling.sqlite < sql/urban_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/urban_growth_feedback_engine.c -lm -o outputs/urban_growth_feedback_engine && ./outputs/urban_growth_feedback_engine > outputs/tables/c_urban_growth_feedback_engine.csv
g++ -std=c++17 cpp/urban_scenario_scanner.cpp -o outputs/urban_scenario_scanner && ./outputs/urban_scenario_scanner > outputs/tables/cpp_urban_scenario_scanner.csv
gfortran fortran/urban_recurrence_solver.f90 -o outputs/urban_recurrence_solver && ./outputs/urban_recurrence_solver > outputs/tables/fortran_urban_recurrence.csv
go run go/urban_diagnostics_runner.go
rustc rust/urban_diagnostics_cli.rs -o outputs/urban_diagnostics_cli && ./outputs/urban_diagnostics_cli
julia julia/urban_systems_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate urban growth, accessibility, congestion, housing capacity, infrastructure pressure, policy investment, validation, and reproducible workflow organization. They are not calibrated empirical models of any real neighborhood, city, corridor, region, infrastructure system, planning process, or public policy decision. Applied use requires local data, spatial validation, community review, calibration, sensitivity analysis, equity assessment, and responsible communication.
