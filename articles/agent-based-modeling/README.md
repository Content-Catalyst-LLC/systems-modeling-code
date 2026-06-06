# Agent-Based Modeling

Advanced companion code for the article **Agent-Based Modeling**.

GitHub folder:

```text
articles/agent-based-modeling/
```

This companion folder turns the article's ABM concepts into reproducible modeling workflows. It includes Schelling-style clustering, threshold adoption, heterogeneous-agent simulations, local interaction diagnostics, emergence measures, scenario comparisons, sensitivity checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level threshold-adoption simulation engine
cpp/        Scenario ensemble and sensitivity scanner
data/       Synthetic scenario parameters, agent-rule inventory, validation targets
docs/       Boundary notes, ODD-style notes, assumptions, validation, responsible use
fortran/    Threshold-adoption recurrence solver
go/         Agent-based scenario diagnostics runner
julia/      Threshold-adoption uncertainty ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library Schelling-style ABM workflow
r/          Base R threshold-adoption diagnostics and figures
rust/       Command-line ABM diagnostics scaffold
sql/        SQLite schema and analysis queries
```

## Professional modeling capabilities

- Heterogeneous agents
- Local interaction
- Spatial Schelling-style relocation
- Threshold-based adoption
- Network-neighborhood influence
- Emergent clustering diagnostics
- Adoption trajectory diagnostics
- Scenario comparison
- Sensitivity checks
- Synthetic validation targets
- ODD-style documentation notes
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
python3 python/agent_based_modeling_workflow.py
Rscript r/agent_based_modeling_diagnostics.R
sqlite3 outputs/tables/agent_based_modeling.sqlite < sql/agent_based_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/abm_threshold_engine.c -lm -o outputs/abm_threshold_engine && ./outputs/abm_threshold_engine > outputs/tables/c_abm_threshold_adoption.csv
g++ -std=c++17 cpp/abm_sensitivity_scanner.cpp -o outputs/abm_sensitivity_scanner && ./outputs/abm_sensitivity_scanner > outputs/tables/cpp_abm_sensitivity.csv
gfortran fortran/abm_threshold_solver.f90 -o outputs/abm_threshold_solver && ./outputs/abm_threshold_solver > outputs/tables/fortran_abm_threshold_adoption.csv
go run go/abm_scenario_runner.go
rustc rust/abm_diagnostics_cli.rs -o outputs/abm_diagnostics_cli && ./outputs/abm_diagnostics_cli
julia julia/abm_threshold_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate agent-based modeling structure, diagnostic design, and reproducible workflow organization. They are not calibrated empirical models of any real population, neighborhood, market, epidemic, or institution. Applied use requires domain data, calibration, validation, uncertainty communication, stakeholder review, privacy safeguards, and boundary critique.
