#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/future_directions_systems_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/future_directions_systems_modeling_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/future_directions_systems_modeling.sqlite < sql/future_directions_systems_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/adaptive_monitoring_engine.c -lm -o outputs/adaptive_monitoring_engine
  ./outputs/adaptive_monitoring_engine > outputs/tables/c_adaptive_monitoring_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/drift_indicator_scanner.cpp -o outputs/drift_indicator_scanner
  ./outputs/drift_indicator_scanner > outputs/tables/cpp_drift_indicator_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/adaptive_state_solver.f90 -o outputs/adaptive_state_solver
  ./outputs/adaptive_state_solver > outputs/tables/fortran_adaptive_state_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/adaptive_monitoring_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/adaptive_monitoring_cli.rs -o outputs/adaptive_monitoring_cli
  ./outputs/adaptive_monitoring_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/adaptive_monitoring_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/adaptive_monitoring_engine outputs/drift_indicator_scanner outputs/adaptive_state_solver outputs/adaptive_monitoring_cli

echo "All available workflows complete."
