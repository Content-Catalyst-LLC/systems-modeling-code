# Network Models

Advanced companion code for the article **Network Models**.

GitHub folder:

```text
articles/network-models/
```

This companion folder turns the article's network-modeling concepts into reproducible analytical workflows. It includes graph-theory scaffolds, adjacency-list datasets, centrality diagnostics, component analysis, diffusion and contagion simulations, threshold cascade examples, robustness tests, fragmentation diagnostics, synthetic datasets, documentation assets, SQL schemas, and multi-language examples for professional systems modeling.

## Contents

```text
c/          Low-level contagion and threshold cascade engine
cpp/        Network robustness and centrality sensitivity scanner
data/       Synthetic edge lists, node attributes, scenario parameters, validation targets
docs/       Boundary notes, edge definitions, validation protocol, responsible-use guidance
fortran/    Matrix-based network diffusion solver
go/         Network robustness diagnostics runner
julia/      Network diffusion and removal ensemble
notebooks/  Notebook-ready placeholders
outputs/    Generated tables and figures
python/     Professional standard-library centrality robustness contagion workflow
r/          Base R network metrics and fragmentation workflow
rust/       Command-line network diagnostics scaffold
sql/        SQLite schema and graph-analysis queries
```

## Professional modeling capabilities

- Graph construction from edge lists
- Node and edge attribute handling
- Degree and centrality diagnostics
- Component and fragmentation analysis
- Reachability and path-length analysis
- Random versus targeted node removal
- Simple contagion simulation
- Threshold cascade simulation
- Robustness and resilience diagnostics
- Synthetic validation checks
- SQL model-run schema
- Portable Python and R workflows
- Multi-language reproducibility scaffolds

## Quick start

From this folder:

```bash
./run_all.sh
```

Or run the core workflows:

```bash
python3 python/network_models_workflow.py
Rscript r/network_models_diagnostics.R
sqlite3 outputs/tables/network_models.sqlite < sql/network_models_schema.sql
```

Optional compiled-language examples:

```bash
gcc c/network_contagion_engine.c -lm -o outputs/network_contagion_engine && ./outputs/network_contagion_engine > outputs/tables/c_network_contagion.csv
g++ -std=c++17 cpp/network_robustness_scanner.cpp -o outputs/network_robustness_scanner && ./outputs/network_robustness_scanner > outputs/tables/cpp_network_robustness.csv
gfortran fortran/network_diffusion_solver.f90 -o outputs/network_diffusion_solver && ./outputs/network_diffusion_solver > outputs/tables/fortran_network_diffusion.csv
go run go/network_scenario_runner.go
rustc rust/network_diagnostics_cli.rs -o outputs/network_diagnostics_cli && ./outputs/network_diagnostics_cli
julia julia/network_diffusion_ensemble.jl
```

## Interpretation warning

These workflows use synthetic data. They demonstrate network-modeling structure, diagnostic design, and reproducible workflow organization. They are not calibrated empirical models of any real infrastructure, financial, ecological, social, public-health, or supply-chain network. Applied use requires domain data, relational-data validation, missing-edge assessment, uncertainty communication, stakeholder review, privacy safeguards, and boundary critique.
