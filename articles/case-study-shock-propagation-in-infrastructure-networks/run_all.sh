#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/infrastructure_shock_propagation_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/infrastructure_shock_propagation_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/infrastructure_shock_propagation.sqlite < sql/infrastructure_shock_propagation_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/infrastructure_cascade_engine.c -lm -o outputs/infrastructure_cascade_engine
  ./outputs/infrastructure_cascade_engine > outputs/tables/c_infrastructure_cascade_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/infrastructure_scenario_scanner.cpp -o outputs/infrastructure_scenario_scanner
  ./outputs/infrastructure_scenario_scanner > outputs/tables/cpp_infrastructure_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/infrastructure_cascade_solver.f90 -o outputs/infrastructure_cascade_solver
  ./outputs/infrastructure_cascade_solver > outputs/tables/fortran_infrastructure_cascade_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/infrastructure_shock_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/infrastructure_cascade_cli.rs -o outputs/infrastructure_cascade_cli
  ./outputs/infrastructure_cascade_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/infrastructure_cascade_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/infrastructure_cascade_engine outputs/infrastructure_scenario_scanner outputs/infrastructure_cascade_solver outputs/infrastructure_cascade_cli

echo "All available workflows complete."
