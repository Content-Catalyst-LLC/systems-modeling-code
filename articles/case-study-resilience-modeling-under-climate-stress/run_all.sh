#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/climate_resilience_scenario_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/climate_resilience_scenario_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/climate_resilience_scenario_model.sqlite < sql/climate_resilience_scenario_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/climate_resilience_engine.c -lm -o outputs/climate_resilience_engine
  ./outputs/climate_resilience_engine > outputs/tables/c_climate_resilience_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/climate_resilience_scenario_scanner.cpp -o outputs/climate_resilience_scenario_scanner
  ./outputs/climate_resilience_scenario_scanner > outputs/tables/cpp_climate_resilience_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/climate_resilience_solver.f90 -o outputs/climate_resilience_solver
  ./outputs/climate_resilience_solver > outputs/tables/fortran_climate_resilience_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/climate_resilience_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/climate_resilience_cli.rs -o outputs/climate_resilience_cli
  ./outputs/climate_resilience_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/climate_resilience_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/climate_resilience_engine outputs/climate_resilience_scenario_scanner outputs/climate_resilience_solver outputs/climate_resilience_cli

echo "All available workflows complete."
