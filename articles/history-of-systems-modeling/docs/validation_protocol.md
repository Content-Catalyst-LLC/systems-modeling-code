# Validation Protocol

Validation in this folder checks whether synthetic outputs remain interpretable and whether scenario behavior follows expected structural logic.

## Checks

- Scripts run from a clean checkout.
- Scenario inputs are documented.
- Outputs are reproducible.
- State values remain in expected ranges.
- Longer delays increase overshoot risk.
- Higher growth increases peak delayed-feedback state.
- Lower carrying capacity constrains the logistic trajectory.
- Stronger balancing response reduces delayed-feedback excursions.
- Sensitivity diagnostics identify influential assumptions.

## Professional extensions

- Recreate selected historical models with documented assumptions.
- Compare historical model structures against published descriptions.
- Add calibration experiments.
- Add uncertainty ensembles.
- Add model cards and validation reports.
