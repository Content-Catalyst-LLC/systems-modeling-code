#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/system_dynamics_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/system_dynamics_modeling_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/system_dynamics_modeling.sqlite < sql/system_dynamics_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/system_dynamics_feedback_engine.c -lm -o outputs/system_dynamics_feedback_engine
  ./outputs/system_dynamics_feedback_engine > outputs/tables/c_system_dynamics_feedback.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/system_dynamics_sensitivity_scanner.cpp -o outputs/system_dynamics_sensitivity_scanner
  ./outputs/system_dynamics_sensitivity_scanner > outputs/tables/cpp_system_dynamics_sensitivity.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/system_dynamics_stock_flow_solver.f90 -o outputs/system_dynamics_stock_flow_solver
  ./outputs/system_dynamics_stock_flow_solver > outputs/tables/fortran_system_dynamics_stock_flow.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/system_dynamics_scenario_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/system_dynamics_diagnostics_cli.rs -o outputs/system_dynamics_diagnostics_cli
  ./outputs/system_dynamics_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/system_dynamics_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

echo "All available workflows complete."
