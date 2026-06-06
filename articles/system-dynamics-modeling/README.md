# System Dynamics Modeling

Advanced companion code for the article **System Dynamics Modeling**.

GitHub folder:

```text
articles/system-dynamics-modeling/
```

This companion folder turns the article's system dynamics concepts into reproducible modeling workflows. It includes stock-flow simulations, causal-loop translation examples, delayed-feedback models, overshoot and correction workflows, scenario comparisons, sensitivity diagnostics, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level stock-flow delayed-feedback engine
cpp/        Scenario ensemble and sensitivity scanner
data/       Synthetic scenario parameters, loop inventory, validation targets
docs/       Boundary notes, assumptions, validation protocol, responsible-use guidance
fortran/    Stock-flow and delayed-feedback recurrence solver
go/         Scenario diagnostics runner
julia/      System dynamics uncertainty ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library system dynamics workflow
r/          Base R stock-flow diagnostics and figures
rust/       Command-line system dynamics diagnostics scaffold
sql/        SQLite schema and analysis queries
```

## Professional modeling capabilities

- Stock-flow accumulation
- Reinforcing inflow
- Delayed balancing outflow
- Capacity-limited nonlinear growth
- Threshold-sensitive correction
- Shock response
- Causal-loop to stock-flow translation notes
- Scenario comparison
- Sensitivity diagnostics
- Validation against synthetic target ranges
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
python3 python/system_dynamics_modeling_workflow.py
Rscript r/system_dynamics_modeling_diagnostics.R
sqlite3 outputs/tables/system_dynamics_modeling.sqlite < sql/system_dynamics_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/system_dynamics_feedback_engine.c -lm -o outputs/system_dynamics_feedback_engine && ./outputs/system_dynamics_feedback_engine > outputs/tables/c_system_dynamics_feedback.csv
g++ -std=c++17 cpp/system_dynamics_sensitivity_scanner.cpp -o outputs/system_dynamics_sensitivity_scanner && ./outputs/system_dynamics_sensitivity_scanner > outputs/tables/cpp_system_dynamics_sensitivity.csv
gfortran fortran/system_dynamics_stock_flow_solver.f90 -o outputs/system_dynamics_stock_flow_solver && ./outputs/system_dynamics_stock_flow_solver > outputs/tables/fortran_system_dynamics_stock_flow.csv
go run go/system_dynamics_scenario_runner.go
rustc rust/system_dynamics_diagnostics_cli.rs -o outputs/system_dynamics_diagnostics_cli && ./outputs/system_dynamics_diagnostics_cli
julia julia/system_dynamics_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate system dynamics structure, diagnostic design, and reproducible workflow organization. They are not calibrated empirical models of any real system. Applied use requires domain data, calibration, validation, uncertainty communication, stakeholder review, and boundary critique.
