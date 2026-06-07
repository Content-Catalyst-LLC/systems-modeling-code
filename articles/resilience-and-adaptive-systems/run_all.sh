#!/usr/bin/env bash
set -euo pipefail
ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"
mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/resilience_adaptive_systems_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/resilience_adaptive_systems_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/resilience_adaptive_systems.sqlite < sql/resilience_adaptive_systems_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/resilience_engine.c -lm -o outputs/resilience_engine
  ./outputs/resilience_engine > outputs/tables/c_resilience_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/resilience_scenario_scanner.cpp -o outputs/resilience_scenario_scanner
  ./outputs/resilience_scenario_scanner > outputs/tables/cpp_resilience_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/resilience_recurrence_solver.f90 -o outputs/resilience_recurrence_solver
  ./outputs/resilience_recurrence_solver > outputs/tables/fortran_resilience_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/resilience_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/resilience_diagnostics_cli.rs -o outputs/resilience_diagnostics_cli
  ./outputs/resilience_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/resilience_adaptive_capacity_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/resilience_engine outputs/resilience_scenario_scanner outputs/resilience_recurrence_solver outputs/resilience_diagnostics_cli

echo "All available workflows complete."
