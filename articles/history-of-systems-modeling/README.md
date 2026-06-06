# The History of Systems Modeling

Advanced companion code for the article **The History of Systems Modeling**.

GitHub folder:

```text
articles/history-of-systems-modeling/
```

This companion folder turns the article's historical argument into executable modeling workflows. It demonstrates how systems modeling evolved from simple growth representations toward feedback control, stock-flow dynamics, delayed regulation, nonlinear constraint, scenario comparison, sensitivity diagnostics, uncertainty ensembles, and reproducible multi-language simulation scaffolds.

## Contents

```text
c/          Low-level delayed-feedback historical dynamics engine
cpp/        Historical scenario ensemble and sensitivity scanner
data/       Synthetic historical-method scenarios, milestones, validation targets
docs/       Boundary notes, historical-method notes, validation, reproducibility, responsible use
fortran/    Stock-flow and delayed-feedback recurrence solver
go/         Historical scenario diagnostics runner
julia/      Historical model-structure uncertainty ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library historical dynamics workflow
r/          Base R historical modeling diagnostics
rust/       Command-line historical diagnostics scaffold
sql/        SQLite schema and historical-method analysis queries
```

## Professional modeling capabilities

- Exponential growth
- Logistic constraint
- Feedback-control regulation
- Stock-flow accumulation
- Delayed balancing feedback
- Overshoot and oscillation diagnostics
- Scenario comparison
- Sensitivity analysis
- Historical modeling-method inventory
- Validation against synthetic plausibility targets
- SQL model-run schema
- Portable Python and R workflows
- Multi-language implementation scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/history_of_systems_modeling_workflow.py
Rscript r/history_of_systems_modeling_diagnostics.R
sqlite3 outputs/tables/history_of_systems_modeling.sqlite < sql/history_of_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/historical_feedback_engine.c -lm -o outputs/historical_feedback_engine && ./outputs/historical_feedback_engine > outputs/tables/c_historical_feedback.csv
g++ -std=c++17 cpp/historical_scenario_sensitivity.cpp -o outputs/historical_scenario_sensitivity && ./outputs/historical_scenario_sensitivity > outputs/tables/cpp_historical_sensitivity.csv
gfortran fortran/historical_stock_flow_solver.f90 -o outputs/historical_stock_flow_solver && ./outputs/historical_stock_flow_solver > outputs/tables/fortran_historical_stock_flow.csv
go run go/historical_scenario_runner.go
rustc rust/historical_diagnostics_cli.rs -o outputs/historical_diagnostics_cli && ./outputs/historical_diagnostics_cli
julia julia/historical_model_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They are designed to demonstrate historical modeling structures and reproducible workflow design. They are not empirical reconstructions of historical models or calibrated models of real systems. Applied use requires domain data, calibration, validation, uncertainty communication, stakeholder review, and boundary critique.
