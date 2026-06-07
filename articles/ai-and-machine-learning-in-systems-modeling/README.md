# AI and Machine Learning in Systems Modeling

Advanced companion code for the article **AI and Machine Learning in Systems Modeling**.

GitHub folder:

```text
articles/ai-and-machine-learning-in-systems-modeling/
```

This companion folder turns AI-enhanced systems modeling concepts into reproducible workflows. It includes hybrid structural prediction, residual learning, surrogate modeling, constraint-aware diagnostics, data-quality and governance tables, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level hybrid residual-learning demonstration
cpp/        Surrogate and residual scenario scanner
data/       AI roles, hybrid architectures, governance, risks, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Hybrid recurrence and residual correction example
go/         AI systems diagnostics runner
julia/      Hybrid systems learning ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library hybrid residual-learning workflow
r/          Base R surrogate systems modeling workflow
rust/       Command-line AI systems diagnostics scaffold
sql/        SQLite schema and analysis queries
README.md
run_all.sh
```

## Professional modeling capabilities

- Structural baseline and residual-learning examples
- Surrogate modeling for nonlinear systems response
- Hybrid model architecture taxonomy
- AI governance and responsible-use tables
- Data-quality, bias, drift, and reliability diagnostics
- Constraint-aware learning concepts
- Validation checks for baseline vs hybrid performance
- SQL schema for AI-enhanced systems modeling metadata
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/ai_ml_systems_modeling_workflow.py
Rscript r/ai_surrogate_systems_modeling_workflow.R
sqlite3 outputs/tables/ai_ml_systems_modeling.sqlite < sql/ai_ml_systems_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/hybrid_residual_engine.c -lm -o outputs/hybrid_residual_engine && ./outputs/hybrid_residual_engine > outputs/tables/c_hybrid_residual_engine.csv
g++ -std=c++17 cpp/ai_systems_scenario_scanner.cpp -o outputs/ai_systems_scenario_scanner && ./outputs/ai_systems_scenario_scanner > outputs/tables/cpp_ai_systems_scenario_scanner.csv
gfortran fortran/hybrid_residual_solver.f90 -o outputs/hybrid_residual_solver && ./outputs/hybrid_residual_solver > outputs/tables/fortran_hybrid_residual_solver.csv
go run go/ai_systems_diagnostics_runner.go
rustc rust/ai_systems_diagnostics_cli.rs -o outputs/ai_systems_diagnostics_cli && ./outputs/ai_systems_diagnostics_cli
julia julia/ai_hybrid_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate AI-enhanced systems modeling patterns: structural baselines, learned residuals, surrogate approximation, validation checks, governance tables, and responsible-use documentation. They are not calibrated models of a real infrastructure system, public health system, environmental system, economic system, platform, model deployment, or AI system. Applied use requires domain evidence, data governance, privacy review, model validation, subgroup testing, drift monitoring, causal review, and human accountability.
