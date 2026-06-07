# Phase Transitions in Complex Systems

Advanced companion code for the article **Phase Transitions in Complex Systems**.

GitHub folder:

```text
articles/phase-transitions-in-complex-systems/
```

This companion folder turns phase-transition concepts into reproducible systems-modeling workflows. It includes bifurcation-style order-parameter simulations, threshold-driven phase-change diagnostics, network connectivity transitions, giant-component detection, critical-region summaries, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level bifurcation and network phase-transition examples
cpp/        Phase-transition scenario scanner
data/       Phase-transition concepts, scenarios, domain examples, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Bifurcation recurrence solver
go/         Network phase-transition diagnostics runner
julia/      Order-parameter and network transition ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library phase-transition workflow
r/          Base R bifurcation and order-parameter workflow
rust/       Command-line phase-transition diagnostics scaffold
sql/        SQLite schema and phase-transition analysis queries
```

## Professional modeling capabilities

- Order-parameter branch simulation
- Threshold-driven bifurcation diagnostics
- Network connectivity transition simulation
- Largest connected component tracking
- Giant component threshold approximation
- Control-parameter sweeps
- Hysteresis and recovery-threshold examples
- Domain examples for ecology, climate, infrastructure, finance, organizations, and social systems
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
python3 python/phase_transitions_workflow.py
Rscript r/phase_transition_bifurcation_diagnostics.R
sqlite3 outputs/tables/phase_transitions.sqlite < sql/phase_transitions_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/phase_transition_engine.c -lm -o outputs/phase_transition_engine && ./outputs/phase_transition_engine > outputs/tables/c_phase_transition_engine.csv
g++ -std=c++17 cpp/phase_transition_scenario_scanner.cpp -o outputs/phase_transition_scenario_scanner && ./outputs/phase_transition_scenario_scanner > outputs/tables/cpp_phase_transition_scenario_scanner.csv
gfortran fortran/phase_transition_recurrence_solver.f90 -o outputs/phase_transition_recurrence_solver && ./outputs/phase_transition_recurrence_solver > outputs/tables/fortran_phase_transition_recurrence.csv
go run go/phase_transition_diagnostics_runner.go
rustc rust/phase_transition_diagnostics_cli.rs -o outputs/phase_transition_diagnostics_cli && ./outputs/phase_transition_diagnostics_cli
julia julia/phase_transition_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate phase-transition concepts, order parameters, control parameters, bifurcation-style thresholds, network connectivity transitions, and reproducible workflow organization. They are not calibrated empirical models of any real physical, ecological, climate, infrastructure, financial, organizational, public policy, or social system. Applied use requires domain evidence, structural review, threshold uncertainty analysis, validation, stakeholder review, and responsible communication.
