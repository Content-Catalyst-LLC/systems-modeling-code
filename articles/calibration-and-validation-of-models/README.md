# Calibration and Validation of Models

Advanced companion code for the article **Calibration and Validation of Models**.

GitHub folder:

```text
articles/calibration-and-validation-of-models/
```

This companion folder turns calibration and validation concepts into reproducible analytical workflows. It includes parameter calibration, out-of-sample validation, train-validation splits, error metrics, residual diagnostics, structural validation scaffolds, benchmark comparison, overfitting checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level calibration trajectory engine
cpp/        Grid-search calibration scanner and validation evaluator
data/       Calibration settings, validation targets, structural checks
docs/       Calibration protocol, validation protocol, credibility notes
fortran/    Dynamic model recurrence and validation-error solver
go/         Calibration and validation diagnostics runner
julia/      Calibration uncertainty ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library calibration and validation workflow
r/          Base R parameter calibration and out-of-sample validation workflow
rust/       Command-line calibration diagnostics scaffold
sql/        SQLite schema and validation-analysis queries
```

## Professional modeling capabilities

- Synthetic observed-data generation
- Parameter calibration
- Grid-search fitting
- Out-of-sample validation
- Calibration-versus-validation error comparison
- Generalization-gap diagnostics
- Residual diagnostics
- Parameter plausibility checks
- Benchmark model comparison
- Structural validation inventory
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
python3 python/calibration_validation_workflow.py
Rscript r/calibration_validation_diagnostics.R
sqlite3 outputs/tables/calibration_validation.sqlite < sql/calibration_validation_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/calibration_trajectory_engine.c -lm -o outputs/calibration_trajectory_engine && ./outputs/calibration_trajectory_engine > outputs/tables/c_calibration_trajectory.csv
g++ -std=c++17 cpp/calibration_grid_search.cpp -o outputs/calibration_grid_search && ./outputs/calibration_grid_search > outputs/tables/cpp_calibration_grid_search.csv
gfortran fortran/calibration_validation_solver.f90 -o outputs/calibration_validation_solver && ./outputs/calibration_validation_solver > outputs/tables/fortran_calibration_validation.csv
go run go/calibration_validation_runner.go
rustc rust/calibration_validation_cli.rs -o outputs/calibration_validation_cli && ./outputs/calibration_validation_cli
julia julia/calibration_uncertainty_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate calibration, validation, out-of-sample testing, error diagnostics, benchmark comparison, and reproducible workflow organization. They are not calibrated empirical models of any real climate, infrastructure, economic, health, ecological, organizational, or policy system. Applied use requires domain data, validation evidence, structural review, uncertainty communication, sensitivity analysis, stakeholder review, and boundary critique.
