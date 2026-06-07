#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/communicating_model_results_responsibly_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/communicating_model_results_responsibly_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/communicating_model_results_responsibly.sqlite < sql/communicating_model_results_responsibly_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/communication_quality_engine.c -lm -o outputs/communication_quality_engine
  ./outputs/communication_quality_engine > outputs/tables/c_communication_quality_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/false_precision_scanner.cpp -o outputs/false_precision_scanner
  ./outputs/false_precision_scanner > outputs/tables/cpp_false_precision_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/communication_quality_solver.f90 -o outputs/communication_quality_solver
  ./outputs/communication_quality_solver > outputs/tables/fortran_communication_quality_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/communication_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/communication_diagnostics_cli.rs -o outputs/communication_diagnostics_cli
  ./outputs/communication_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/communication_quality_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/communication_quality_engine outputs/false_precision_scanner outputs/communication_quality_solver outputs/communication_diagnostics_cli

echo "All available workflows complete."
