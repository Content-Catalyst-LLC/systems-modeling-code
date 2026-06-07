# When Systems Models Clarify and When They Distort

Advanced companion code for the article **When Systems Models Clarify and When They Distort**.

GitHub folder:

```text
articles/when-systems-models-clarify-and-when-they-distort/
```

This companion folder turns the clarification-versus-distortion review into reproducible systems-modeling workflows. It includes clarification scoring, distortion-risk scoring, net interpretive value, model-use labels, false-precision risk registers, boundary-error diagnostics, proxy-distortion registers, scenario-framing risks, communication controls, validation checks, SQL schemas, and multi-language examples for responsible model interpretation.

## Contents

```text
c/          Low-level clarification and distortion scoring engine
cpp/        Model-use risk scanner
data/       Model cases, risk registers, communication controls, validation targets
docs/       Modeling protocol, assumptions, validation, responsible use
fortran/    Clarification-distortion solver
go/         Clarification diagnostics runner
julia/      Clarification-distortion ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library workflow
r/          Base R workflow and diagnostic figure
rust/       Command-line clarification diagnostics scaffold
sql/        SQLite schema and analysis queries
README.md
run_all.sh
```

## Professional modeling capabilities

- Clarification scoring
- Distortion-risk scoring
- Net interpretive value
- Model-use labels
- False precision, boundary error, proxy distortion, scenario framing, optimization narrowing, and authority-transfer risk registers
- Communication control checklist
- Valid-use and misuse documentation tables
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
python3 python/clarification_distortion_workflow.py
Rscript r/clarification_distortion_workflow.R
sqlite3 outputs/tables/clarification_distortion.sqlite < sql/clarification_distortion_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/clarification_distortion_engine.c -lm -o outputs/clarification_distortion_engine && ./outputs/clarification_distortion_engine > outputs/tables/c_clarification_distortion_engine.csv
g++ -std=c++17 cpp/model_use_risk_scanner.cpp -o outputs/model_use_risk_scanner && ./outputs/model_use_risk_scanner > outputs/tables/cpp_model_use_risk_scanner.csv
gfortran fortran/clarification_distortion_solver.f90 -o outputs/clarification_distortion_solver && ./outputs/clarification_distortion_solver > outputs/tables/fortran_clarification_distortion_solver.csv
go run go/clarification_diagnostics_runner.go
rustc rust/clarification_diagnostics_cli.rs -o outputs/clarification_diagnostics_cli && ./outputs/clarification_diagnostics_cli
julia julia/clarification_distortion_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate model-use review patterns: what a model clarifies, where it may distort, how outputs can be misused, and how interpretation should be bounded. They are not substitutes for domain validation, uncertainty quantification, stakeholder review, model governance, or ethical review.
