# Validation Protocol

Validation should match model purpose.

## Structural validation

- Are state variables meaningful?
- Are causal relationships plausible?
- Are feedback loops represented correctly?
- Are boundaries documented?
- Are excluded variables acknowledged?

## Behavioral validation

- Do outputs behave plausibly under baseline conditions?
- Do extreme conditions produce interpretable results?
- Do shocks propagate through expected pathways?
- Does higher redundancy reduce loss?
- Does higher recovery improve final state?

## Sensitivity and uncertainty

- Which parameters dominate results?
- Are results robust across plausible parameter ranges?
- Which assumptions deserve empirical calibration?
- What decision would change if a parameter changed?

## Reproducibility

- Can a clean checkout regenerate outputs?
- Are input files versioned?
- Are scripts deterministic or seeded?
- Are generated outputs clearly separated from source code?
