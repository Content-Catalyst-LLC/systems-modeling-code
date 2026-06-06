# Modeling Feedback Loops

Advanced companion code for the article **Modeling Feedback Loops**.

GitHub folder:

```text
articles/modeling-feedback-loops/
```

This companion folder turns feedback-loop concepts into reproducible systems-modeling workflows. It includes reinforcing feedback, balancing feedback, logistic feedback, delayed balancing feedback, stock-flow accumulation, loop-dominance diagnostics, oscillation testing, policy-resistance scenarios, validation checks, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level reinforcing, balancing, logistic, and delayed feedback engine
cpp/        Delayed feedback ensemble scanner
data/       Feedback loop taxonomy, parameters, scenarios, validation targets
docs/       Feedback modeling protocol, assumptions, validation, responsible use
fortran/    Feedback recurrence solver
go/         Feedback diagnostics runner
julia/      Feedback dynamics and delay ensemble workflow
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library feedback modeling workflow
r/          Base R feedback loop dynamics workflow
rust/       Command-line feedback diagnostics scaffold
sql/        SQLite schema and feedback-loop analysis queries
```

## Professional modeling capabilities

- Reinforcing feedback simulation
- Balancing feedback simulation
- Logistic feedback simulation
- Delayed balancing feedback
- Overshoot and oscillation diagnostics
- Stock-flow accumulation examples
- Loop-dominance interpretation
- Policy-resistance scenarios
- Delay and correction-strength sweeps
- Validation checks
- SQL model-run schema
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/feedback_loop_modeling_workflow.py
Rscript r/feedback_loop_dynamics_diagnostics.R
sqlite3 outputs/tables/feedback_loop_modeling.sqlite < sql/feedback_loop_modeling_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/feedback_loop_engine.c -lm -o outputs/feedback_loop_engine && ./outputs/feedback_loop_engine > outputs/tables/c_feedback_loop_engine.csv
g++ -std=c++17 cpp/delayed_feedback_scanner.cpp -o outputs/delayed_feedback_scanner && ./outputs/delayed_feedback_scanner > outputs/tables/cpp_delayed_feedback_scanner.csv
gfortran fortran/feedback_recurrence_solver.f90 -o outputs/feedback_recurrence_solver && ./outputs/feedback_recurrence_solver > outputs/tables/fortran_feedback_recurrence.csv
go run go/feedback_diagnostics_runner.go
rustc rust/feedback_diagnostics_cli.rs -o outputs/feedback_diagnostics_cli && ./outputs/feedback_diagnostics_cli
julia julia/feedback_loop_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate feedback-loop structure, delayed response, oscillation diagnostics, stock-flow accumulation, policy resistance, and reproducible workflow organization. They are not calibrated empirical models of any real climate, infrastructure, economic, health, environmental, organizational, or policy system. Applied use requires domain data, structural review, validation evidence, justified feedback assumptions, uncertainty communication, stakeholder review, and boundary critique.
