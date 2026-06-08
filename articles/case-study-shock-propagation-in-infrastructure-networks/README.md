# Case Study: Shock Propagation in Infrastructure Networks

Companion code for the article **Case Study: Shock Propagation in Infrastructure Networks**.

GitHub folder:

```text
articles/case-study-shock-propagation-in-infrastructure-networks/
```

This companion folder demonstrates how a small infrastructure network can be modeled as nodes, edges, dependencies, load, capacity, criticality, shock scenarios, cascading failure rules, and recovery diagnostics.

## Contents

```text
c/          C cascade summary engine
cpp/        C++ infrastructure scenario scanner
data/       Synthetic nodes, edges, scenarios, assumptions, diagnostics, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Fortran cascade summary solver
go/         Go shock propagation runner
julia/      Julia cascade ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Standard-library cascade workflow
r/          Base R shock propagation workflow
rust/       Rust cascade diagnostics CLI
sql/        SQLite schema and network review queries
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
python3 python/infrastructure_shock_propagation_workflow.py
Rscript r/infrastructure_shock_propagation_workflow.R
sqlite3 outputs/tables/infrastructure_shock_propagation.sqlite < sql/infrastructure_shock_propagation_schema.sql
```

Optional compiled examples run automatically when compilers/interpreters are installed.

## Interpretation warning

All data are synthetic. This is a learning scaffold for infrastructure network reasoning, not a validated operational model. Real decision use requires engineering detail, outage records, dependency mapping, geospatial exposure, stakeholder review, uncertainty analysis, and responsible communication.
