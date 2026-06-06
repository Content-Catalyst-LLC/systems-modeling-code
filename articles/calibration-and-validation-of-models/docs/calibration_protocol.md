# Calibration Protocol

This companion folder demonstrates parameter calibration using a synthetic nonlinear dynamic model.

## Calibration questions

- Which parameters are estimated?
- Which evidence is used for calibration?
- What objective function is minimized?
- What parameter bounds are allowed?
- Are calibrated values plausible?
- How are calibration outputs documented?

## Companion method

The Python workflow uses a dependency-light grid search over growth rate and carrying capacity. The R workflow uses base R `optim`.

## Professional extension

Applied work should document:

- Data provenance
- Parameter sources
- Objective function
- Calibration algorithm
- Parameter bounds
- Fit metrics
- Identifiability concerns
- Calibration failure cases
