# Assumptions and Limitations

## Assumptions

- Interarrival times are exponentially distributed in the core workflows.
- Service times are exponentially distributed in the core workflows.
- Queue discipline is first-in-first-out.
- Resources are continuously available during the simulated horizon.
- Entities do not abandon the queue.
- Routing is simplified to one service stage.
- Service-level performance is measured against a waiting-time threshold.

## Limitations

- The model is not calibrated to empirical timestamps.
- Real service systems may require multiple entity classes and priority rules.
- No warm-up removal is included in the simple workflows.
- No real staffing schedules are represented.
- Results should not be interpreted as forecasts.
