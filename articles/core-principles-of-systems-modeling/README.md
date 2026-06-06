# Core Principles of Systems Modeling

Advanced companion code for the article **Core Principles of Systems Modeling**.

GitHub folder:

```text
articles/core-principles-of-systems-modeling/
```

This companion folder turns the article's principles into reproducible modeling workflows. It demonstrates abstraction, boundary setting, stocks, flows, feedback, delay, nonlinear thresholds, scenario comparison, sensitivity diagnostics, validation checks, and responsible model documentation.

## Contents

```text
c/          Low-level stock-flow feedback simulation engine
cpp/        Scenario ensemble and sensitivity scanner
data/       Synthetic scenario parameters, principle inventory, validation targets
docs/       Boundary notes, assumptions, validation protocol, responsible-use guidance
fortran/    Stock-flow and delayed-feedback solver
go/         Scenario diagnostics runner
julia/      Feedback-threshold ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library workflow
r/          Base R diagnostics and visualization workflow
rust/       Command-line systems-modeling diagnostics scaffold
sql/        SQLite schema and analysis queries
```

## Professional modeling capabilities

- Core-principle inventory
- Stock-flow accumulation
- Reinforcing feedback
- Delayed balancing feedback
- Nonlinear threshold correction
- Scenario comparison
- Sensitivity diagnostics
- Validation against synthetic target ranges
- SQL model-run schema
- Portable Python and R workflows
- Multi-language implementation scaffolds
- Responsible modeling documentation

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/core_principles_systems_modeling_workflow.py
Rscript r/core_principles_systems_modeling_diagnostics.R
sqlite3 outputs/tables/core_principles_systems_modeling.sqlite < sql/core_principles_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/core_principles_feedback_engine.c -lm -o outputs/core_principles_feedback_engine && ./outputs/core_principles_feedback_engine > outputs/tables/c_core_principles_feedback.csv
g++ -std=c++17 cpp/core_principles_sensitivity_scanner.cpp -o outputs/core_principles_sensitivity_scanner && ./outputs/core_principles_sensitivity_scanner > outputs/tables/cpp_core_principles_sensitivity.csv
gfortran fortran/core_principles_stock_flow_solver.f90 -o outputs/core_principles_stock_flow_solver && ./outputs/core_principles_stock_flow_solver > outputs/tables/fortran_core_principles_stock_flow.csv
go run go/core_principles_scenario_runner.go
rustc rust/core_principles_diagnostics_cli.rs -o outputs/core_principles_diagnostics_cli && ./outputs/core_principles_diagnostics_cli
julia julia/core_principles_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate systems-modeling structure, not empirical claims about a real system. Applied use requires domain data, calibration, validation, uncertainty communication, stakeholder review, and boundary critique.
