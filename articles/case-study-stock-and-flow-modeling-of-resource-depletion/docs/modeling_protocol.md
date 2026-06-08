# Stock-and-Flow Resource Depletion Modeling Protocol

This case models resource depletion as a stock-and-flow system.

## Core steps

1. Define the resource stock.
2. Define regeneration inflow.
3. Define extraction outflow.
4. Define demand growth.
5. Add scarcity and conservation feedback.
6. Set thresholds.
7. Simulate scenarios.
8. Diagnose depletion, overshoot, unmet demand, and threshold crossing.
9. Test sensitivity.
10. Communicate assumptions and limitations.

## Core stock identity

```text
next stock = current stock + regeneration - extraction
```

The model is useful because it keeps attention on the stock, not just annual extraction.
