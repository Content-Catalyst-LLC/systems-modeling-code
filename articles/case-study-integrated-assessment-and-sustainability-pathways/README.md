# Case Study: Integrated Assessment and Sustainability Pathways

Companion code for the article **Case Study: Integrated Assessment and Sustainability Pathways**.

GitHub folder:

```text
articles/case-study-integrated-assessment-and-sustainability-pathways/
```

This companion folder demonstrates a simplified integrated assessment and sustainability pathways workflow connecting energy demand, clean energy transition, emissions, cumulative emissions, climate stress, adaptation capacity, climate damages, transition cost, land pressure, water stress, equity score, constraint breaches, and sustainability scoring.

## Contents

```text
c/          C pathway summary engine
cpp/        C++ sustainability pathway scanner
data/       Pathway assumptions, model assumptions, diagnostics, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Fortran pathway summary solver
go/         Go integrated assessment runner
julia/      Julia pathway summary ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Standard-library integrated assessment workflow
r/          Base R integrated assessment workflow
rust/       Rust pathway diagnostics CLI
sql/        SQLite schema and pathway review queries
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
python3 python/integrated_assessment_sustainability_pathways_workflow.py
Rscript r/integrated_assessment_sustainability_pathways_workflow.R
sqlite3 outputs/tables/integrated_assessment_sustainability_pathways.sqlite < sql/integrated_assessment_sustainability_pathways_schema.sql
```

Optional compiled examples run automatically when compilers/interpreters are installed.

## Interpretation warning

All data are synthetic. This is a learning scaffold for integrated assessment reasoning, not a validated climate, energy, land, water, economic, or equity model. Real decision use requires domain evidence, scenario review, stakeholder review, calibration, uncertainty analysis, legal and institutional review, and responsible public communication.
