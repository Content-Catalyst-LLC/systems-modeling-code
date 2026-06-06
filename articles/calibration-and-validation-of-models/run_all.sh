#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/calibration_validation_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/calibration_validation_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/calibration_validation.sqlite < sql/calibration_validation_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/calibration_trajectory_engine.c -lm -o outputs/calibration_trajectory_engine
  ./outputs/calibration_trajectory_engine > outputs/tables/c_calibration_trajectory.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/calibration_grid_search.cpp -o outputs/calibration_grid_search
  ./outputs/calibration_grid_search > outputs/tables/cpp_calibration_grid_search.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/calibration_validation_solver.f90 -o outputs/calibration_validation_solver
  ./outputs/calibration_validation_solver > outputs/tables/fortran_calibration_validation.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/calibration_validation_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/calibration_validation_cli.rs -o outputs/calibration_validation_cli
  ./outputs/calibration_validation_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/calibration_uncertainty_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/calibration_trajectory_engine outputs/calibration_grid_search outputs/calibration_validation_solver outputs/calibration_validation_cli

echo "All available workflows complete."
