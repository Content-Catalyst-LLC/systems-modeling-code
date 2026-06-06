#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/model_comparison_ensemble_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/model_comparison_ensemble_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/model_comparison_ensemble.sqlite < sql/model_comparison_ensemble_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/model_trajectory_comparison.c -lm -o outputs/model_trajectory_comparison
  ./outputs/model_trajectory_comparison > outputs/tables/c_model_trajectory_comparison.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/model_ensemble_scanner.cpp -o outputs/model_ensemble_scanner
  ./outputs/model_ensemble_scanner > outputs/tables/cpp_model_ensemble_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/model_comparison_solver.f90 -o outputs/model_comparison_solver
  ./outputs/model_comparison_solver > outputs/tables/fortran_model_comparison.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/model_ensemble_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/model_ensemble_cli.rs -o outputs/model_ensemble_cli
  ./outputs/model_ensemble_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/model_ensemble_comparison.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/model_trajectory_comparison outputs/model_ensemble_scanner outputs/model_comparison_solver outputs/model_ensemble_cli

echo "All available workflows complete."
