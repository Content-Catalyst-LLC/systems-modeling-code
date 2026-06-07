# Panarchy and Multi-Scale Systems Modeling

Advanced companion code for the article **Panarchy and Multi-Scale Systems Modeling**.

GitHub folder:

```text
articles/panarchy-and-multi-scale-systems-modeling/
```

This companion folder turns panarchy, adaptive-cycle, and multi-scale systems concepts into reproducible modeling workflows. It includes linked fast and slow adaptive cycles, cross-scale coupling, revolt and remember dynamics, phase classification, release thresholds, memory diagnostics, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level fast/slow adaptive-cycle simulation engine
cpp/        Panarchy scenario scanner
data/       Panarchy taxonomy, scenario definitions, scale examples, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Cross-scale recurrence solver
go/         Panarchy diagnostics runner
julia/      Multi-scale adaptive-cycle ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library panarchy workflow
r/          Base R multi-scale panarchy diagnostics workflow
rust/       Command-line panarchy diagnostics scaffold
sql/        SQLite schema and panarchy analysis queries
```

## Professional modeling capabilities

- Linked fast and slow adaptive-cycle simulation
- Revolt and remember dynamics
- Cross-scale coupling diagnostics
- Phase classification across growth, conservation, release, and reorganization
- Release-threshold scenario testing
- Slow-memory and rigid-structure scenarios
- Multi-scale resilience diagnostics
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
python3 python/panarchy_multiscale_systems_workflow.py
Rscript r/panarchy_multiscale_cycles_diagnostics.R
sqlite3 outputs/tables/panarchy_multiscale_systems.sqlite < sql/panarchy_multiscale_systems_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/panarchy_engine.c -lm -o outputs/panarchy_engine && ./outputs/panarchy_engine > outputs/tables/c_panarchy_engine.csv
g++ -std=c++17 cpp/panarchy_scenario_scanner.cpp -o outputs/panarchy_scenario_scanner && ./outputs/panarchy_scenario_scanner > outputs/tables/cpp_panarchy_scenario_scanner.csv
gfortran fortran/panarchy_recurrence_solver.f90 -o outputs/panarchy_recurrence_solver && ./outputs/panarchy_recurrence_solver > outputs/tables/fortran_panarchy_recurrence.csv
go run go/panarchy_diagnostics_runner.go
rustc rust/panarchy_diagnostics_cli.rs -o outputs/panarchy_diagnostics_cli && ./outputs/panarchy_diagnostics_cli
julia julia/panarchy_multiscale_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate adaptive cycles, cross-scale coupling, revolt, remember, release thresholds, memory effects, and reproducible workflow organization. They are not calibrated empirical models of any real ecological, infrastructure, climate, health, financial, public policy, organizational, or social system. Applied use requires domain data, structural review, validation evidence, stakeholder review, and explicit scale-boundary judgment.
