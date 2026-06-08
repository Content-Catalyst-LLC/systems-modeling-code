#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/integrated_assessment_sustainability_pathways_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/integrated_assessment_sustainability_pathways_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/integrated_assessment_sustainability_pathways.sqlite < sql/integrated_assessment_sustainability_pathways_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/integrated_assessment_engine.c -lm -o outputs/integrated_assessment_engine
  ./outputs/integrated_assessment_engine > outputs/tables/c_integrated_assessment_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/sustainability_pathway_scanner.cpp -o outputs/sustainability_pathway_scanner
  ./outputs/sustainability_pathway_scanner > outputs/tables/cpp_sustainability_pathway_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/integrated_assessment_solver.f90 -o outputs/integrated_assessment_solver
  ./outputs/integrated_assessment_solver > outputs/tables/fortran_integrated_assessment_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/integrated_assessment_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/integrated_assessment_cli.rs -o outputs/integrated_assessment_cli
  ./outputs/integrated_assessment_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/integrated_assessment_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/integrated_assessment_engine outputs/sustainability_pathway_scanner outputs/integrated_assessment_solver outputs/integrated_assessment_cli

echo "All available workflows complete."
