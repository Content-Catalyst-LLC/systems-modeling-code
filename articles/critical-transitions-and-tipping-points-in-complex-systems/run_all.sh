#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/critical_transitions_tipping_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/critical_transitions_tipping_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/critical_transitions_tipping.sqlite < sql/critical_transitions_tipping_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/tipping_threshold_engine.c -lm -o outputs/tipping_threshold_engine
  ./outputs/tipping_threshold_engine > outputs/tables/c_tipping_threshold_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/critical_transition_scenario_scanner.cpp -o outputs/critical_transition_scenario_scanner
  ./outputs/critical_transition_scenario_scanner > outputs/tables/cpp_critical_transition_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/tipping_recurrence_solver.f90 -o outputs/tipping_recurrence_solver
  ./outputs/tipping_recurrence_solver > outputs/tables/fortran_tipping_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/tipping_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/tipping_diagnostics_cli.rs -o outputs/tipping_diagnostics_cli
  ./outputs/tipping_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/tipping_hysteresis_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/tipping_threshold_engine outputs/critical_transition_scenario_scanner outputs/tipping_recurrence_solver outputs/tipping_diagnostics_cli

echo "All available workflows complete."
