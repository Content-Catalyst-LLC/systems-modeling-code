#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/history_of_systems_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/history_of_systems_modeling_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/history_of_systems_modeling.sqlite < sql/history_of_systems_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/historical_feedback_engine.c -lm -o outputs/historical_feedback_engine
  ./outputs/historical_feedback_engine > outputs/tables/c_historical_feedback.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/historical_scenario_sensitivity.cpp -o outputs/historical_scenario_sensitivity
  ./outputs/historical_scenario_sensitivity > outputs/tables/cpp_historical_sensitivity.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/historical_stock_flow_solver.f90 -o outputs/historical_stock_flow_solver
  ./outputs/historical_stock_flow_solver > outputs/tables/fortran_historical_stock_flow.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/historical_scenario_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/historical_diagnostics_cli.rs -o outputs/historical_diagnostics_cli
  ./outputs/historical_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/historical_model_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

echo "All available workflows complete."
