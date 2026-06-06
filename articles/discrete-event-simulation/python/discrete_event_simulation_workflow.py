#!/usr/bin/env python3
"""
Discrete event simulation workflow.

Dependency-light event-calendar workflow demonstrating:

1. Future-event list
2. Next-event time advance
3. Stochastic arrivals
4. Stochastic service
5. Queue formation
6. Multi-server resource use
7. Utilization and service-level diagnostics
8. Synthetic validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass
from heapq import heappop, heappush
from pathlib import Path
import csv
import random
from statistics import mean


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


@dataclass(frozen=True)
class Scenario:
    name: str
    arrival_rate: float
    service_rate: float
    servers: int
    simulation_horizon: float
    service_level_target: float
    seed: int


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError(f"No rows to write: {path}")

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def load_scenarios() -> list[Scenario]:
    rows = read_csv(DATA / "des_scenarios.csv")
    return [
        Scenario(
            name=row["scenario"],
            arrival_rate=float(row["arrival_rate"]),
            service_rate=float(row["service_rate"]),
            servers=int(row["servers"]),
            simulation_horizon=float(row["simulation_horizon"]),
            service_level_target=float(row["service_level_target"]),
            seed=int(row["seed"]),
        )
        for row in rows
    ]


def exponential_time(rng: random.Random, rate: float) -> float:
    if rate <= 0:
        raise ValueError("Rate must be positive.")
    return rng.expovariate(rate)


def simulate_queue(scenario: Scenario) -> tuple[list[dict[str, object]], list[dict[str, object]], dict[str, object]]:
    rng = random.Random(scenario.seed)

    event_calendar: list[tuple[float, int, str, int | None]] = []
    event_counter = 0

    queue: list[tuple[int, float]] = []
    busy_servers = 0
    entity_id = 0

    entity_records: dict[int, dict[str, float]] = {}
    event_trace: list[dict[str, object]] = []

    busy_time_area = 0.0
    queue_time_area = 0.0
    last_event_time = 0.0

    def schedule(time: float, event_type: str, entity: int | None = None) -> None:
        nonlocal event_counter
        event_counter += 1
        heappush(event_calendar, (time, event_counter, event_type, entity))

    schedule(0.0, "arrival", None)

    while event_calendar:
        current_time, _, event_type, event_entity = heappop(event_calendar)

        if current_time > scenario.simulation_horizon:
            break

        elapsed = current_time - last_event_time
        busy_time_area += busy_servers * elapsed
        queue_time_area += len(queue) * elapsed
        last_event_time = current_time

        if event_type == "arrival":
            entity_id += 1
            entity_records[entity_id] = {
                "arrival_time": current_time,
                "service_start": -1.0,
                "departure_time": -1.0,
                "service_time": -1.0,
            }

            next_arrival = current_time + exponential_time(rng, scenario.arrival_rate)
            if next_arrival <= scenario.simulation_horizon:
                schedule(next_arrival, "arrival", None)

            if busy_servers < scenario.servers:
                busy_servers += 1
                service_time = exponential_time(rng, scenario.service_rate)
                entity_records[entity_id]["service_start"] = current_time
                entity_records[entity_id]["service_time"] = service_time
                schedule(current_time + service_time, "departure", entity_id)
            else:
                queue.append((entity_id, current_time))

        elif event_type == "departure":
            if event_entity is None:
                raise ValueError("Departure event missing entity id.")

            entity_records[event_entity]["departure_time"] = current_time

            if queue:
                next_entity, _arrival_time = queue.pop(0)
                service_time = exponential_time(rng, scenario.service_rate)
                entity_records[next_entity]["service_start"] = current_time
                entity_records[next_entity]["service_time"] = service_time
                schedule(current_time + service_time, "departure", next_entity)
            else:
                busy_servers = max(0, busy_servers - 1)

        event_trace.append({
            "scenario": scenario.name,
            "time": round(current_time, 6),
            "event_type": event_type,
            "event_entity_id": event_entity if event_entity is not None else entity_id,
            "queue_length": len(queue),
            "busy_servers": busy_servers,
        })

    completed_rows: list[dict[str, object]] = []

    for entity, record in sorted(entity_records.items()):
        if record["departure_time"] < 0 or record["service_start"] < 0:
            continue

        waiting_time = record["service_start"] - record["arrival_time"]
        time_in_system = record["departure_time"] - record["arrival_time"]

        completed_rows.append({
            "scenario": scenario.name,
            "entity_id": entity,
            "arrival_time": round(record["arrival_time"], 6),
            "service_start": round(record["service_start"], 6),
            "departure_time": round(record["departure_time"], 6),
            "service_time": round(record["service_time"], 6),
            "waiting_time": round(waiting_time, 6),
            "time_in_system": round(time_in_system, 6),
            "met_service_level": waiting_time <= scenario.service_level_target,
        })

    waiting_times = [float(row["waiting_time"]) for row in completed_rows]
    time_in_system_values = [float(row["time_in_system"]) for row in completed_rows]

    utilization = busy_time_area / max(last_event_time * scenario.servers, 1e-9)
    utilization = max(0.0, min(1.0, utilization))

    summary = {
        "scenario": scenario.name,
        "arrival_rate": scenario.arrival_rate,
        "service_rate": scenario.service_rate,
        "servers": scenario.servers,
        "completed_entities": len(completed_rows),
        "average_waiting_time": round(mean(waiting_times), 6) if waiting_times else 0,
        "maximum_waiting_time": round(max(waiting_times), 6) if waiting_times else 0,
        "average_time_in_system": round(mean(time_in_system_values), 6) if time_in_system_values else 0,
        "maximum_time_in_system": round(max(time_in_system_values), 6) if time_in_system_values else 0,
        "average_queue_length_time_weighted": round(queue_time_area / max(last_event_time, 1e-9), 6),
        "utilization": round(utilization, 6),
        "service_level_share": round(
            sum(1 for row in completed_rows if row["met_service_level"]) / max(1, len(completed_rows)),
            6
        ),
        "diagnostic": "high waiting pressure" if waiting_times and mean(waiting_times) > scenario.service_level_target else "contained waiting under current assumptions",
    }

    return completed_rows, event_trace, summary


def validate_summaries(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {
        "completed_entities": (0.0, 10000.0),
        "average_waiting_time": (0.0, 100000.0),
        "maximum_waiting_time": (0.0, 100000.0),
        "average_time_in_system": (0.0, 100000.0),
        "utilization": (0.0, 1.0),
        "service_level_share": (0.0, 1.0),
        "average_queue_length_time_weighted": (0.0, 10000.0),
    }

    rows: list[dict[str, object]] = []

    for summary in summary_rows:
        for metric, (low, high) in targets.items():
            value = float(summary[metric])
            rows.append({
                "scenario": summary["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    return rows


def main() -> None:
    scenarios = load_scenarios()

    all_entities: list[dict[str, object]] = []
    all_events: list[dict[str, object]] = []
    summaries: list[dict[str, object]] = []

    for scenario in scenarios:
        entity_rows, event_rows, summary = simulate_queue(scenario)
        all_entities.extend(entity_rows)
        all_events.extend(event_rows)
        summaries.append(summary)

    write_csv(TABLES / "python_des_process_route_inventory.csv", read_csv(DATA / "process_route_inventory.csv"))
    write_csv(TABLES / "python_des_entity_trace.csv", all_entities)
    write_csv(TABLES / "python_des_event_trace.csv", all_events)
    write_csv(TABLES / "python_des_queue_summary.csv", summaries)
    write_csv(TABLES / "python_des_validation.csv", validate_summaries(summaries))

    print("Discrete event simulation workflow complete.")
    print(TABLES / "python_des_queue_summary.csv")


if __name__ == "__main__":
    main()
