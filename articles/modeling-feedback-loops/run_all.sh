#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/feedback_loop_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/feedback_loop_dynamics_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/feedback_loop_modeling.sqlite < sql/feedback_loop_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/feedback_loop_engine.c -lm -o outputs/feedback_loop_engine
  ./outputs/feedback_loop_engine > outputs/tables/c_feedback_loop_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/delayed_feedback_scanner.cpp -o outputs/delayed_feedback_scanner
  ./outputs/delayed_feedback_scanner > outputs/tables/cpp_delayed_feedback_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/feedback_recurrence_solver.f90 -o outputs/feedback_recurrence_solver
  ./outputs/feedback_recurrence_solver > outputs/tables/fortran_feedback_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/feedback_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/feedback_diagnostics_cli.rs -o outputs/feedback_diagnostics_cli
  ./outputs/feedback_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/feedback_loop_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/feedback_loop_engine outputs/delayed_feedback_scanner outputs/feedback_recurrence_solver outputs/feedback_diagnostics_cli

echo "All available workflows complete."
