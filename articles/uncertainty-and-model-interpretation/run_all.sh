#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/uncertainty_interpretation_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/uncertainty_interpretation_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/uncertainty_interpretation.sqlite < sql/uncertainty_interpretation_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/uncertainty_trajectory_engine.c -lm -o outputs/uncertainty_trajectory_engine
  ./outputs/uncertainty_trajectory_engine > outputs/tables/c_uncertainty_trajectory.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/uncertainty_robustness_scanner.cpp -o outputs/uncertainty_robustness_scanner
  ./outputs/uncertainty_robustness_scanner > outputs/tables/cpp_uncertainty_robustness.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/uncertainty_recurrence_solver.f90 -o outputs/uncertainty_recurrence_solver
  ./outputs/uncertainty_recurrence_solver > outputs/tables/fortran_uncertainty_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/uncertainty_ensemble_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/uncertainty_diagnostics_cli.rs -o outputs/uncertainty_diagnostics_cli
  ./outputs/uncertainty_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/uncertainty_propagation_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/uncertainty_trajectory_engine outputs/uncertainty_robustness_scanner outputs/uncertainty_recurrence_solver outputs/uncertainty_diagnostics_cli

echo "All available workflows complete."
