# Synchronization Rules

Hybrid models require explicit synchronization rules.

## Companion model assumptions

- One model step is one synthetic decision period.
- Agent demand is calculated first.
- Queue service then processes available demand.
- Queue pressure is calculated from remaining queue length.
- Queue pressure affects agent demand in the next step.
- R aggregate-agent workflow uses one shared time step for both modules.

## Professional extension

Applied hybrid models should define:

- Master clock
- Substep rules
- Exchange frequency
- Aggregation windows
- Disaggregation rules
- Unit transformations
- Interface validation checks
- Uncertainty transfer across modules
