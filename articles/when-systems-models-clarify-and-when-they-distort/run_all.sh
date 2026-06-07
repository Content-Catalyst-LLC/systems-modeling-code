#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/clarification_distortion_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/clarification_distortion_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/clarification_distortion.sqlite < sql/clarification_distortion_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/clarification_distortion_engine.c -lm -o outputs/clarification_distortion_engine
  ./outputs/clarification_distortion_engine > outputs/tables/c_clarification_distortion_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/model_use_risk_scanner.cpp -o outputs/model_use_risk_scanner
  ./outputs/model_use_risk_scanner > outputs/tables/cpp_model_use_risk_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/clarification_distortion_solver.f90 -o outputs/clarification_distortion_solver
  ./outputs/clarification_distortion_solver > outputs/tables/fortran_clarification_distortion_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/clarification_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/clarification_diagnostics_cli.rs -o outputs/clarification_diagnostics_cli
  ./outputs/clarification_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/clarification_distortion_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/clarification_distortion_engine outputs/model_use_risk_scanner outputs/clarification_distortion_solver outputs/clarification_diagnostics_cli

echo "All available workflows complete."
