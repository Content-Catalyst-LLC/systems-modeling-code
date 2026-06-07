#!/usr/bin/env python3
"""
Health systems modeling workflow.

Dependency-light workflow demonstrating:

1. Care demand and service capacity
2. Backlog and unmet need
3. Workforce burnout and attrition
4. Access barriers and trust
5. Prevention and surge scenarios
6. Scenario comparison
7. Validation checks
8. Health system component, feedback, and equity taxonomies

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


def simulate_health_system(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    capacity = float(row["initial_capacity"])
    demand = float(row["initial_demand"])
    initial_demand = float(row["initial_demand"])
    trust = float(row["initial_trust"])
    demand_growth = float(row["demand_growth"])
    prevention_effect = float(row["prevention_effect"])
    workforce_recovery = float(row["workforce_recovery"])
    burnout_sensitivity = float(row["burnout_sensitivity"])
    attrition_sensitivity = float(row["attrition_sensitivity"])
    hiring_rate = float(row["hiring_rate"])
    access_barrier = float(row["access_barrier"])
    trust_loss_rate = float(row["trust_loss_rate"])
    trust_gain_rate = float(row["trust_gain_rate"])
    surge_start = int(float(row["surge_start"]))
    surge_end = int(float(row["surge_end"]))
    surge_intensity = float(row["surge_intensity"])
    seed = int(float(row["seed"]))

    rng = random.Random(seed)
    backlog = 0.0
    burnout = 0.12

    rows: list[dict[str, object]] = []

    for time in range(n_steps):
        pressure = demand / max(capacity, 1.0)
        slack = max(1.0 - pressure, 0.0)

        burnout = max(
            0.0,
            burnout
            + burnout_sensitivity * max(pressure - 1.0, 0.0)
            - workforce_recovery * slack,
        )

        attrition = attrition_sensitivity * burnout * capacity
        surge = surge_intensity if surge_start <= time <= surge_end else 0.0

        effective_capacity = max(
            0.0,
            capacity
            + hiring_rate
            - attrition
            - 0.10 * max(pressure - 1.0, 0.0) * capacity,
        )

        served = min(demand, effective_capacity)
        unmet_need = max(demand - served, 0.0)
        access_gap = access_barrier * demand + unmet_need

        backlog = max(0.0, backlog + demand - served)

        trust = bounded(
            trust
            + trust_gain_rate * slack
            - trust_loss_rate * max(pressure - 1.0, 0.0)
            - 0.004 * access_gap / max(demand, 1.0)
            + rng.gauss(0.0, 0.004),
            0.0,
            1.0,
        )

        rows.append({
            "scenario": scenario,
            "time": time,
            "demand": round(demand, 6),
            "capacity": round(capacity, 6),
            "effective_capacity": round(effective_capacity, 6),
            "pressure": round(pressure, 6),
            "slack": round(slack, 6),
            "burnout": round(burnout, 6),
            "attrition": round(attrition, 6),
            "served": round(served, 6),
            "unmet_need": round(unmet_need, 6),
            "backlog": round(backlog, 6),
            "access_gap": round(access_gap, 6),
            "trust": round(trust, 6),
            "surge_active": int(surge > 0),
        })

        capacity = effective_capacity
        prevention_reduction = prevention_effect * (time + 1)
        demand = max(
            0.0,
            initial_demand
            + demand_growth * (time + 1)
            + surge
            - prevention_reduction
            + 0.08 * backlog
            + rng.gauss(0.0, 0.25),
        )

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]

        maximum_pressure = max(float(row["pressure"]) for row in subset)
        maximum_burnout = max(float(row["burnout"]) for row in subset)
        total_unmet_need = sum(float(row["unmet_need"]) for row in subset)
        average_access_gap = mean(float(row["access_gap"]) for row in subset)
        minimum_trust = min(float(row["trust"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_capacity": final["effective_capacity"],
            "final_backlog": final["backlog"],
            "final_trust": final["trust"],
            "maximum_pressure": round(maximum_pressure, 6),
            "maximum_burnout": round(maximum_burnout, 6),
            "total_unmet_need": round(total_unmet_need, 6),
            "average_access_gap": round(average_access_gap, 6),
            "minimum_trust": round(minimum_trust, 6),
            "diagnostic_label": (
                "high strain health system pathway"
                if maximum_pressure > 1.25 or total_unmet_need > 1000 or minimum_trust < 0.35
                else "manageable health system pathway"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_health_system(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_capacity", 0.0, 1000000.0),
            ("final_backlog", 0.0, 1000000.0),
            ("final_trust", 0.0, 1.0),
            ("maximum_pressure", 0.0, 1000000.0),
            ("maximum_burnout", 0.0, 1000000.0),
            ("total_unmet_need", 0.0, 1000000.0),
            ("average_access_gap", 0.0, 1000000.0),
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

    write_csv(TABLES / "python_health_system_components.csv", read_csv(DATA / "health_system_components.csv"))
    write_csv(TABLES / "python_health_feedback_loops.csv", read_csv(DATA / "health_feedback_loops.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_equity_dimensions.csv", read_csv(DATA / "equity_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_health_system_trajectories.csv", all_rows)
    write_csv(TABLES / "python_health_system_summary.csv", summary_rows)
    write_csv(TABLES / "python_health_system_validation_checks.csv", validation_rows)

    print("Health systems modeling workflow complete.")
    print(TABLES / "python_health_system_summary.csv")


if __name__ == "__main__":
    main()
