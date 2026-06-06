# Hybrid Modeling Approaches

Advanced companion code for the article **Hybrid Modeling Approaches**.

GitHub folder:

```text
articles/hybrid-modeling-approaches/
```

This companion folder turns the article's hybrid modeling concepts into reproducible analytical workflows. It includes coupled system dynamics and agent-based workflows, hybrid agent-queue simulations, network-interface scaffolds, cross-scale feedback examples, synchronization diagnostics, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level hybrid agent-queue feedback engine
cpp/        Coupling sensitivity scanner and scenario ensemble
data/       Synthetic coupling scenarios, module registry, interface inventory
docs/       Architecture notes, synchronization rules, validation, responsible use
fortran/    Coupled aggregate-adoption recurrence solver
go/         Hybrid scenario diagnostics runner
julia/      Coupling uncertainty ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library hybrid agent-queue workflow
r/          Base R aggregate-agent feedback workflow
rust/       Command-line hybrid diagnostics scaffold
sql/        SQLite schema and analysis queries
```

## Professional modeling capabilities

- Cross-scale coupling
- Aggregate-agent feedback
- Agent demand and queue pressure feedback
- Module interface design
- Synchronization diagnostics
- Coupling-frequency assumptions
- Scenario comparison
- Sensitivity checks
- Validation checks
- Synthetic datasets
- Architecture documentation
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
python3 python/hybrid_modeling_workflow.py
Rscript r/hybrid_modeling_diagnostics.R
sqlite3 outputs/tables/hybrid_modeling.sqlite < sql/hybrid_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/hybrid_agent_queue_engine.c -lm -o outputs/hybrid_agent_queue_engine && ./outputs/hybrid_agent_queue_engine > outputs/tables/c_hybrid_agent_queue.csv
g++ -std=c++17 cpp/hybrid_coupling_sensitivity.cpp -o outputs/hybrid_coupling_sensitivity && ./outputs/hybrid_coupling_sensitivity > outputs/tables/cpp_hybrid_coupling_sensitivity.csv
gfortran fortran/hybrid_feedback_solver.f90 -o outputs/hybrid_feedback_solver && ./outputs/hybrid_feedback_solver > outputs/tables/fortran_hybrid_feedback.csv
go run go/hybrid_scenario_runner.go
rustc rust/hybrid_diagnostics_cli.rs -o outputs/hybrid_diagnostics_cli && ./outputs/hybrid_diagnostics_cli
julia julia/hybrid_coupling_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate hybrid model architecture, coupling logic, synchronization, validation, and reproducible workflow organization. They are not calibrated empirical models of any real energy transition, infrastructure system, health system, supply chain, public policy system, or sustainability transition. Applied use requires domain data, module-level validation, interface validation, uncertainty propagation, stakeholder review, and boundary critique.
