# Assumptions and Limitations

## Assumptions

- Parameter ranges are synthetic and illustrative.
- Inputs are sampled independently in the core workflows.
- Rank correlation is used as a dependency-light sensitivity diagnostic.
- The model recurrence is intentionally compact and transparent.
- Validation targets check numerical plausibility, not empirical truth.

## Limitations

- No real system is calibrated.
- No formal Sobol or Morris estimator is implemented in the dependency-light core workflow.
- Parameter correlations are not represented.
- Structural sensitivity is documented but not exhaustively simulated.
- Results should not be treated as decision guidance.
