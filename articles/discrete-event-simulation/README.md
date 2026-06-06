# Discrete Event Simulation

Advanced companion code for the article **Discrete Event Simulation**.

GitHub folder:

```text
articles/discrete-event-simulation/
```

This companion folder turns the article's DES concepts into reproducible modeling workflows. It includes event-calendar simulations, stochastic queue models, resource-utilization diagnostics, bottleneck experiments, service-level analysis, replication logic, scenario comparison, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level event-driven queue engine
cpp/        Scenario ensemble and utilization sensitivity scanner
data/       Synthetic scenarios, process routes, resources, validation targets
docs/       Boundary notes, event-calendar design, validation, responsible use
fortran/    Single-server queue recurrence solver
go/         DES scenario diagnostics runner
julia/      Queueing and service-level uncertainty ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library event-calendar DES workflow
r/          Base R stochastic queue diagnostics and figures
rust/       Command-line DES diagnostics scaffold
sql/        SQLite schema and analysis queries
```

## Professional modeling capabilities

- Future-event-list simulation
- Next-event time advance
- Stochastic interarrival and service times
- Single-server and multi-server queue scenarios
- Resource seizure and release
- Queue-pressure diagnostics
- Waiting-time and time-in-system metrics
- Utilization and service-level analysis
- Scenario comparison
- Replication-ready workflow design
- Synthetic validation checks
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
python3 python/discrete_event_simulation_workflow.py
Rscript r/discrete_event_simulation_diagnostics.R
sqlite3 outputs/tables/discrete_event_simulation.sqlite < sql/discrete_event_simulation_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/des_queue_engine.c -lm -o outputs/des_queue_engine && ./outputs/des_queue_engine > outputs/tables/c_des_queue_trace.csv
g++ -std=c++17 cpp/des_sensitivity_scanner.cpp -o outputs/des_sensitivity_scanner && ./outputs/des_sensitivity_scanner > outputs/tables/cpp_des_sensitivity.csv
gfortran fortran/des_queue_solver.f90 -o outputs/des_queue_solver && ./outputs/des_queue_solver > outputs/tables/fortran_des_queue.csv
go run go/des_scenario_runner.go
rustc rust/des_diagnostics_cli.rs -o outputs/des_diagnostics_cli && ./outputs/des_diagnostics_cli
julia julia/des_queue_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate discrete event simulation structure, diagnostic design, and reproducible workflow organization. They are not calibrated empirical models of any real hospital, port, warehouse, factory, call center, maintenance system, or infrastructure operation. Applied use requires timestamped data, process validation, resource validation, uncertainty communication, stakeholder review, equity analysis, and boundary critique.
