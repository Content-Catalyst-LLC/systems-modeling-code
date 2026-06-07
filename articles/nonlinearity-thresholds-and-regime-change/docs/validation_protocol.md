# Validation Protocol

For this synthetic companion model, validation checks workflow integrity and plausible numerical behavior.

## Checks

- Nonlinearity taxonomy is exported.
- Domain examples are exported.
- Scenario trajectories are generated.
- Summary diagnostics are generated.
- System state remains between 0 and 100.
- Pressure remains nonnegative.
- Damage and recovery flows remain nonnegative.
- Net flow remains finite.
- Rolling autocorrelation remains between -1 and 1 when available.

## Professional extension

Applied use should add empirical validation, behavior reproduction, threshold estimation, model comparison, uncertainty propagation, sensitivity analysis, spatial analysis, and distributional impact assessment.
