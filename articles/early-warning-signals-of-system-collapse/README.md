# Early Warning Signals of System Collapse

Advanced companion code for the article **Early Warning Signals of System Collapse**.

GitHub folder:

```text
articles/early-warning-signals-of-system-collapse/
```

This companion folder turns early-warning-signal concepts into reproducible systems-modeling workflows. It includes weakening-recovery simulations, rolling variance, lag-1 autocorrelation, trend diagnostics, recovery-rate indicators, spatial and network warning examples, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level rolling early-warning indicator engine
cpp/        Early-warning scenario scanner
data/       Indicator taxonomy, scenario definitions, domain examples, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Autoregressive warning recurrence solver
go/         Early-warning diagnostics runner
julia/      Early-warning indicator ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library early-warning workflow
r/          Base R rolling warning diagnostics workflow
rust/       Command-line early-warning diagnostics scaffold
sql/        SQLite schema and early-warning analysis queries
```

## Professional modeling capabilities

- Simulated weakening recovery
- Rolling variance diagnostics
- Rolling lag-1 autocorrelation diagnostics
- Critical-slowing-down proxy indicators
- Trend diagnostics for warning signals
- Recovery-rate and perturbation examples
- Spatial and network warning-signal examples
- Scenario comparison under noise and stability assumptions
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
python3 python/early_warning_signals_workflow.py
Rscript r/early_warning_signals_diagnostics.R
sqlite3 outputs/tables/early_warning_signals.sqlite < sql/early_warning_signals_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/early_warning_engine.c -lm -o outputs/early_warning_engine && ./outputs/early_warning_engine > outputs/tables/c_early_warning_engine.csv
g++ -std=c++17 cpp/early_warning_scenario_scanner.cpp -o outputs/early_warning_scenario_scanner && ./outputs/early_warning_scenario_scanner > outputs/tables/cpp_early_warning_scenario_scanner.csv
gfortran fortran/early_warning_recurrence_solver.f90 -o outputs/early_warning_recurrence_solver && ./outputs/early_warning_recurrence_solver > outputs/tables/fortran_early_warning_recurrence.csv
go run go/early_warning_diagnostics_runner.go
rustc rust/early_warning_diagnostics_cli.rs -o outputs/early_warning_diagnostics_cli && ./outputs/early_warning_diagnostics_cli
julia julia/early_warning_indicator_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate early-warning indicators, critical-slowing-down proxies, rolling diagnostics, and reproducible workflow organization. They are not calibrated empirical models of any real climate, ecological, infrastructure, health, financial, organizational, public policy, or social system. Applied use requires domain evidence, structural review, data auditing, validation, sensitivity analysis, stakeholder review, and responsible communication.
