#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/health_systems_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/health_systems_capacity_backlog_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/health_systems_modeling.sqlite < sql/health_systems_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/health_system_pressure_engine.c -lm -o outputs/health_system_pressure_engine
  ./outputs/health_system_pressure_engine > outputs/tables/c_health_system_pressure_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/health_system_scenario_scanner.cpp -o outputs/health_system_scenario_scanner
  ./outputs/health_system_scenario_scanner > outputs/tables/cpp_health_system_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/health_system_recurrence_solver.f90 -o outputs/health_system_recurrence_solver
  ./outputs/health_system_recurrence_solver > outputs/tables/fortran_health_system_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/health_system_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/health_system_diagnostics_cli.rs -o outputs/health_system_diagnostics_cli
  ./outputs/health_system_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/health_systems_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/health_system_pressure_engine outputs/health_system_scenario_scanner outputs/health_system_recurrence_solver outputs/health_system_diagnostics_cli

echo "All available workflows complete."
