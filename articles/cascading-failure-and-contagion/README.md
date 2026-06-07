# Cascading Failure and Contagion

Companion code for the Systems Modeling article **“Cascading Failure and Contagion.”**

This folder contains reproducible, dependency-light examples for network-oriented systems modeling: propagation, dependency, systemic risk, threshold failure, common-mode failure, stress testing, recovery, and resilience intervention.

## Included workflows

- `python/` — standard-library cascading failure stress test
- `r/` — base R network cascade and recovery simulation
- `sql/` — SQLite schema and exposure diagnostics
- `julia/` — minimal threshold cascade model
- `go/` — capacity-threshold diagnostic
- `rust/` — capacity-threshold diagnostic
- `c/` — capacity-threshold diagnostic
- `cpp/` — capacity-threshold diagnostic
- `fortran/` — capacity-threshold diagnostic
- `data/` — synthetic node and edge data
- `outputs/tables/` — generated CSV and SQLite outputs
- `outputs/figures/` — generated figures where available
- `notebooks/` — notebook-ready placeholder

## Run all available workflows

```bash
bash run_all.sh
```

The runner skips languages that are not installed.
