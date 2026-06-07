# Geospatial Systems Modeling

Advanced companion code for the article **Geospatial Systems Modeling**.

GitHub folder:

```text
articles/geospatial-systems-modeling/
```

This companion folder turns geospatial systems modeling concepts into reproducible workflows. It includes synthetic grid generation, exposure modeling, hazard and vulnerability surfaces, service accessibility scoring, spatial priority-zone classification, network-style distance logic, geospatial uncertainty registers, spatial ethics and governance tables, validation checks, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level grid risk and accessibility engine
cpp/        Spatial priority scenario scanner
data/       Spatial components, data structures, risks, governance, scenarios, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Grid recurrence and risk scoring example
go/         Geospatial diagnostics runner
julia/      Grid exposure and access ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library geospatial systems workflow
r/          Base R grid-based exposure and accessibility workflow
rust/       Command-line geospatial diagnostics scaffold
sql/        SQLite schema and spatial analysis queries
README.md
run_all.sh
```

## Professional modeling capabilities

- Synthetic spatial grid generation
- Hazard, population, vulnerability, and exposure surfaces
- Distance-based service accessibility
- Service-gap scoring
- Spatial priority-zone classification
- Scenario comparison across baseline, higher hazard, low access, high vulnerability, and resilient service placement cases
- Spatial data structure, scale, uncertainty, ethics, and governance taxonomies
- Validation checks
- SQL schema for geospatial systems modeling metadata
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/geospatial_systems_modeling_workflow.py
Rscript r/geospatial_systems_modeling_workflow.R
sqlite3 outputs/tables/geospatial_systems_modeling.sqlite < sql/geospatial_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/geospatial_grid_engine.c -lm -o outputs/geospatial_grid_engine && ./outputs/geospatial_grid_engine > outputs/tables/c_geospatial_grid_engine.csv
g++ -std=c++17 cpp/geospatial_priority_scanner.cpp -o outputs/geospatial_priority_scanner && ./outputs/geospatial_priority_scanner > outputs/tables/cpp_geospatial_priority_scanner.csv
gfortran fortran/geospatial_grid_solver.f90 -o outputs/geospatial_grid_solver && ./outputs/geospatial_grid_solver > outputs/tables/fortran_geospatial_grid_solver.csv
go run go/geospatial_diagnostics_runner.go
rustc rust/geospatial_diagnostics_cli.rs -o outputs/geospatial_diagnostics_cli && ./outputs/geospatial_diagnostics_cli
julia julia/geospatial_grid_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate geospatial systems modeling patterns: grid cells, hazard surfaces, population exposure, vulnerability, service access, distance decay, priority-zone classification, validation checks, and responsible-use documentation. They are not calibrated models of any real city, watershed, infrastructure network, health system, climate-risk zone, environmental justice burden, or service geography. Applied use requires real coordinate systems, geospatial metadata, spatial joins, projection management, data governance, privacy review, uncertainty analysis, validation, local knowledge, and responsible communication.
