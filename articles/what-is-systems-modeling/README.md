# What Is Systems Modeling?

Advanced companion code for the article **What Is Systems Modeling?**

GitHub folder:

```text
articles/what-is-systems-modeling/
```

This folder provides a professional multi-language scaffold for applied systems modeling. It includes dynamic simulation, stock-and-flow recurrence models, network shock propagation, scenario ensembles, sensitivity analysis, validation diagnostics, database schemas, reproducible outputs, and responsible-use documentation.

## Contents

```text
c/          Low-level stock-flow simulation engine
cpp/        Scenario ensemble and sensitivity scanner
data/       Synthetic dependency networks, parameters, scenarios, validation targets
docs/       Boundary, assumptions, validation, reproducibility, responsible-use notes
fortran/    Coupled stock recurrence solver
go/         Scenario batch runner
julia/      Nonlinear feedback and uncertainty ensemble models
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library modeling workflow
r/          Base R stock-flow uncertainty and sensitivity workflows
rust/       Diagnostic command-line model runner
sql/        SQLite schemas and analysis queries
```

## Professional modeling capabilities

- Stock-flow accumulation and depletion
- Reinforcing and balancing feedback
- Nonlinear response and pressure feedback
- Network dependency and shock propagation
- Recovery, redundancy, and cascading vulnerability diagnostics
- Scenario comparison
- Monte Carlo uncertainty analysis
- One-at-a-time sensitivity analysis
- Validation checks against target ranges
- Reproducible CSV outputs
- SQL schema for model runs, parameters, outputs, and diagnostics
- Multi-language implementations for professional extension

## Quick start

From this article folder:

```bash
./run_all.sh
```

Or run individual workflows:

```bash
python3 python/systems_modeling_professional_workflow.py
Rscript r/stock_flow_uncertainty_workflow.R
sqlite3 outputs/tables/systems_modeling.sqlite < sql/systems_modeling_schema_and_queries.sql
```

Optional compiled workflows:

```bash
gcc c/stock_flow_engine.c -lm -o outputs/stock_flow_engine && ./outputs/stock_flow_engine > outputs/tables/c_stock_flow_output.csv
g++ -std=c++17 cpp/scenario_ensemble_sensitivity.cpp -o outputs/scenario_ensemble_sensitivity && ./outputs/scenario_ensemble_sensitivity > outputs/tables/cpp_scenario_ensemble.csv
gfortran fortran/coupled_stock_solver.f90 -o outputs/coupled_stock_solver && ./outputs/coupled_stock_solver > outputs/tables/fortran_coupled_stock_output.csv
go run go/network_batch_runner.go
rustc rust/systems_model_cli.rs -o outputs/systems_model_cli && ./outputs/systems_model_cli
julia julia/nonlinear_feedback_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate modeling structure, reproducibility, diagnostics, and professional code organization. They are not calibrated empirical models of any real-world system. Any applied use requires domain data, calibration, validation, stakeholder review, uncertainty communication, and ethical boundary critique.
