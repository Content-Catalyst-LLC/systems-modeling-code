# Sensitivity Analysis in Systems Models

Advanced companion code for the article **Sensitivity Analysis in Systems Models**.

GitHub folder:

```text
articles/sensitivity-analysis-in-systems-models/
```

This companion folder turns the article's sensitivity-analysis concepts into reproducible analytical workflows. It includes local and global sensitivity workflows, Monte Carlo and stratified sampling, parameter screening, rank-based diagnostics, robustness checks, uncertainty propagation, structural-variant inventories, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level nonlinear sensitivity recurrence engine
cpp/        Parameter-screening and ensemble sensitivity scanner
data/       Parameter ranges, structural variants, validation targets
docs/       Boundary notes, sampling design, validation, responsible use
fortran/    Nonlinear sensitivity recurrence solver
go/         Global sensitivity diagnostics runner
julia/      Sensitivity uncertainty ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library sensitivity workflow
r/          Base R local and global sensitivity workflow
rust/       Command-line sensitivity diagnostics scaffold
sql/        SQLite schema and sensitivity-analysis queries
```

## Professional modeling capabilities

- Local one-at-a-time sensitivity
- Monte Carlo global sensitivity
- Latin-hypercube-style stratified sampling
- Rank-based sensitivity diagnostics
- Parameter screening
- Structural-variant inventory
- Robustness checks
- Uncertainty propagation
- Validation checks
- Synthetic model-run metadata
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
python3 python/sensitivity_analysis_workflow.py
Rscript r/sensitivity_analysis_diagnostics.R
sqlite3 outputs/tables/sensitivity_analysis.sqlite < sql/sensitivity_analysis_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/sensitivity_recurrence_engine.c -lm -o outputs/sensitivity_recurrence_engine && ./outputs/sensitivity_recurrence_engine > outputs/tables/c_sensitivity_recurrence.csv
g++ -std=c++17 cpp/sensitivity_screening_scanner.cpp -o outputs/sensitivity_screening_scanner && ./outputs/sensitivity_screening_scanner > outputs/tables/cpp_sensitivity_screening.csv
gfortran fortran/sensitivity_recurrence_solver.f90 -o outputs/sensitivity_recurrence_solver && ./outputs/sensitivity_recurrence_solver > outputs/tables/fortran_sensitivity_recurrence.csv
go run go/sensitivity_diagnostics_runner.go
rustc rust/sensitivity_diagnostics_cli.rs -o outputs/sensitivity_diagnostics_cli && ./outputs/sensitivity_diagnostics_cli
julia julia/sensitivity_uncertainty_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate sensitivity-analysis structure, uncertainty propagation, robustness diagnostics, and reproducible workflow organization. They are not calibrated empirical models of any real climate, infrastructure, economic, health, environmental, or policy system. Applied use requires domain data, justified parameter ranges, scenario validation, uncertainty communication, sensitivity-method selection, stakeholder review, and boundary critique.
