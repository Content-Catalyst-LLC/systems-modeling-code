#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Python workflow..."
python3 python/agent_based_adoption_diffusion_workflow.py

if command -v Rscript >/dev/null 2>&1; then
  echo "Running R workflow..."
  Rscript r/agent_based_adoption_diffusion_workflow.R
else
  echo "Rscript not found; skipping R workflow."
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "Running SQL workflow..."
  sqlite3 outputs/tables/agent_based_adoption_diffusion.sqlite < sql/agent_based_adoption_diffusion_schema.sql
else
  echo "sqlite3 not found; skipping SQL workflow."
fi

if command -v gcc >/dev/null 2>&1; then
  echo "Running C workflow..."
  gcc c/adoption_diffusion_engine.c -lm -o outputs/adoption_diffusion_engine
  ./outputs/adoption_diffusion_engine > outputs/tables/c_adoption_diffusion_engine.csv
else
  echo "gcc not found; skipping C workflow."
fi

if command -v g++ >/dev/null 2>&1; then
  echo "Running C++ workflow..."
  g++ -std=c++17 cpp/adoption_scenario_scanner.cpp -o outputs/adoption_scenario_scanner
  ./outputs/adoption_scenario_scanner > outputs/tables/cpp_adoption_scenario_scanner.csv
else
  echo "g++ not found; skipping C++ workflow."
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "Running Fortran workflow..."
  gfortran fortran/adoption_diffusion_solver.f90 -o outputs/adoption_diffusion_solver
  ./outputs/adoption_diffusion_solver > outputs/tables/fortran_adoption_diffusion_solver.csv
else
  echo "gfortran not found; skipping Fortran workflow."
fi

if command -v go >/dev/null 2>&1; then
  echo "Running Go workflow..."
  go run go/adoption_diffusion_runner.go
else
  echo "go not found; skipping Go workflow."
fi

if command -v rustc >/dev/null 2>&1; then
  echo "Running Rust workflow..."
  rustc rust/adoption_diffusion_cli.rs -o outputs/adoption_diffusion_cli
  ./outputs/adoption_diffusion_cli
else
  echo "rustc not found; skipping Rust workflow."
fi

if command -v julia >/dev/null 2>&1; then
  echo "Running Julia workflow..."
  julia julia/adoption_diffusion_ensemble.jl
else
  echo "julia not found; skipping Julia workflow."
fi

rm -f outputs/adoption_diffusion_engine outputs/adoption_scenario_scanner outputs/adoption_diffusion_solver outputs/adoption_diffusion_cli

echo "All available workflows complete."
