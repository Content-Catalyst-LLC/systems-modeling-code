# Validation Protocol

Validation is purpose-specific. For this synthetic companion model, validation checks workflow integrity and queueing plausibility.

## Checks

- Scripts run from a clean checkout.
- Event calendar processes arrivals and departures in chronological order.
- Resources are not released below zero.
- Queue lengths remain nonnegative.
- Utilization remains between zero and one.
- Service-level share remains between zero and one.
- Higher arrival pressure generally increases waiting.
- Additional server capacity generally reduces waiting pressure.
- Model assumptions and limitations are documented.

## Professional extensions

- Compare simulated waiting times with observed process timestamps.
- Validate service-time and interarrival-time distributions.
- Add warm-up and steady-state analysis.
- Run replications and confidence intervals.
- Add sensitivity analysis over priority rules.
- Add domain expert process validation.
