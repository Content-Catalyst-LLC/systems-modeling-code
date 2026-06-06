#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/mathematics_complex_systems_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/mathematics_complex_systems_diagnostics.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/mathematics_complex_systems.sqlite < sql/mathematics_complex_systems_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/complex_systems_math_engine.c -lm -o outputs/complex_systems_math_engine
  ./outputs/complex_systems_math_engine > outputs/tables/c_complex_systems_math.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/nonlinear_ensemble_scanner.cpp -o outputs/nonlinear_ensemble_scanner
  ./outputs/nonlinear_ensemble_scanner > outputs/tables/cpp_nonlinear_ensemble_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/nonlinear_recurrence_solver.f90 -o outputs/nonlinear_recurrence_solver
  ./outputs/nonlinear_recurrence_solver > outputs/tables/fortran_nonlinear_recurrence.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/complex_systems_math_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/complex_systems_math_cli.rs -o outputs/complex_systems_math_cli
  ./outputs/complex_systems_math_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/complex_systems_math_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/complex_systems_math_engine outputs/nonlinear_ensemble_scanner outputs/nonlinear_recurrence_solver outputs/complex_systems_math_cli

echo "All available workflows complete."
