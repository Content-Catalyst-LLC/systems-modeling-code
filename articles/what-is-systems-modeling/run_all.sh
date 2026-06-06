#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python professional workflow..."
python3 python/systems_modeling_professional_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R stock-flow uncertainty workflow..."
  Rscript r/stock_flow_uncertainty_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQLite schema and analysis queries..."
  sqlite3 outputs/tables/systems_modeling.sqlite < sql/systems_modeling_schema_and_queries.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Compiling and running C stock-flow engine..."
  gcc c/stock_flow_engine.c -lm -o outputs/stock_flow_engine
  ./outputs/stock_flow_engine > outputs/tables/c_stock_flow_output.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Compiling and running C++ sensitivity scanner..."
  g++ -std=c++17 cpp/scenario_ensemble_sensitivity.cpp -o outputs/scenario_ensemble_sensitivity
  ./outputs/scenario_ensemble_sensitivity > outputs/tables/cpp_scenario_ensemble.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Compiling and running Fortran solver..."
  gfortran fortran/coupled_stock_solver.f90 -o outputs/coupled_stock_solver
  ./outputs/coupled_stock_solver > outputs/tables/fortran_coupled_stock_output.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go network batch runner..."
  go run go/network_batch_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Compiling and running Rust CLI..."
  rustc rust/systems_model_cli.rs -o outputs/systems_model_cli
  ./outputs/systems_model_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia nonlinear feedback ensemble..."
  julia julia/nonlinear_feedback_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

echo "All available workflows complete."
