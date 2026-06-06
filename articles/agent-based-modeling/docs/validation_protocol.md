# Validation Protocol

Validation is purpose-specific. For this synthetic companion model, validation checks workflow integrity and interpretable ABM behavior.

## Checks

- Scripts run from a clean checkout.
- Scenario inputs are documented.
- Outputs are reproducible with fixed seeds.
- Probability metrics stay between 0 and 1.
- High thresholds reduce diffusion relative to low thresholds.
- More initial adopters should generally increase diffusion potential.
- Schelling-style relocation should often increase clustering.
- Single-run outputs are not overinterpreted.
- Model assumptions and limitations are documented.

## Professional extensions

- Compare model outputs with empirical patterns.
- Add replicated ensembles per scenario.
- Add global sensitivity analysis.
- Add calibration against observed data.
- Add stakeholder review for behavioral rules.
- Add a full ODD protocol document.
