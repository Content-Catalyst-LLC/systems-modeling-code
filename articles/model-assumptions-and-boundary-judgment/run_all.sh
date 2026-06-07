#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/model_assumptions_boundary_judgment_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/model_assumptions_boundary_judgment_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/model_assumptions_boundary_judgment.sqlite < sql/model_assumptions_boundary_judgment_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/assumption_risk_engine.c -lm -o outputs/assumption_risk_engine
  ./outputs/assumption_risk_engine > outputs/tables/c_assumption_risk_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/boundary_scenario_scanner.cpp -o outputs/boundary_scenario_scanner
  ./outputs/boundary_scenario_scanner > outputs/tables/cpp_boundary_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/assumption_risk_solver.f90 -o outputs/assumption_risk_solver
  ./outputs/assumption_risk_solver > outputs/tables/fortran_assumption_risk_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/boundary_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/boundary_diagnostics_cli.rs -o outputs/boundary_diagnostics_cli
  ./outputs/boundary_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/assumption_boundary_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/assumption_risk_engine outputs/boundary_scenario_scanner outputs/assumption_risk_solver outputs/boundary_diagnostics_cli

echo "All available workflows complete."
