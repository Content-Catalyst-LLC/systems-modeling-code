# Case Study: Stock-and-Flow Modeling of Resource Depletion

Companion code for the article **Case Study: Stock-and-Flow Modeling of Resource Depletion**.

GitHub folder:

```text
articles/case-study-stock-and-flow-modeling-of-resource-depletion/
```

This project demonstrates how a small, transparent stock-and-flow model can represent resource depletion as the interaction of a stock, regeneration inflow, extraction outflow, demand growth, scarcity feedback, conservation response, threshold risk, and scenario uncertainty.

## Contents

```text
c/          C depletion summary engine
cpp/        C++ scenario scanner
data/       Scenario parameters, assumptions, diagnostics, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Fortran stock-and-flow scenario solver
go/         Go depletion diagnostics runner
julia/      Julia scenario ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Standard-library stock-and-flow workflow
r/          Base R scenario simulation workflow
rust/       Rust depletion diagnostics CLI
sql/        SQLite schema and scenario queries
README.md
run_all.sh
```

## Quick start

From this folder:

```bash
./run_all.sh
```

Core workflows:

```bash
python3 python/stock_flow_resource_depletion_workflow.py
Rscript r/stock_flow_resource_depletion_workflow.R
sqlite3 outputs/tables/resource_depletion.sqlite < sql/resource_depletion_schema.sql
```

Optional compiled examples run automatically when compilers/interpreters are installed.

## Interpretation warning

All data are synthetic. This is a learning scaffold for stock-and-flow reasoning, not a validated resource-management model. Real decision use requires domain data, stakeholder review, calibration, uncertainty analysis, institutional context, and responsible communication.
