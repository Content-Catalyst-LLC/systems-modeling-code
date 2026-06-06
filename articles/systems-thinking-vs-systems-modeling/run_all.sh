#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/systems_thinking_vs_modeling_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/systems_thinking_vs_modeling_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/systems_thinking_vs_modeling.sqlite < sql/systems_thinking_vs_modeling_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/feedback_translation_engine.c -lm -o outputs/feedback_translation_engine
  ./outputs/feedback_translation_engine > outputs/tables/c_feedback_translation.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/conceptual_model_gap_scanner.cpp -o outputs/conceptual_model_gap_scanner
  ./outputs/conceptual_model_gap_scanner > outputs/tables/cpp_gap_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/stock_flow_translation_solver.f90 -o outputs/stock_flow_translation_solver
  ./outputs/stock_flow_translation_solver > outputs/tables/fortran_stock_flow_translation.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/scenario_comparison_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/systems_modeling_gap_cli.rs -o outputs/systems_modeling_gap_cli
  ./outputs/systems_modeling_gap_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/conceptual_formal_gap_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

echo "All available workflows complete."
