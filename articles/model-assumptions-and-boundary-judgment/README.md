# Model Assumptions and Boundary Judgment

Advanced companion code for the article **Model Assumptions and Boundary Judgment**.

GitHub folder:

```text
articles/model-assumptions-and-boundary-judgment/
```

This companion folder turns assumption discipline and boundary critique into reproducible systems-modeling workflows. It includes assumption registers, assumption risk scoring, boundary scenario comparison, sensitivity-style diagnostics, exclusion logs, validation checks, evidence grading, boundary critique tables, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level assumption risk scoring engine
cpp/        Boundary scenario comparison scanner
data/       Assumptions, boundary scenarios, exclusion logs, evidence grades, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Assumption risk solver
go/         Boundary diagnostics runner
julia/      Assumption and boundary ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library assumption and boundary workflow
r/          Base R assumption sensitivity and boundary comparison workflow
rust/       Command-line boundary diagnostics scaffold
sql/        SQLite schema and assumption analysis queries
README.md
run_all.sh
```

## Professional modeling capabilities

- Assumption register generation
- Assumption risk scoring with uncertainty, sensitivity, and consequence
- Boundary scenario comparison
- Assumption category summaries
- Exclusion log and boundary critique tables
- Evidence strength grading
- Validation checks
- SQL model documentation schema
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/model_assumptions_boundary_judgment_workflow.py
Rscript r/model_assumptions_boundary_judgment_workflow.R
sqlite3 outputs/tables/model_assumptions_boundary_judgment.sqlite < sql/model_assumptions_boundary_judgment_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/assumption_risk_engine.c -lm -o outputs/assumption_risk_engine && ./outputs/assumption_risk_engine > outputs/tables/c_assumption_risk_engine.csv
g++ -std=c++17 cpp/boundary_scenario_scanner.cpp -o outputs/boundary_scenario_scanner && ./outputs/boundary_scenario_scanner > outputs/tables/cpp_boundary_scenario_scanner.csv
gfortran fortran/assumption_risk_solver.f90 -o outputs/assumption_risk_solver && ./outputs/assumption_risk_solver > outputs/tables/fortran_assumption_risk_solver.csv
go run go/boundary_diagnostics_runner.go
rustc rust/boundary_diagnostics_cli.rs -o outputs/boundary_diagnostics_cli && ./outputs/boundary_diagnostics_cli
julia julia/assumption_boundary_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate assumption documentation, boundary comparison, sensitivity-style thinking, exclusion logging, evidence grading, and validation patterns. They are not a substitute for real model validation, stakeholder review, domain expertise, boundary critique, uncertainty quantification, or responsible decision governance.
