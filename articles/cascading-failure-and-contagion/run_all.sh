#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

mkdir -p outputs/tables outputs/figures

echo "Running Cascading Failure and Contagion workflows..."

if command -v python3 >/dev/null 2>&1; then
  echo "[python] running cascading_failure_stress_test.py"
  python3 python/cascading_failure_stress_test.py
else
  echo "[python] skipped: python3 not installed"
fi

if command -v Rscript >/dev/null 2>&1; then
  echo "[R] running cascading_failure_network_workflow.R"
  Rscript r/cascading_failure_network_workflow.R
else
  echo "[R] skipped: Rscript not installed"
fi

if command -v sqlite3 >/dev/null 2>&1; then
  echo "[sql] running cascading_failure_schema.sql"
  (cd sql && sqlite3 ../outputs/tables/cascading_failure.sqlite < cascading_failure_schema.sql)
else
  echo "[sql] skipped: sqlite3 not installed"
fi

if command -v julia >/dev/null 2>&1; then
  echo "[julia] running cascade_threshold_model.jl"
  julia julia/cascade_threshold_model.jl > outputs/tables/julia_cascade_threshold_output.txt
else
  echo "[julia] skipped: julia not installed"
fi

if command -v go >/dev/null 2>&1; then
  echo "[go] running cascade_summary.go"
  go run go/cascade_summary.go > outputs/tables/go_cascade_summary_output.txt
else
  echo "[go] skipped: go not installed"
fi

if command -v rustc >/dev/null 2>&1; then
  echo "[rust] compiling cascade_summary.rs"
  rustc rust/cascade_summary.rs -o outputs/tables/rust_cascade_summary
  outputs/tables/rust_cascade_summary > outputs/tables/rust_cascade_summary_output.txt
else
  echo "[rust] skipped: rustc not installed"
fi

if command -v gcc >/dev/null 2>&1; then
  echo "[c] compiling cascade_capacity.c"
  gcc c/cascade_capacity.c -o outputs/tables/cascade_capacity_c
  outputs/tables/cascade_capacity_c > outputs/tables/c_cascade_capacity_output.txt
else
  echo "[c] skipped: gcc not installed"
fi

if command -v g++ >/dev/null 2>&1; then
  echo "[cpp] compiling cascade_threshold.cpp"
  g++ cpp/cascade_threshold.cpp -o outputs/tables/cascade_threshold_cpp
  outputs/tables/cascade_threshold_cpp > outputs/tables/cpp_cascade_threshold_output.txt
else
  echo "[cpp] skipped: g++ not installed"
fi

if command -v gfortran >/dev/null 2>&1; then
  echo "[fortran] compiling cascade_threshold.f90"
  gfortran fortran/cascade_threshold.f90 -o outputs/tables/cascade_threshold_fortran
  outputs/tables/cascade_threshold_fortran > outputs/tables/fortran_cascade_threshold_output.txt
else
  echo "[fortran] skipped: gfortran not installed"
fi

echo "Workflow complete. Outputs are in: $ARTICLE_DIR/outputs"
