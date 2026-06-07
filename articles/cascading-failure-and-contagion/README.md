# Cascading Failure and Contagion

Advanced companion code for the article **Cascading Failure and Contagion**.

GitHub folder:

```text
articles/cascading-failure-and-contagion/
```

This companion folder turns cascade and contagion concepts into reproducible systems-modeling workflows. It includes random-network threshold cascades, targeted initial shocks, overload and capacity diagnostics, contagion scenarios, containment comparisons, propagation taxonomies, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level threshold-cascade engine
cpp/        Cascade scenario scanner
data/       Cascade mechanisms, scenarios, domain examples, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Threshold cascade recurrence solver
go/         Cascade diagnostics runner
julia/      Cascade and contagion ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library cascade workflow
r/          Base R threshold-cascade diagnostics workflow
rust/       Command-line cascade diagnostics scaffold
sql/        SQLite schema and cascade analysis queries
```

## Professional modeling capabilities

- Random network generation
- Targeted hub failure seeding
- Threshold contagion dynamics
- Cascade size and duration measurement
- New-failure trajectory tracking
- Network connectivity and degree diagnostics
- Overload, exposure, and containment examples
- Domain examples for infrastructure, finance, public health, supply chains, ecology, organizations, and social systems
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
python3 python/cascading_failure_contagion_workflow.py
Rscript r/cascading_failure_threshold_diagnostics.R
sqlite3 outputs/tables/cascading_failure_contagion.sqlite < sql/cascading_failure_contagion_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/cascade_threshold_engine.c -lm -o outputs/cascade_threshold_engine && ./outputs/cascade_threshold_engine > outputs/tables/c_cascade_threshold_engine.csv
g++ -std=c++17 cpp/cascade_scenario_scanner.cpp -o outputs/cascade_scenario_scanner && ./outputs/cascade_scenario_scanner > outputs/tables/cpp_cascade_scenario_scanner.csv
gfortran fortran/cascade_recurrence_solver.f90 -o outputs/cascade_recurrence_solver && ./outputs/cascade_recurrence_solver > outputs/tables/fortran_cascade_recurrence.csv
go run go/cascade_diagnostics_runner.go
rustc rust/cascade_diagnostics_cli.rs -o outputs/cascade_diagnostics_cli && ./outputs/cascade_diagnostics_cli
julia julia/cascade_contagion_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate cascade propagation, threshold contagion, network exposure, containment logic, and reproducible workflow organization. They are not calibrated empirical models of any real infrastructure, financial, ecological, public health, supply-chain, organizational, public policy, or social system. Applied use requires domain evidence, dependency mapping, threshold review, validation, sensitivity analysis, stakeholder review, and responsible communication.
