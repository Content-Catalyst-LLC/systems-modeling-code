# Infrastructure Systems Modeling

Advanced companion code for the article **Infrastructure Systems Modeling**.

GitHub folder:

```text
articles/infrastructure-systems-modeling/
```

This companion folder turns infrastructure systems concepts into reproducible systems-modeling workflows. It includes load-capacity diagnostics, interdependent infrastructure cascade simulations, resilience and recovery indicators, maintenance and service-risk taxonomies, equity and distributional-risk examples, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level infrastructure cascade engine
cpp/        Infrastructure scenario scanner
data/       Infrastructure components, scenarios, dependencies, equity dimensions, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Infrastructure service recurrence solver
go/         Infrastructure diagnostics runner
julia/      Infrastructure cascade ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library infrastructure systems workflow
r/          Base R load-capacity and service disruption diagnostics workflow
rust/       Command-line infrastructure diagnostics scaffold
sql/        SQLite schema and infrastructure systems analysis queries
```

## Professional modeling capabilities

- Infrastructure load-capacity diagnostics
- Interdependent power, communications, water, and transport cascade simulation
- Service availability and unmet service metrics
- Recovery and resilience indicators
- Maintenance, aging, and deferred-investment taxonomy
- Critical infrastructure interdependence tables
- Equity, access, affordability, and restoration-priority concept tables
- SQL model-run schema
- Validation checks
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/infrastructure_systems_modeling_workflow.py
Rscript r/infrastructure_systems_load_capacity_diagnostics.R
sqlite3 outputs/tables/infrastructure_systems_modeling.sqlite < sql/infrastructure_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/infrastructure_cascade_engine.c -lm -o outputs/infrastructure_cascade_engine && ./outputs/infrastructure_cascade_engine > outputs/tables/c_infrastructure_cascade_engine.csv
g++ -std=c++17 cpp/infrastructure_scenario_scanner.cpp -o outputs/infrastructure_scenario_scanner && ./outputs/infrastructure_scenario_scanner > outputs/tables/cpp_infrastructure_scenario_scanner.csv
gfortran fortran/infrastructure_recurrence_solver.f90 -o outputs/infrastructure_recurrence_solver && ./outputs/infrastructure_recurrence_solver > outputs/tables/fortran_infrastructure_recurrence.csv
go run go/infrastructure_diagnostics_runner.go
rustc rust/infrastructure_diagnostics_cli.rs -o outputs/infrastructure_diagnostics_cli && ./outputs/infrastructure_diagnostics_cli
julia julia/infrastructure_systems_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate infrastructure load, capacity, interdependence, cascading service disruption, recovery, validation, and reproducible workflow organization. They are not calibrated empirical models of any real power grid, water system, transportation system, communications network, emergency service, city, region, public agency, or infrastructure investment decision. Applied use requires engineering data, local operations data, dependency audit, calibration, validation, stress testing, equity assessment, community review, and responsible communication.
