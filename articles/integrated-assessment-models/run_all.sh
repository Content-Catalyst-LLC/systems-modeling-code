#!/usr/bin/env bash
set -euo pipefail
ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"
mkdir -p outputs/tables outputs/figures

python3 python/integrated_assessment_models_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  Rscript r/iam_stylized_scenario_comparison.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 outputs/tables/integrated_assessment_models.sqlite < sql/integrated_assessment_models_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  gcc c/iam_pathway_engine.c -lm -o outputs/iam_pathway_engine
  ./outputs/iam_pathway_engine > outputs/tables/c_iam_pathway_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  g++ -std=c++17 cpp/iam_scenario_scanner.cpp -o outputs/iam_scenario_scanner
  ./outputs/iam_scenario_scanner > outputs/tables/cpp_iam_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  gfortran fortran/iam_recurrence_solver.f90 -o outputs/iam_recurrence_solver
  ./outputs/iam_recurrence_solver > outputs/tables/fortran_iam_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  go run go/iam_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  rustc rust/iam_diagnostics_cli.rs -o outputs/iam_diagnostics_cli
  ./outputs/iam_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  julia julia/iam_scenario_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/iam_pathway_engine outputs/iam_scenario_scanner outputs/iam_recurrence_solver outputs/iam_diagnostics_cli
echo "All available IAM workflows complete."
