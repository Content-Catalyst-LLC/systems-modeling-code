# Validation Protocol

Validation is purpose-specific. For this synthetic companion model, validation checks workflow integrity and plausible numerical behavior.

## Checks

- Scripts run from a clean checkout.
- Parameter ranges load correctly.
- State variables remain nonnegative.
- Correlation magnitudes remain between zero and one.
- Sampling outputs preserve run-level metadata.
- Local and global outputs are written separately.
- Validation diagnostics are exported.
- Model assumptions and limitations are documented.

## Professional extensions

- Validate parameter ranges with domain evidence.
- Test sensitivity to range width.
- Test parameter dependence and scenario coherence.
- Compare local, global, and structural sensitivity results.
- Use formal variance-based indices where justified.
- Review sensitivity findings with domain experts and stakeholders.
