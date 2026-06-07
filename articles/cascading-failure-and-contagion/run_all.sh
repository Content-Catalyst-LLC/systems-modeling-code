#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/cascading_failure_contagion_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/cascading_failure_threshold_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/cascading_failure_contagion.sqlite < sql/cascading_failure_contagion_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/cascade_threshold_engine.c -lm -o outputs/cascade_threshold_engine
  ./outputs/cascade_threshold_engine > outputs/tables/c_cascade_threshold_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/cascade_scenario_scanner.cpp -o outputs/cascade_scenario_scanner
  ./outputs/cascade_scenario_scanner > outputs/tables/cpp_cascade_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/cascade_recurrence_solver.f90 -o outputs/cascade_recurrence_solver
  ./outputs/cascade_recurrence_solver > outputs/tables/fortran_cascade_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/cascade_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/cascade_diagnostics_cli.rs -o outputs/cascade_diagnostics_cli
  ./outputs/cascade_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/cascade_contagion_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/cascade_threshold_engine outputs/cascade_scenario_scanner outputs/cascade_recurrence_solver outputs/cascade_diagnostics_cli

echo "All available workflows complete."
