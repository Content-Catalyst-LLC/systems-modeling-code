#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/panarchy_multiscale_systems_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/panarchy_multiscale_cycles_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/panarchy_multiscale_systems.sqlite < sql/panarchy_multiscale_systems_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/panarchy_engine.c -lm -o outputs/panarchy_engine
  ./outputs/panarchy_engine > outputs/tables/c_panarchy_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/panarchy_scenario_scanner.cpp -o outputs/panarchy_scenario_scanner
  ./outputs/panarchy_scenario_scanner > outputs/tables/cpp_panarchy_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/panarchy_recurrence_solver.f90 -o outputs/panarchy_recurrence_solver
  ./outputs/panarchy_recurrence_solver > outputs/tables/fortran_panarchy_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/panarchy_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/panarchy_diagnostics_cli.rs -o outputs/panarchy_diagnostics_cli
  ./outputs/panarchy_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/panarchy_multiscale_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/panarchy_engine outputs/panarchy_scenario_scanner outputs/panarchy_recurrence_solver outputs/panarchy_diagnostics_cli

echo "All available workflows complete."
