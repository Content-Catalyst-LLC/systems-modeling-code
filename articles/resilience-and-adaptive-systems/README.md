# Resilience and Adaptive Systems

Advanced companion code for the article **Resilience and Adaptive Systems**.

This folder translates resilience theory into reproducible systems-modeling workflows: repeated-shock simulations, adaptive-capacity dynamics, recovery-time diagnostics, performance-loss metrics, resilience design comparisons, validation checks, synthetic datasets, documentation, SQL schemas, and multi-language examples.

```text
articles/resilience-and-adaptive-systems/
```

## Contents

```text
c/          Repeated-shock resilience engine
cpp/        Resilience scenario scanner
data/       Taxonomies, scenarios, shock schedules, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Resilience recurrence solver
go/         Resilience diagnostics runner
julia/      Adaptive-capacity ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library resilience workflow
r/          Base R resilience diagnostics workflow
rust/       Command-line resilience diagnostics scaffold
sql/        SQLite schema and resilience analysis queries
```

## Quick start

```bash
./run_all.sh
```

Core workflows:

```bash
python3 python/resilience_adaptive_systems_workflow.py
Rscript r/resilience_adaptive_systems_diagnostics.R
sqlite3 outputs/tables/resilience_adaptive_systems.sqlite < sql/resilience_adaptive_systems_schema.sql
```

These workflows use synthetic data and are not calibrated to any real system. Applied use requires domain data, validation, uncertainty analysis, stakeholder review, and ethical interpretation.
