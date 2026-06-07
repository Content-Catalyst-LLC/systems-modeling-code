#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/participatory_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/participatory_modeling_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/participatory_modeling.sqlite < sql/participatory_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/participatory_score_engine.c -lm -o outputs/participatory_score_engine
  ./outputs/participatory_score_engine > outputs/tables/c_participatory_score_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/participatory_scenario_scanner.cpp -o outputs/participatory_scenario_scanner
  ./outputs/participatory_scenario_scanner > outputs/tables/cpp_participatory_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/participatory_score_solver.f90 -o outputs/participatory_score_solver
  ./outputs/participatory_score_solver > outputs/tables/fortran_participatory_score_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/participatory_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/participatory_diagnostics_cli.rs -o outputs/participatory_diagnostics_cli
  ./outputs/participatory_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/participatory_scenario_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/participatory_score_engine outputs/participatory_scenario_scanner outputs/participatory_score_solver outputs/participatory_diagnostics_cli

echo "All available workflows complete."
