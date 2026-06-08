#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/stock_flow_resource_depletion_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/stock_flow_resource_depletion_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/resource_depletion.sqlite < sql/resource_depletion_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/resource_depletion_engine.c -lm -o outputs/resource_depletion_engine
  ./outputs/resource_depletion_engine > outputs/tables/c_resource_depletion_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/resource_scenario_scanner.cpp -o outputs/resource_scenario_scanner
  ./outputs/resource_scenario_scanner > outputs/tables/cpp_resource_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/resource_stock_solver.f90 -o outputs/resource_stock_solver
  ./outputs/resource_stock_solver > outputs/tables/fortran_resource_stock_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/resource_depletion_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/resource_depletion_cli.rs -o outputs/resource_depletion_cli
  ./outputs/resource_depletion_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/resource_depletion_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/resource_depletion_engine outputs/resource_scenario_scanner outputs/resource_stock_solver outputs/resource_depletion_cli

echo "All available workflows complete."
