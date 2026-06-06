#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/why_complex_systems_require_models_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/why_complex_systems_require_models_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/why_complex_systems_require_models.sqlite < sql/why_complex_systems_require_models_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/delayed_feedback_engine.c -lm -o outputs/delayed_feedback_engine
  ./outputs/delayed_feedback_engine > outputs/tables/c_delayed_feedback.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/scenario_threshold_sensitivity.cpp -o outputs/scenario_threshold_sensitivity
  ./outputs/scenario_threshold_sensitivity > outputs/tables/cpp_threshold_sensitivity.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/delayed_feedback_solver.f90 -o outputs/delayed_feedback_solver
  ./outputs/delayed_feedback_solver > outputs/tables/fortran_delayed_feedback.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/scenario_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/threshold_diagnostics_cli.rs -o outputs/threshold_diagnostics_cli
  ./outputs/threshold_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/nonlinear_threshold_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

echo "All available workflows complete."
