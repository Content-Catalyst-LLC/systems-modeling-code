#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/ai_ml_systems_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/ai_surrogate_systems_modeling_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/ai_ml_systems_modeling.sqlite < sql/ai_ml_systems_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/hybrid_residual_engine.c -lm -o outputs/hybrid_residual_engine
  ./outputs/hybrid_residual_engine > outputs/tables/c_hybrid_residual_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/ai_systems_scenario_scanner.cpp -o outputs/ai_systems_scenario_scanner
  ./outputs/ai_systems_scenario_scanner > outputs/tables/cpp_ai_systems_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/hybrid_residual_solver.f90 -o outputs/hybrid_residual_solver
  ./outputs/hybrid_residual_solver > outputs/tables/fortran_hybrid_residual_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/ai_systems_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/ai_systems_diagnostics_cli.rs -o outputs/ai_systems_diagnostics_cli
  ./outputs/ai_systems_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/ai_hybrid_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/hybrid_residual_engine outputs/ai_systems_scenario_scanner outputs/hybrid_residual_solver outputs/ai_systems_diagnostics_cli

echo "All available workflows complete."
