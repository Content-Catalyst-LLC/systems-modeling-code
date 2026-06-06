# Event Calendar Design

A discrete event simulation advances from one scheduled event to the next.

## Event-calendar loop

1. Select the earliest event from the future-event list.
2. Advance the simulation clock to that event time.
3. Update the system state.
4. Schedule future events caused by the current event.
5. Record performance metrics.
6. Repeat until the stopping condition is reached.

## Events in the companion workflow

- `arrival`
- `departure`

## State variables

- Queue length
- Busy servers
- Entity arrival time
- Entity service start time
- Entity departure time
- Resource busy-time area
- Queue-length time area

## Professional extension

Applied DES projects usually add more event types, including service starts, transfers, routing decisions, failures, repairs, batch releases, appointment arrivals, priority changes, and shift-change events.
