# Stocks, Flows, and Accumulation

Advanced companion code for the article **Stocks, Flows, and Accumulation**.

GitHub folder:

```text
articles/stocks-flows-and-accumulation/
```

This companion folder turns stock-flow concepts into reproducible systems-modeling workflows. It includes backlog accumulation, regenerative resource dynamics, infrastructure condition, maintenance backlogs, delayed response, capacity limits, nonlinear flows, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level stock-flow simulation engine
cpp/        Stock-flow scenario scanner
data/       Stock-flow taxonomy, scenario definitions, parameters, validation targets
docs/       Stock-flow modeling protocol, assumptions, validation, responsible use
fortran/    Stock-flow recurrence solver
go/         Stock-flow diagnostics runner
julia/      Accumulation scenario ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library stock-flow modeling workflow
r/          Base R accumulation diagnostics workflow
rust/       Command-line stock-flow diagnostics scaffold
sql/        SQLite schema and stock-flow analysis queries
```

## Professional modeling capabilities

- Stock-flow taxonomy inventory
- Backlog accumulation simulation
- Resource depletion and regeneration modeling
- Infrastructure condition and maintenance modeling
- Delayed response comparison
- Capacity and conservation scenarios
- Nonlinear flow and threshold diagnostics
- Net-flow summary metrics
- Recovery-time diagnostics
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
python3 python/stock_flow_accumulation_workflow.py
Rscript r/stock_flow_accumulation_diagnostics.R
sqlite3 outputs/tables/stock_flow_accumulation.sqlite < sql/stock_flow_accumulation_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/stock_flow_engine.c -lm -o outputs/stock_flow_engine && ./outputs/stock_flow_engine > outputs/tables/c_stock_flow_engine.csv
g++ -std=c++17 cpp/stock_flow_scenario_scanner.cpp -o outputs/stock_flow_scenario_scanner && ./outputs/stock_flow_scenario_scanner > outputs/tables/cpp_stock_flow_scenario_scanner.csv
gfortran fortran/stock_flow_recurrence_solver.f90 -o outputs/stock_flow_recurrence_solver && ./outputs/stock_flow_recurrence_solver > outputs/tables/fortran_stock_flow_recurrence.csv
go run go/stock_flow_diagnostics_runner.go
rustc rust/stock_flow_diagnostics_cli.rs -o outputs/stock_flow_diagnostics_cli && ./outputs/stock_flow_diagnostics_cli
julia julia/stock_flow_accumulation_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate stock-flow structure, accumulation, depletion, regeneration, backlog dynamics, delayed response, infrastructure condition, net-flow diagnostics, and reproducible workflow organization. They are not calibrated empirical models of any real climate, infrastructure, economic, health, environmental, organizational, or policy system. Applied use requires domain data, structural review, validation evidence, justified stock-flow assumptions, uncertainty communication, stakeholder review, and boundary critique.
