# Validation Protocol

Validation is purpose-specific. For this synthetic companion model, validation checks workflow integrity and interpretable network behavior.

## Checks

- Scripts run from a clean checkout.
- Edge list loads correctly.
- All generated metrics stay within valid bounds.
- Component diagnostics remain valid after node removal.
- Targeted high-degree removal is compared with random removal.
- Contagion shares stay between zero and one.
- Threshold cascade shares stay between zero and one.
- Model assumptions and limitations are documented.

## Professional extensions

- Validate nodes against authoritative asset lists.
- Validate edges against observed relationships or flows.
- Test sensitivity to missing edges.
- Test sensitivity to weight thresholds.
- Compare simulated diffusion with observed spread.
- Add temporal network layers.
- Add directed and weighted flow logic.
