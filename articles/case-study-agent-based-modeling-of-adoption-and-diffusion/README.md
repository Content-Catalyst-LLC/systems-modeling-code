# Case Study: Agent-Based Modeling of Adoption and Diffusion

Companion code for the article **Case Study: Agent-Based Modeling of Adoption and Diffusion**.

GitHub folder:

```text
articles/case-study-agent-based-modeling-of-adoption-and-diffusion/
```

This companion folder demonstrates how an agent-based model can represent adoption and diffusion through heterogeneous agents, social networks, thresholds, peer influence, cost barriers, trust, resistance, seed adopters, intervention strategies, diffusion diagnostics, scenario comparison, and validation checks.

## Contents

```text
c/          C diffusion summary engine
cpp/        C++ adoption scenario scanner
data/       Scenario parameters, agent-group assumptions, diagnostics, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Fortran diffusion summary solver
go/         Go adoption diagnostics runner
julia/      Julia diffusion summary ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Standard-library agent-based diffusion workflow
r/          Base R agent-based diffusion workflow
rust/       Rust diffusion diagnostics CLI
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
python3 python/agent_based_adoption_diffusion_workflow.py
Rscript r/agent_based_adoption_diffusion_workflow.R
sqlite3 outputs/tables/agent_based_adoption_diffusion.sqlite < sql/agent_based_adoption_diffusion_schema.sql
```

Optional compiled examples run automatically when compilers/interpreters are installed.

## Interpretation warning

All data are synthetic. This is a learning scaffold for agent-based diffusion reasoning, not a calibrated adoption forecast. Real decision use requires empirical data, network evidence, calibration, validation, stakeholder review, uncertainty analysis, and responsible communication.
