# Systems Thinking vs Systems Modeling

Advanced companion code for the article **Systems Thinking vs Systems Modeling**.

GitHub folder:

```text
articles/systems-thinking-vs-systems-modeling/
```

This companion folder demonstrates how conceptual systems thinking can be translated into formal systems modeling. It includes causal-structure translation, dynamic simulation, conceptual-model gap diagnostics, sensitivity analysis, scenario comparison, validation checks, SQL schemas, and multi-language implementation scaffolds.

## Contents

```text
c/          Low-level feedback translation engine
cpp/        Conceptual-model gap scanner
data/       Synthetic relationships, scenario parameters, validation targets
docs/       Boundary translation, assumptions, validation, reproducibility, responsible use
fortran/    Stock-flow translation solver
go/         Scenario comparison runner
julia/      Conceptual/formal gap ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library workflow
r/          Base R diagnostics and visualization workflow
rust/       Command-line gap diagnostic scaffold
sql/        SQLite schema and analysis queries
```

## Professional modeling capabilities

- Translation from conceptual systems maps to formal variables
- Dynamic state simulation
- Feedback, delay, backlog, rework, trust, capacity, and learning dynamics
- Conceptual score versus modeled score comparison
- Scenario diagnostics
- Sensitivity analysis
- Validation against synthetic plausibility targets
- Reproducible CSV outputs
- SQL schema for model runs, assumptions, outputs, and diagnostics
- Multi-language scaffolding for professional extension

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/systems_thinking_vs_modeling_workflow.py
Rscript r/systems_thinking_vs_modeling_diagnostics.R
sqlite3 outputs/tables/systems_thinking_vs_modeling.sqlite < sql/systems_thinking_vs_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/feedback_translation_engine.c -lm -o outputs/feedback_translation_engine && ./outputs/feedback_translation_engine > outputs/tables/c_feedback_translation.csv
g++ -std=c++17 cpp/conceptual_model_gap_scanner.cpp -o outputs/conceptual_model_gap_scanner && ./outputs/conceptual_model_gap_scanner > outputs/tables/cpp_gap_scanner.csv
gfortran fortran/stock_flow_translation_solver.f90 -o outputs/stock_flow_translation_solver && ./outputs/stock_flow_translation_solver > outputs/tables/fortran_stock_flow_translation.csv
go run go/scenario_comparison_runner.go
rustc rust/systems_modeling_gap_cli.rs -o outputs/systems_modeling_gap_cli && ./outputs/systems_modeling_gap_cli
julia julia/conceptual_formal_gap_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They are designed to demonstrate systems-modeling workflow structure, not to model a real empirical system. Applied use requires domain data, calibration, validation, stakeholder review, uncertainty communication, and ethical boundary critique.
