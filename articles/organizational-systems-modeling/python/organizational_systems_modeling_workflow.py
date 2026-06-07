#!/usr/bin/env python3
"""
Organizational systems modeling workflow.

Dependency-light workflow demonstrating:

1. Workload and capacity pressure
2. Learning and capability development
3. Burnout and attrition
4. Trust and coordination burden
5. Delivery and backlog dynamics
6. Scenario comparison
7. Validation checks
8. Organizational component, feedback, and ethics taxonomies

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import random
from statistics import mean


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


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


def bounded(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def simulate_organization(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    capacity = float(row["initial_capacity"])
    workload = float(row["initial_workload"])
    trust = float(row["initial_trust"])
    demand_growth = float(row["demand_growth"])
    hiring_rate = float(row["hiring_rate"])
    learning_rate = float(row["learning_rate"])
    burnout_sensitivity = float(row["burnout_sensitivity"])
    recovery_rate = float(row["recovery_rate"])
    attrition_sensitivity = float(row["attrition_sensitivity"])
    coordination_burden_rate = float(row["coordination_burden_rate"])
    trust_loss_rate = float(row["trust_loss_rate"])
    trust_gain_rate = float(row["trust_gain_rate"])
    seed = int(float(row["seed"]))

    rng = random.Random(seed)
    backlog = 0.0
    burnout = 0.10

    rows: list[dict[str, object]] = []

    for time in range(n_steps):
        pressure = workload / max(capacity, 1.0)
        slack = max(1.0 - pressure, 0.0)

        learning = learning_rate * capacity * slack * trust
        coordination_burden = coordination_burden_rate * max(pressure - 1.0, 0.0) * capacity
        burnout = max(
            0.0,
            burnout
            + burnout_sensitivity * max(pressure - 1.0, 0.0)
            - recovery_rate * slack,
        )
        attrition = attrition_sensitivity * burnout * capacity

        effective_capacity = max(
            0.0,
            capacity
            + hiring_rate
            + learning
            - attrition
            - coordination_burden,
        )

        delivery = min(workload, effective_capacity)
        backlog = max(0.0, backlog + workload - delivery)

        trust = bounded(
            trust
            + trust_gain_rate * slack
            - trust_loss_rate * max(pressure - 1.0, 0.0)
            - 0.005 * burnout
            + rng.gauss(0.0, 0.005),
            0.0,
            1.0,
        )

        rows.append({
            "scenario": scenario,
            "time": time,
            "capacity": round(capacity, 6),
            "workload": round(workload, 6),
            "pressure": round(pressure, 6),
            "slack": round(slack, 6),
            "learning": round(learning, 6),
            "coordination_burden": round(coordination_burden, 6),
            "burnout": round(burnout, 6),
            "attrition": round(attrition, 6),
            "trust": round(trust, 6),
            "delivery": round(delivery, 6),
            "backlog": round(backlog, 6),
        })

        capacity = effective_capacity
        workload = float(row["initial_workload"]) + demand_growth * (time + 1) + 0.10 * backlog

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]

        maximum_pressure = max(float(row["pressure"]) for row in subset)
        maximum_burnout = max(float(row["burnout"]) for row in subset)
        total_attrition = sum(float(row["attrition"]) for row in subset)
        average_delivery = mean(float(row["delivery"]) for row in subset)
        minimum_trust = min(float(row["trust"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_capacity": final["capacity"],
            "final_workload": final["workload"],
            "final_backlog": final["backlog"],
            "final_trust": final["trust"],
            "maximum_pressure": round(maximum_pressure, 6),
            "maximum_burnout": round(maximum_burnout, 6),
            "total_attrition": round(total_attrition, 6),
            "average_delivery": round(average_delivery, 6),
            "minimum_trust": round(minimum_trust, 6),
            "diagnostic_label": (
                "unsustainable operating pathway"
                if maximum_pressure > 1.25 or maximum_burnout > 0.60 or minimum_trust < 0.30
                else "manageable operating pathway"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_organization(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_capacity", 0.0, 1000000.0),
            ("final_workload", 0.0, 1000000.0),
            ("final_backlog", 0.0, 1000000.0),
            ("final_trust", 0.0, 1.0),
            ("maximum_pressure", 0.0, 1000000.0),
            ("maximum_burnout", 0.0, 1000000.0),
            ("total_attrition", 0.0, 1000000.0),
            ("average_delivery", 0.0, 1000000.0),
            ("minimum_trust", 0.0, 1.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_organizational_system_components.csv", read_csv(DATA / "organizational_system_components.csv"))
    write_csv(TABLES / "python_organizational_feedback_loops.csv", read_csv(DATA / "organizational_feedback_loops.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_ethics_dimensions.csv", read_csv(DATA / "ethics_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_organizational_system_trajectories.csv", all_rows)
    write_csv(TABLES / "python_organizational_system_summary.csv", summary_rows)
    write_csv(TABLES / "python_organizational_system_validation_checks.csv", validation_rows)

    print("Organizational systems modeling workflow complete.")
    print(TABLES / "python_organizational_system_summary.csv")


if __name__ == "__main__":
    main()
