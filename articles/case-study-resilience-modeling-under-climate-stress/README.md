# Case Study: Resilience Modeling Under Climate Stress

Companion code for the article **Case Study: Resilience Modeling Under Climate Stress**.

GitHub folder:

```text
articles/case-study-resilience-modeling-under-climate-stress/
```

This companion folder demonstrates climate resilience modeling through climate stress trajectories, exposure, sensitivity, adaptive capacity, recovery, degradation, thresholds, adaptation investment, transformation triggers, resilience diagnostics, scenario comparison, and validation checks.

## Contents

```text
c/          C resilience summary engine
cpp/        C++ climate resilience scenario scanner
data/       Climate scenarios, assumptions, diagnostics, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Fortran resilience summary solver
go/         Go climate resilience runner
julia/      Julia resilience summary ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Standard-library resilience workflow
r/          Base R climate resilience workflow
rust/       Rust resilience diagnostics CLI
sql/        SQLite schema and scenario review queries
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
python3 python/climate_resilience_scenario_workflow.py
Rscript r/climate_resilience_scenario_workflow.R
sqlite3 outputs/tables/climate_resilience_scenario_model.sqlite < sql/climate_resilience_scenario_schema.sql
```

Optional compiled examples run automatically when compilers/interpreters are installed.

## Interpretation warning

All data are synthetic. This is a learning scaffold for climate resilience reasoning, not a validated climate adaptation model. Real decision use requires local hazard evidence, service data, social vulnerability assessment, stakeholder review, uncertainty analysis, legal and institutional review, and responsible public communication.
