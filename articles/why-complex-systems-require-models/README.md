# Why Complex Systems Require Models

Advanced companion code for the article **Why Complex Systems Require Models**.

GitHub folder:

```text
articles/why-complex-systems-require-models/
```

This companion folder demonstrates why complex systems require formal models. It includes delayed-feedback simulations, nonlinear threshold models, scenario comparison workflows, sensitivity diagnostics, validation checks, synthetic datasets, SQL schemas, documentation assets, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level delayed-feedback simulation engine
cpp/        Scenario ensemble and sensitivity scanner
data/       Synthetic scenario parameters, validation targets, and model assumptions
docs/       Boundary notes, assumptions, validation protocol, responsible-use guidance
fortran/    Delayed-feedback recurrence solver
go/         Scenario comparison runner
julia/      Nonlinear threshold ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library workflow
r/          Base R delayed-feedback diagnostics
rust/       Command-line threshold diagnostic scaffold
sql/        SQLite schema and analysis queries
```

## Professional modeling capabilities

- Reinforcing feedback
- Delayed balancing feedback
- Threshold-sensitive correction
- Nonlinear transition dynamics
- Shock response
- Scenario comparison
- Sensitivity diagnostics
- Validation against synthetic plausibility targets
- Reproducible CSV outputs
- Portable Python and R workflows
- SQL model-run schema
- Multi-language implementation scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/why_complex_systems_require_models_workflow.py
Rscript r/why_complex_systems_require_models_diagnostics.R
sqlite3 outputs/tables/why_complex_systems_require_models.sqlite < sql/why_complex_systems_require_models_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/delayed_feedback_engine.c -lm -o outputs/delayed_feedback_engine && ./outputs/delayed_feedback_engine > outputs/tables/c_delayed_feedback.csv
g++ -std=c++17 cpp/scenario_threshold_sensitivity.cpp -o outputs/scenario_threshold_sensitivity && ./outputs/scenario_threshold_sensitivity > outputs/tables/cpp_threshold_sensitivity.csv
gfortran fortran/delayed_feedback_solver.f90 -o outputs/delayed_feedback_solver && ./outputs/delayed_feedback_solver > outputs/tables/fortran_delayed_feedback.csv
go run go/scenario_diagnostics_runner.go
rustc rust/threshold_diagnostics_cli.rs -o outputs/threshold_diagnostics_cli && ./outputs/threshold_diagnostics_cli
julia julia/nonlinear_threshold_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate modeling structure, diagnostic design, and reproducible workflow organization. They are not calibrated empirical models of any real system. Applied use requires domain data, calibration, validation, uncertainty communication, stakeholder review, and boundary critique.
