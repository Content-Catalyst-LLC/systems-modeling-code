#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/delay_oscillation_policy_resistance_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/delay_oscillation_policy_resistance_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/delay_oscillation_policy_resistance.sqlite < sql/delay_oscillation_policy_resistance_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/delay_oscillation_engine.c -lm -o outputs/delay_oscillation_engine
  ./outputs/delay_oscillation_engine > outputs/tables/c_delay_oscillation_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/delay_policy_resistance_scanner.cpp -o outputs/delay_policy_resistance_scanner
  ./outputs/delay_policy_resistance_scanner > outputs/tables/cpp_delay_policy_resistance_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/delayed_feedback_recurrence_solver.f90 -o outputs/delayed_feedback_recurrence_solver
  ./outputs/delayed_feedback_recurrence_solver > outputs/tables/fortran_delayed_feedback_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/delay_policy_diagnostics_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/delay_policy_diagnostics_cli.rs -o outputs/delay_policy_diagnostics_cli
  ./outputs/delay_policy_diagnostics_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/delay_oscillation_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/delay_oscillation_engine outputs/delay_policy_resistance_scanner outputs/delayed_feedback_recurrence_solver outputs/delay_policy_diagnostics_cli

echo "All available workflows complete."
