#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import csv
from statistics import mean
import random

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


def shock_schedule(multiplier: float) -> dict[int, float]:
    return {
        int(float(row["time"])): float(row["baseline_shock"]) * multiplier
        for row in read_csv(DATA / "shock_schedule.csv")
    }


def simulate_resilience(scenario_row: dict[str, str], steps: int = 180) -> list[dict[str, object]]:
    scenario = scenario_row["scenario"]
    initial_adaptive_capacity = float(scenario_row["initial_adaptive_capacity"])
    recovery_erosion = float(scenario_row["recovery_erosion"])
    learning_gain = float(scenario_row["learning_gain"])
    shock_multiplier = float(scenario_row["shock_multiplier"])
    adaptation_floor = float(scenario_row["adaptation_floor"])

    rng = random.Random(42)
    schedule = shock_schedule(shock_multiplier)
    state = 0.0
    adaptive_capacity = initial_adaptive_capacity
    rows: list[dict[str, object]] = []

    for time in range(1, steps + 1):
        shock = schedule.get(time, 0.0)
        if time > 1:
            adaptive_capacity = max(
                adaptation_floor,
                adaptive_capacity - recovery_erosion + learning_gain * max(0.0, 1.0 - abs(state)),
            )
            state = state - adaptive_capacity * state + shock + rng.gauss(0.0, 0.025)

        performance = max(0.0, 1.0 - abs(state) / 4.0)
        rows.append({
            "scenario": scenario,
            "time": time,
            "state": round(state, 6),
            "absolute_state": round(abs(state), 6),
            "adaptive_capacity": round(adaptive_capacity, 6),
            "shock": round(shock, 6),
            "performance": round(performance, 6),
            "performance_loss": round(1.0 - performance, 6),
            "initial_adaptive_capacity": initial_adaptive_capacity,
            "recovery_erosion": recovery_erosion,
            "learning_gain": learning_gain,
            "shock_multiplier": shock_multiplier,
        })
    return rows


def recovery_time_after_shock(rows: list[dict[str, object]], shock_time: int, tolerance: float = 0.25) -> int | str:
    for row in rows:
        if int(row["time"]) >= shock_time and abs(float(row["state"])) <= tolerance:
            return int(row["time"]) - shock_time
    return ""


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    shock_times = [int(float(row["time"])) for row in read_csv(DATA / "shock_schedule.csv")]
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        states = [float(row["state"]) for row in subset]
        performances = [float(row["performance"]) for row in subset]
        losses = [float(row["performance_loss"]) for row in subset]
        capacities = [float(row["adaptive_capacity"]) for row in subset]
        recovery_times = [recovery_time_after_shock(subset, shock_time) for shock_time in shock_times]
        numeric_recovery_times = [float(value) for value in recovery_times if value != ""]

        initial_capacity = capacities[0]
        final_capacity = capacities[-1]
        min_performance = min(performances)
        diagnostic_label = (
            "adaptive recovery" if final_capacity >= initial_capacity and min_performance >= 0.55
            else "resilience weakening" if min_performance < 0.45 or sum(1 for value in recovery_times if value == "") >= 2
            else "managed disturbance"
        )

        summary_rows.append({
            "scenario": scenario,
            "final_state": round(states[-1], 6),
            "maximum_abs_state": round(max(abs(value) for value in states), 6),
            "minimum_performance": round(min_performance, 6),
            "mean_performance": round(mean(performances), 6),
            "initial_adaptive_capacity": round(initial_capacity, 6),
            "final_adaptive_capacity": round(final_capacity, 6),
            "adaptive_capacity_change": round(final_capacity - initial_capacity, 6),
            "average_recovery_time": round(mean(numeric_recovery_times), 6) if numeric_recovery_times else "",
            "unrecovered_shocks": sum(1 for value in recovery_times if value == ""),
            "cumulative_performance_loss": round(sum(losses), 6),
            "diagnostic_label": diagnostic_label,
        })
    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")
    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_resilience(scenario))

    summary_rows = summarize(all_rows)
    validation_rows: list[dict[str, object]] = []
    for row in summary_rows:
        for metric, low, high in [
            ("maximum_abs_state", 0.0, 1000000.0),
            ("minimum_performance", 0.0, 1.0),
            ("mean_performance", 0.0, 1.0),
            ("final_adaptive_capacity", 0.0, 100.0),
            ("unrecovered_shocks", 0.0, 1000.0),
            ("cumulative_performance_loss", 0.0, 1000000.0),
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

        if row["average_recovery_time"] != "":
            value = float(row["average_recovery_time"])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": "average_recovery_time",
                "value": round(value, 6),
                "target_low": 0.0,
                "target_high": 1000000.0,
                "passed": value >= 0.0,
            })

    write_csv(TABLES / "python_resilience_dimensions.csv", read_csv(DATA / "resilience_dimensions.csv"))
    write_csv(TABLES / "python_domain_resilience_examples.csv", read_csv(DATA / "domain_resilience_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_shock_schedule.csv", read_csv(DATA / "shock_schedule.csv"))
    write_csv(TABLES / "python_resilience_adaptive_system_trajectories.csv", all_rows)
    write_csv(TABLES / "python_resilience_adaptive_system_summary.csv", summary_rows)
    write_csv(TABLES / "python_resilience_adaptive_system_validation_checks.csv", validation_rows)

    print("Resilience and adaptive systems workflow complete.")
    print(TABLES / "python_resilience_adaptive_system_summary.csv")


if __name__ == "__main__":
    main()
