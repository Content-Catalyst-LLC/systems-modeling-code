#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/phase_transitions_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/phase_transition_bifurcation_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/phase_transitions.sqlite < sql/phase_transitions_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/phase_transition_engine.c -lm -o outputs/phase_transition_engine
  ./outputs/phase_transition_engine > outputs/tables/c_phase_transition_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/phase_transition_scenario_scanner.cpp -o outputs/phase_transition_scenario_scanner
  ./outputs/phase_transition_scenario_scanner > outputs/tables/cpp_phase_transition_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/phase_transition_recurrence_solver.f90 -o outputs/phase_transition_recurrence_solver
  ./outputs/phase_transition_recurrence_solver > outputs/tables/fortran_phase_transition_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/phase_transition_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/phase_transition_diagnostics_cli.rs -o outputs/phase_transition_diagnostics_cli
  ./outputs/phase_transition_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/phase_transition_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/phase_transition_engine outputs/phase_transition_scenario_scanner outputs/phase_transition_recurrence_solver outputs/phase_transition_diagnostics_cli

echo "All available workflows complete."
