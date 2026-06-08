#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/public_policy_scenario_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/public_policy_scenario_modeling_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/public_policy_scenario_modeling.sqlite < sql/public_policy_scenario_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/policy_robustness_engine.c -lm -o outputs/policy_robustness_engine
  ./outputs/policy_robustness_engine > outputs/tables/c_policy_robustness_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/policy_scenario_scanner.cpp -o outputs/policy_scenario_scanner
  ./outputs/policy_scenario_scanner > outputs/tables/cpp_policy_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/policy_robustness_solver.f90 -o outputs/policy_robustness_solver
  ./outputs/policy_robustness_solver > outputs/tables/fortran_policy_robustness_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/policy_robustness_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/policy_robustness_cli.rs -o outputs/policy_robustness_cli
  ./outputs/policy_robustness_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/policy_scenario_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/policy_robustness_engine outputs/policy_scenario_scanner outputs/policy_robustness_solver outputs/policy_robustness_cli

echo "All available workflows complete."
