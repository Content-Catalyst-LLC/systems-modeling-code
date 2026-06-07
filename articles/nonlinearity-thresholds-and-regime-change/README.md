# Nonlinearity, Thresholds, and Regime Change

Advanced companion code for the article **Nonlinearity, Thresholds, and Regime Change**.

GitHub folder:

```text
articles/nonlinearity-thresholds-and-regime-change/
```

This companion folder turns nonlinear systems concepts into reproducible systems-modeling workflows. It includes nonlinear damage functions, threshold-crossing diagnostics, regime-specific behavior, hysteresis, collapse and recovery thresholds, early-warning indicators, critical-transition scenarios, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level nonlinear threshold simulation engine
cpp/        Regime-change scenario scanner
data/       Nonlinearity taxonomy, scenario definitions, examples, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Nonlinear recurrence solver
go/         Regime diagnostics runner
julia/      Threshold/regime ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library nonlinear-regime workflow
r/          Base R threshold and regime-change diagnostics workflow
rust/       Command-line nonlinear diagnostics scaffold
sql/        SQLite schema and threshold/regime analysis queries
```

## Professional modeling capabilities

- Nonlinear response simulation
- Threshold crossing and regime classification
- Collapse and recovery threshold comparison
- Hysteresis diagnostics
- Regime-specific damage and recovery functions
- Early-warning indicators
- Rolling variance and autocorrelation diagnostics
- Scenario comparison for intervention timing and threshold uncertainty
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
python3 python/nonlinearity_threshold_regime_workflow.py
Rscript r/nonlinearity_threshold_regime_diagnostics.R
sqlite3 outputs/tables/nonlinearity_threshold_regime.sqlite < sql/nonlinearity_threshold_regime_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/nonlinear_threshold_engine.c -lm -o outputs/nonlinear_threshold_engine && ./outputs/nonlinear_threshold_engine > outputs/tables/c_nonlinear_threshold_engine.csv
g++ -std=c++17 cpp/regime_change_scenario_scanner.cpp -o outputs/regime_change_scenario_scanner && ./outputs/regime_change_scenario_scanner > outputs/tables/cpp_regime_change_scenario_scanner.csv
gfortran fortran/nonlinear_regime_recurrence_solver.f90 -o outputs/nonlinear_regime_recurrence_solver && ./outputs/nonlinear_regime_recurrence_solver > outputs/tables/fortran_nonlinear_regime_recurrence.csv
go run go/regime_diagnostics_runner.go
rustc rust/nonlinear_regime_diagnostics_cli.rs -o outputs/nonlinear_regime_diagnostics_cli && ./outputs/nonlinear_regime_diagnostics_cli
julia julia/nonlinear_regime_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate nonlinear damage, thresholds, regime shifts, hysteresis, early-warning diagnostics, and reproducible workflow organization. They are not calibrated empirical models of any real climate, ecological, infrastructure, financial, health, public policy, organizational, or social system. Applied use requires domain data, structural review, validation evidence, justified threshold assumptions, uncertainty communication, stakeholder review, and boundary critique.
