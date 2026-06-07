#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/environmental_systems_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/environmental_systems_resource_recovery_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/environmental_systems_modeling.sqlite < sql/environmental_systems_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/environmental_stock_flow_engine.c -lm -o outputs/environmental_stock_flow_engine
  ./outputs/environmental_stock_flow_engine > outputs/tables/c_environmental_stock_flow_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/environmental_scenario_scanner.cpp -o outputs/environmental_scenario_scanner
  ./outputs/environmental_scenario_scanner > outputs/tables/cpp_environmental_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/environmental_recurrence_solver.f90 -o outputs/environmental_recurrence_solver
  ./outputs/environmental_recurrence_solver > outputs/tables/fortran_environmental_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/environmental_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/environmental_diagnostics_cli.rs -o outputs/environmental_diagnostics_cli
  ./outputs/environmental_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/environmental_systems_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/environmental_stock_flow_engine outputs/environmental_scenario_scanner outputs/environmental_recurrence_solver outputs/environmental_diagnostics_cli

echo "All available workflows complete."
