# Validation Protocol

Validation is purpose-specific. For this synthetic companion model, validation checks workflow integrity and plausible scenario behavior.

## Checks

- Scripts run from a clean checkout.
- Scenario definitions load correctly.
- Dynamic state remains nonnegative.
- Cost remains nonnegative.
- Resilience scores stay within configured bounds.
- Regret remains nonnegative.
- Stress scenarios differ from baseline.
- Policy scenarios differ from baseline.
- Model assumptions and limitations are documented.

## Professional extensions

- Validate model structure against domain evidence.
- Review scenarios with domain experts and stakeholders.
- Test sensitivity to parameter ranges.
- Compare historical hindcasts where possible.
- Use ensemble diagnostics for stochastic uncertainty.
- Report tail risks, worst cases, and regret.
