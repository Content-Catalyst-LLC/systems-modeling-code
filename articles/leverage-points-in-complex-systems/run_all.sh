#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/leverage_points_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/leverage_points_intervention_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/leverage_points_modeling.sqlite < sql/leverage_points_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/leverage_points_engine.c -lm -o outputs/leverage_points_engine
  ./outputs/leverage_points_engine > outputs/tables/c_leverage_points_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/leverage_intervention_scanner.cpp -o outputs/leverage_intervention_scanner
  ./outputs/leverage_intervention_scanner > outputs/tables/cpp_leverage_intervention_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/leverage_recurrence_solver.f90 -o outputs/leverage_recurrence_solver
  ./outputs/leverage_recurrence_solver > outputs/tables/fortran_leverage_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/leverage_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/leverage_diagnostics_cli.rs -o outputs/leverage_diagnostics_cli
  ./outputs/leverage_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/leverage_points_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/leverage_points_engine outputs/leverage_intervention_scanner outputs/leverage_recurrence_solver outputs/leverage_diagnostics_cli

echo "All available workflows complete."
