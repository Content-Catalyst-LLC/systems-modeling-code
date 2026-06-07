# Participatory Modeling and Stakeholder Systems

Advanced companion code for the article **Participatory Modeling and Stakeholder Systems**.

GitHub folder:

```text
articles/participatory-modeling-and-stakeholder-systems/
```

This companion folder turns participatory modeling concepts into reproducible workflows. It includes stakeholder mapping, outcome weighting, scenario scoring, assumption registers, disagreement diagnostics, legitimacy-adjusted rankings, facilitation and power-risk registers, evidence governance tables, validation checks, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level stakeholder scenario scoring engine
cpp/        Participatory scenario scanner
data/       Stakeholders, scenarios, assumptions, participation levels, governance, risks
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Stakeholder score recurrence example
go/         Participatory diagnostics runner
julia/      Stakeholder scenario ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library participatory modeling workflow
r/          Base R stakeholder scoring and consensus workflow
rust/       Command-line participatory diagnostics scaffold
sql/        SQLite schema and analysis queries
README.md
run_all.sh
```

## Professional modeling capabilities

- Stakeholder group definitions
- Outcome weighting across access, cost, resilience, equity, and feasibility
- Scenario performance comparison
- Stakeholder-specific scenario scoring
- Disagreement diagnostics
- Legitimacy-adjusted scenario rankings
- Assumption register
- Participation-level taxonomy
- Evidence and governance tables
- Power, facilitation, and representation risk registers
- Validation checks
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/participatory_modeling_workflow.py
Rscript r/participatory_modeling_workflow.R
sqlite3 outputs/tables/participatory_modeling.sqlite < sql/participatory_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/participatory_score_engine.c -lm -o outputs/participatory_score_engine && ./outputs/participatory_score_engine > outputs/tables/c_participatory_score_engine.csv
g++ -std=c++17 cpp/participatory_scenario_scanner.cpp -o outputs/participatory_scenario_scanner && ./outputs/participatory_scenario_scanner > outputs/tables/cpp_participatory_scenario_scanner.csv
gfortran fortran/participatory_score_solver.f90 -o outputs/participatory_score_solver && ./outputs/participatory_score_solver > outputs/tables/fortran_participatory_score_solver.csv
go run go/participatory_diagnostics_runner.go
rustc rust/participatory_diagnostics_cli.rs -o outputs/participatory_diagnostics_cli && ./outputs/participatory_diagnostics_cli
julia julia/participatory_scenario_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate participatory modeling patterns: stakeholder weights, scenario performance values, disagreement diagnostics, assumption registers, validation checks, and responsible-use documentation. They are not a substitute for real facilitation, community governance, stakeholder consent, power analysis, data rights, or public decision legitimacy. Applied use requires careful process design, inclusive participation, documentation of dissent, ethical review, data governance, and accountability for model use.
