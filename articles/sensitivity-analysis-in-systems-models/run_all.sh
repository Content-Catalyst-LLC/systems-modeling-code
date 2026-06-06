#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/sensitivity_analysis_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/sensitivity_analysis_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/sensitivity_analysis.sqlite < sql/sensitivity_analysis_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/sensitivity_recurrence_engine.c -lm -o outputs/sensitivity_recurrence_engine
  ./outputs/sensitivity_recurrence_engine > outputs/tables/c_sensitivity_recurrence.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/sensitivity_screening_scanner.cpp -o outputs/sensitivity_screening_scanner
  ./outputs/sensitivity_screening_scanner > outputs/tables/cpp_sensitivity_screening.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/sensitivity_recurrence_solver.f90 -o outputs/sensitivity_recurrence_solver
  ./outputs/sensitivity_recurrence_solver > outputs/tables/fortran_sensitivity_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/sensitivity_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/sensitivity_diagnostics_cli.rs -o outputs/sensitivity_diagnostics_cli
  ./outputs/sensitivity_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/sensitivity_uncertainty_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/sensitivity_recurrence_engine outputs/sensitivity_screening_scanner outputs/sensitivity_recurrence_solver outputs/sensitivity_diagnostics_cli

echo "All available workflows complete."
