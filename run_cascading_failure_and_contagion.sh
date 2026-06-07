#!/usr/bin/env bash
set -euo pipefail
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/articles/cascading-failure-and-contagion/run_all.sh"
