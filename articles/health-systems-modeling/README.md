# Health Systems Modeling

Advanced companion code for the article **Health Systems Modeling**.

GitHub folder:

```text
articles/health-systems-modeling/
```

This companion folder turns health systems concepts into reproducible systems-modeling workflows. It includes demand-capacity simulations, backlog and unmet-need diagnostics, workforce burnout and attrition dynamics, access barriers, trust, prevention and surge scenarios, health equity taxonomies, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level health demand-capacity engine
cpp/        Health system scenario scanner
data/       Health system components, scenarios, feedback loops, equity dimensions, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Health system recurrence solver
go/         Health diagnostics runner
julia/      Health system pressure ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library health systems workflow
r/          Base R care demand-capacity diagnostics workflow
rust/       Command-line health diagnostics scaffold
sql/        SQLite schema and health systems analysis queries
```

## Professional modeling capabilities

- Health system demand-capacity pressure simulation
- Patient backlog and unmet-need diagnostics
- Workforce burnout and attrition dynamics
- Access gap and trust indicators
- Prevention and surge scenario comparison
- Health equity and social determinants concept tables
- Quality, safety, financing, digital health, and resilience taxonomies
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
python3 python/health_systems_modeling_workflow.py
Rscript r/health_systems_capacity_backlog_diagnostics.R
sqlite3 outputs/tables/health_systems_modeling.sqlite < sql/health_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/health_system_pressure_engine.c -lm -o outputs/health_system_pressure_engine && ./outputs/health_system_pressure_engine > outputs/tables/c_health_system_pressure_engine.csv
g++ -std=c++17 cpp/health_system_scenario_scanner.cpp -o outputs/health_system_scenario_scanner && ./outputs/health_system_scenario_scanner > outputs/tables/cpp_health_system_scenario_scanner.csv
gfortran fortran/health_system_recurrence_solver.f90 -o outputs/health_system_recurrence_solver && ./outputs/health_system_recurrence_solver > outputs/tables/fortran_health_system_recurrence.csv
go run go/health_system_diagnostics_runner.go
rustc rust/health_system_diagnostics_cli.rs -o outputs/health_system_diagnostics_cli && ./outputs/health_system_diagnostics_cli
julia julia/health_systems_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate health system demand, service capacity, backlog, workforce burnout, attrition, access gaps, trust, prevention, surge pressure, validation, and reproducible workflow organization. They are not calibrated empirical models of any real patient population, hospital, clinic, public health agency, disease, workforce, payer, community, or health policy. Applied use requires clinical and operational evidence, privacy governance, consent where appropriate, stakeholder review, calibration, validation, uncertainty analysis, equity assessment, and responsible communication.
