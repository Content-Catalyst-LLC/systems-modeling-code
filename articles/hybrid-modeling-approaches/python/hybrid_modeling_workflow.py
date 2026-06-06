#!/usr/bin/env python3
"""
Hybrid modeling workflow.

Dependency-light workflow demonstrating:

1. Heterogeneous agents
2. Demand generation
3. Queue pressure
4. Service capacity
5. Feedback from operational pressure to agent behavior
6. Scenario comparison
7. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass
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
    n_agents: int
    n_steps: int
    service_capacity: int
    pressure_sensitivity: float
    baseline_low: float
    baseline_high: float
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
    rows = read_csv(DATA / "hybrid_scenarios.csv")
    return [
        Scenario(
            name=row["scenario"],
            n_agents=int(row["n_agents"]),
            n_steps=int(row["n_steps"]),
            service_capacity=int(row["service_capacity"]),
            pressure_sensitivity=float(row["pressure_sensitivity"]),
            baseline_low=float(row["baseline_low"]),
            baseline_high=float(row["baseline_high"]),
            seed=int(row["seed"]),
        )
        for row in rows
    ]


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def simulate(scenario: Scenario) -> tuple[list[dict[str, object]], dict[str, object]]:
    rng = random.Random(scenario.seed)

    propensities = [
        rng.uniform(scenario.baseline_low, scenario.baseline_high)
        for _ in range(scenario.n_agents)
    ]

    queue_length = 0
    rows: list[dict[str, object]] = []

    for time in range(scenario.n_steps):
        pressure = queue_length / max(1, scenario.service_capacity)

        effective_propensities = [
            clamp(propensity - scenario.pressure_sensitivity * pressure)
            for propensity in propensities
        ]

        arrivals = sum(1 for probability in effective_propensities if rng.random() < probability)
        available_work = queue_length + arrivals
        served = min(scenario.service_capacity, available_work)
        queue_length = max(0, available_work - served)

        utilization = served / scenario.service_capacity
        arrival_share = arrivals / scenario.n_agents
        coupling_residual = abs(arrivals - served)

        rows.append({
            "scenario": scenario.name,
            "time": time,
            "arrivals": arrivals,
            "served": served,
            "queue_length": queue_length,
            "queue_pressure": round(pressure, 6),
            "arrival_share": round(arrival_share, 6),
            "utilization": round(utilization, 6),
            "mean_effective_propensity": round(mean(effective_propensities), 6),
            "coupling_residual": coupling_residual,
        })

    queue_values = [int(row["queue_length"]) for row in rows]
    arrival_values = [int(row["arrivals"]) for row in rows]
    utilization_values = [float(row["utilization"]) for row in rows]
    residual_values = [float(row["coupling_residual"]) for row in rows]

    summary = {
        "scenario": scenario.name,
        "n_agents": scenario.n_agents,
        "n_steps": scenario.n_steps,
        "service_capacity": scenario.service_capacity,
        "pressure_sensitivity": scenario.pressure_sensitivity,
        "total_arrivals": sum(arrival_values),
        "average_arrivals": round(mean(arrival_values), 6),
        "average_queue_length": round(mean(queue_values), 6),
        "maximum_queue_length": max(queue_values),
        "average_utilization": round(mean(utilization_values), 6),
        "average_coupling_residual": round(mean(residual_values), 6),
        "final_queue_length": queue_values[-1],
        "diagnostic": (
            "persistent operational pressure"
            if mean(queue_values) > scenario.service_capacity
            else "queue pressure contained under current coupling assumptions"
        ),
    }

    return rows, summary


def validate(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {
        "average_queue_length": (0.0, 10000.0),
        "maximum_queue_length": (0.0, 10000.0),
        "average_utilization": (0.0, 1.0),
        "final_queue_length": (0.0, 10000.0),
        "average_coupling_residual": (0.0, 10000.0),
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

    all_rows: list[dict[str, object]] = []
    summaries: list[dict[str, object]] = []

    for scenario in scenarios:
        rows, summary = simulate(scenario)
        all_rows.extend(rows)
        summaries.append(summary)

    write_csv(TABLES / "python_hybrid_module_registry.csv", read_csv(DATA / "module_registry.csv"))
    write_csv(TABLES / "python_hybrid_interface_inventory.csv", read_csv(DATA / "interface_inventory.csv"))
    write_csv(TABLES / "python_hybrid_agent_queue_timeseries.csv", all_rows)
    write_csv(TABLES / "python_hybrid_agent_queue_summary.csv", summaries)
    write_csv(TABLES / "python_hybrid_agent_queue_validation.csv", validate(summaries))

    print("Hybrid modeling workflow complete.")
    print(TABLES / "python_hybrid_agent_queue_summary.csv")


if __name__ == "__main__":
    main()
