#!/usr/bin/env python3
"""
Feedback loop modeling workflow.

Dependency-light workflow demonstrating:

1. Reinforcing feedback
2. Balancing feedback
3. Logistic feedback
4. Delayed balancing feedback
5. Stock-flow accumulation
6. Overshoot and oscillation diagnostics
7. Policy-resistance scenarios

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
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


def parameters() -> dict[str, float]:
    result: dict[str, float] = {}
    for row in read_csv(DATA / "feedback_parameters.csv"):
        result[row["parameter"]] = float(row["value"])
    return result


def simulate_reinforcing(initial: float, rate: float, steps: int) -> list[float]:
    values = [initial]
    for _ in range(1, steps):
        values.append((1.0 + rate) * values[-1])
    return values


def simulate_balancing(initial: float, target: float, correction: float, steps: int) -> list[float]:
    values = [initial]
    for _ in range(1, steps):
        values.append(values[-1] + correction * (target - values[-1]))
    return values


def simulate_logistic(initial: float, rate: float, capacity: float, steps: int) -> list[float]:
    values = [initial]
    for _ in range(1, steps):
        previous = values[-1]
        values.append(previous + rate * previous * (1.0 - previous / capacity))
    return values


def simulate_delayed_balancing(
    initial: float,
    target: float,
    correction: float,
    delay: int,
    steps: int,
) -> list[float]:
    values = [initial]
    for time in range(1, steps):
        delayed_index = max(0, time - delay)
        values.append(values[-1] + correction * (target - values[delayed_index]))
    return values


def simulate_stock_flow(
    initial_stock: float,
    inflow_base: float,
    outflow_fraction: float,
    feedback_strength: float,
    steps: int,
) -> list[float]:
    stock = [initial_stock]
    for _ in range(1, steps):
        previous = stock[-1]
        inflow = inflow_base + feedback_strength * max(0.0, 60.0 - previous)
        outflow = outflow_fraction * previous
        stock.append(max(0.0, previous + inflow - outflow))
    return stock


def sign_changes(values: list[float], target: float) -> int:
    centered = [value - target for value in values]
    changes = 0
    for left, right in zip(centered, centered[1:]):
        if left == 0 or right == 0:
            continue
        if (left < 0 < right) or (left > 0 > right):
            changes += 1
    return changes


def loop_dominance_label(reinforcing: float, balancing: float, delayed_gap: float) -> str:
    if reinforcing > balancing * 1.25:
        return "reinforcing loop dominance"
    if balancing > reinforcing * 1.25 and delayed_gap < 5.0:
        return "balancing loop dominance"
    if delayed_gap >= 5.0:
        return "delayed balancing instability"
    return "mixed loop influence"


def policy_pressure_path(
    intervention_strength: float,
    behavioral_response: float,
    implementation_delay: int,
    steps: int = 72,
) -> list[float]:
    pressure = [100.0]
    for time in range(1, steps):
        prior = pressure[-1]
        intervention_effect = 0.0
        if time >= implementation_delay:
            intervention_effect = intervention_strength * prior

        response_effect = behavioral_response * max(0.0, 100.0 - prior)
        if behavioral_response > 0:
            response_effect = behavioral_response * max(0.0, 100.0 - prior + intervention_effect)

        natural_decay = 0.015 * prior
        pressure.append(max(0.0, prior - intervention_effect + response_effect - natural_decay))
    return pressure


def main() -> None:
    p = parameters()
    steps = 90

    target = p["balancing_target"]

    reinforcing = simulate_reinforcing(2.0, p["reinforcing_rate"], steps)
    balancing = simulate_balancing(2.0, target, p["balancing_correction"], steps)
    logistic = simulate_logistic(2.0, p["logistic_rate"], p["logistic_capacity"], steps)
    stock_flow = simulate_stock_flow(
        p["stock_initial"],
        p["stock_inflow_base"],
        p["stock_outflow_fraction"],
        feedback_strength=0.08,
        steps=steps,
    )

    base_trajectory_rows: list[dict[str, object]] = []
    for time in range(steps):
        base_trajectory_rows.extend([
            {
                "time": time + 1,
                "process": "reinforcing",
                "state": round(reinforcing[time], 6),
                "target": "",
                "delay": 0,
                "correction_strength": "",
            },
            {
                "time": time + 1,
                "process": "balancing",
                "state": round(balancing[time], 6),
                "target": target,
                "delay": 0,
                "correction_strength": p["balancing_correction"],
            },
            {
                "time": time + 1,
                "process": "logistic",
                "state": round(logistic[time], 6),
                "target": "",
                "delay": 0,
                "correction_strength": "",
            },
            {
                "time": time + 1,
                "process": "stock_flow",
                "state": round(stock_flow[time], 6),
                "target": 60.0,
                "delay": 0,
                "correction_strength": 0.08,
            },
        ])

    delayed_scenario_rows: list[dict[str, object]] = []
    delayed_trajectory_rows: list[dict[str, object]] = []

    for row in read_csv(DATA / "delayed_feedback_scenarios.csv"):
        scenario_id = int(row["scenario_id"])
        delay = int(row["delay"])
        correction = float(row["correction_strength"])

        delayed = simulate_delayed_balancing(
            initial=p["delay_initial_state"],
            target=p["delay_target"],
            correction=correction,
            delay=delay,
            steps=steps,
        )

        overshoot = max(delayed) - p["delay_target"]
        undershoot = p["delay_target"] - min(delayed)
        crossing_count = sign_changes(delayed, p["delay_target"])
        mean_gap = mean(abs(value - p["delay_target"]) for value in delayed)

        delayed_scenario_rows.append({
            "scenario_id": scenario_id,
            "delay": delay,
            "correction_strength": correction,
            "final_state": round(delayed[-1], 6),
            "maximum_state": round(max(delayed), 6),
            "minimum_state": round(min(delayed), 6),
            "overshoot_above_target": round(max(0.0, overshoot), 6),
            "undershoot_below_target": round(max(0.0, undershoot), 6),
            "target_crossings": crossing_count,
            "mean_absolute_target_gap": round(mean_gap, 6),
            "oscillation_risk": (
                "high"
                if crossing_count >= 4 and max(0.0, overshoot) > 5
                else "moderate"
                if crossing_count >= 2
                else "low"
            ),
        })

        for time, state in enumerate(delayed, start=1):
            delayed_trajectory_rows.append({
                "scenario_id": scenario_id,
                "time": time,
                "process": "delayed_balancing",
                "state": round(state, 6),
                "target": p["delay_target"],
                "delay": delay,
                "correction_strength": correction,
            })

    policy_rows: list[dict[str, object]] = []
    policy_summary_rows: list[dict[str, object]] = []

    for row in read_csv(DATA / "policy_resistance_scenarios.csv"):
        scenario = row["scenario"]
        intervention_strength = float(row["intervention_strength"])
        behavioral_response = float(row["behavioral_response"])
        implementation_delay = int(row["implementation_delay"])

        pressure_path = policy_pressure_path(
            intervention_strength=intervention_strength,
            behavioral_response=behavioral_response,
            implementation_delay=implementation_delay,
            steps=72,
        )

        for time, pressure in enumerate(pressure_path, start=1):
            policy_rows.append({
                "scenario": scenario,
                "time": time,
                "policy_pressure": round(pressure, 6),
                "intervention_strength": intervention_strength,
                "behavioral_response": behavioral_response,
                "implementation_delay": implementation_delay,
            })

        policy_summary_rows.append({
            "scenario": scenario,
            "initial_pressure": round(pressure_path[0], 6),
            "final_pressure": round(pressure_path[-1], 6),
            "minimum_pressure": round(min(pressure_path), 6),
            "maximum_pressure": round(max(pressure_path), 6),
            "pressure_reduction": round(pressure_path[0] - pressure_path[-1], 6),
            "policy_resistance_label": (
                "counter-feedback offsets intervention"
                if pressure_path[-1] > 70 and behavioral_response > 0
                else "intervention reduces modeled pressure"
                if pressure_path[-1] < pressure_path[0]
                else "limited modeled improvement"
            ),
        })

    diagnostic_rows = [
        {
            "process": "reinforcing",
            "initial_value": round(reinforcing[0], 6),
            "final_value": round(reinforcing[-1], 6),
            "maximum_value": round(max(reinforcing), 6),
            "minimum_value": round(min(reinforcing), 6),
            "interpretation": "self-amplifying compounding process",
        },
        {
            "process": "balancing",
            "initial_value": round(balancing[0], 6),
            "final_value": round(balancing[-1], 6),
            "maximum_value": round(max(balancing), 6),
            "minimum_value": round(min(balancing), 6),
            "interpretation": "target-seeking stabilizing process",
        },
        {
            "process": "logistic",
            "initial_value": round(logistic[0], 6),
            "final_value": round(logistic[-1], 6),
            "maximum_value": round(max(logistic), 6),
            "minimum_value": round(min(logistic), 6),
            "interpretation": "reinforcing growth constrained by balancing capacity limit",
        },
        {
            "process": "stock_flow",
            "initial_value": round(stock_flow[0], 6),
            "final_value": round(stock_flow[-1], 6),
            "maximum_value": round(max(stock_flow), 6),
            "minimum_value": round(min(stock_flow), 6),
            "interpretation": "accumulation process governed by inflow outflow and corrective feedback",
        },
    ]

    loop_dominance_rows: list[dict[str, object]] = []
    max_reinforcing = max(reinforcing)
    max_balancing = max(balancing)
    for time in range(steps):
        delayed_gap = abs(float(delayed_trajectory_rows[time]["state"]) - p["delay_target"])
        reinforcing_strength = reinforcing[time] / max_reinforcing
        balancing_strength = balancing[time] / max_balancing
        loop_dominance_rows.append({
            "time": time + 1,
            "reinforcing_strength_proxy": round(reinforcing_strength, 6),
            "balancing_strength_proxy": round(balancing_strength, 6),
            "delayed_target_gap": round(delayed_gap, 6),
            "loop_dominance_label": loop_dominance_label(
                reinforcing_strength,
                balancing_strength,
                delayed_gap,
            ),
        })

    validation_rows: list[dict[str, object]] = []
    for row in delayed_scenario_rows:
        for metric, low, high in [
            ("final_state", -1000000.0, 1000000.0),
            ("maximum_state", -1000000.0, 1000000.0),
            ("minimum_state", -1000000.0, 1000000.0),
            ("target_crossings", 0.0, 1000.0),
            ("mean_absolute_target_gap", 0.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scope": f"delayed_feedback_scenario_{row['scenario_id']}",
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    for row in policy_summary_rows:
        for metric, low, high in [
            ("initial_pressure", 0.0, 1000000.0),
            ("final_pressure", 0.0, 1000000.0),
            ("minimum_pressure", 0.0, 1000000.0),
            ("maximum_pressure", 0.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scope": row["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_feedback_loop_taxonomy.csv", read_csv(DATA / "feedback_loop_taxonomy.csv"))
    write_csv(TABLES / "python_feedback_parameters.csv", read_csv(DATA / "feedback_parameters.csv"))
    write_csv(TABLES / "python_feedback_base_trajectories.csv", base_trajectory_rows)
    write_csv(TABLES / "python_delayed_feedback_trajectories.csv", delayed_trajectory_rows)
    write_csv(TABLES / "python_delayed_feedback_scenarios.csv", delayed_scenario_rows)
    write_csv(TABLES / "python_feedback_loop_diagnostics.csv", diagnostic_rows)
    write_csv(TABLES / "python_loop_dominance_diagnostics.csv", loop_dominance_rows)
    write_csv(TABLES / "python_policy_resistance_trajectories.csv", policy_rows)
    write_csv(TABLES / "python_policy_resistance_summary.csv", policy_summary_rows)
    write_csv(TABLES / "python_feedback_validation_checks.csv", validation_rows)

    print("Feedback loop modeling workflow complete.")
    print(TABLES / "python_delayed_feedback_scenarios.csv")


if __name__ == "__main__":
    main()
