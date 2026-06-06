#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/scenario_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/scenario_modeling_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/scenario_modeling.sqlite < sql/scenario_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/scenario_trajectory_engine.c -lm -o outputs/scenario_trajectory_engine
  ./outputs/scenario_trajectory_engine > outputs/tables/c_scenario_trajectory.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/policy_robustness_scanner.cpp -o outputs/policy_robustness_scanner
  ./outputs/policy_robustness_scanner > outputs/tables/cpp_policy_robustness.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/scenario_recurrence_solver.f90 -o outputs/scenario_recurrence_solver
  ./outputs/scenario_recurrence_solver > outputs/tables/fortran_scenario_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/scenario_ensemble_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/scenario_diagnostics_cli.rs -o outputs/scenario_diagnostics_cli
  ./outputs/scenario_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/scenario_uncertainty_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/scenario_trajectory_engine outputs/policy_robustness_scanner outputs/scenario_recurrence_solver outputs/scenario_diagnostics_cli

echo "All available workflows complete."
