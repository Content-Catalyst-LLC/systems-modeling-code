#!/usr/bin/env bash
set -euo pipefail

ARTICLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ARTICLE_DIR"

bash run_all.sh

test -f outputs/tables/python_cascade_summary.csv

echo "Smoke test passed for cascading-failure-and-contagion."
