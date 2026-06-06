# Validation Protocol

Validation checks workflow integrity and plausible numerical behavior.

## Checks

- Calibration and validation predictions are generated.
- RMSE and MAE are nonnegative.
- Bias remains finite.
- Model ranks are positive.
- Ensemble weights sum approximately to one.
- Policy scores remain between zero and one hundred.
- Regret is nonnegative.
- Model metadata are exported.

## Professional extension

Applied work should add independent validation, benchmark testing, residual diagnostics, structural review, out-of-sample checks, expert review, and sensitivity to ensemble weighting.
