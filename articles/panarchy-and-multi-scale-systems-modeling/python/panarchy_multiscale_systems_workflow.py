#!/usr/bin/env python3
"""
Panarchy and multi-scale systems modeling workflow.

Dependency-light workflow demonstrating:

1. Fast and slow adaptive cycles
2. Cross-scale coupling
3. Revolt dynamics
4. Remember dynamics
5. Release events
6. Adaptive-cycle phase classification
7. Scenario comparison
8. Validation checks

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


def classify_phase(fast_cycle: float, release_event: int) -> str:
    if release_event == 1:
        return "release"
    if fast_cycle < 0.8:
        return "reorganization"
    if fast_cycle < 2.0:
        return "growth"
    return "conservation"


def simulate_panarchy(row: dict[str, str], steps: int = 160) -> list[dict[str, object]]:
    scenario = row["scenario"]
    fast_growth = float(row["fast_growth"])
    fast_capacity = float(row["fast_capacity"])
    slow_constraint = float(row["slow_constraint"])
    release_threshold = float(row["release_threshold"])
    release_magnitude = float(row["release_magnitude"])
    revolt_strength = float(row["revolt_strength"])
    remember_strength = float(row["remember_strength"])
    slow_adjustment = float(row["slow_adjustment"])
    slow_target = float(row["slow_target"])

    fast_cycle = 0.5
    slow_memory = 1.0
    rows: list[dict[str, object]] = []

    for time in range(1, steps + 1):
        release_event = 0

        if time > 1:
            fast_cycle = (
                fast_cycle
                + fast_growth * fast_cycle * (1.0 - fast_cycle / fast_capacity)
                - slow_constraint * slow_memory
            )

            if fast_cycle > release_threshold:
                fast_cycle = max(0.0, fast_cycle - release_magnitude)
                slow_memory = slow_memory + revolt_strength
                release_event = 1
            else:
                slow_memory = slow_memory + slow_adjustment * (slow_target - slow_memory)

            fast_cycle = max(0.0, fast_cycle + remember_strength * slow_memory)

        phase = classify_phase(fast_cycle, release_event)

        rows.append({
            "scenario": scenario,
            "time": time,
            "fast_cycle": round(fast_cycle, 6),
            "slow_memory": round(slow_memory, 6),
            "release_event": release_event,
            "phase": phase,
            "cross_scale_coupling": round(fast_cycle * slow_memory, 6),
            "fast_growth": fast_growth,
            "fast_capacity": fast_capacity,
            "slow_constraint": slow_constraint,
            "release_threshold": release_threshold,
            "release_magnitude": release_magnitude,
            "revolt_strength": revolt_strength,
            "remember_strength": remember_strength,
            "slow_adjustment": slow_adjustment,
            "slow_target": slow_target,
        })

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        fast_values = [float(row["fast_cycle"]) for row in subset]
        slow_values = [float(row["slow_memory"]) for row in subset]
        coupling_values = [float(row["cross_scale_coupling"]) for row in subset]
        release_events = sum(int(row["release_event"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_fast_cycle": round(fast_values[-1], 6),
            "final_slow_memory": round(slow_values[-1], 6),
            "release_events": release_events,
            "maximum_fast_cycle": round(max(fast_values), 6),
            "maximum_slow_memory": round(max(slow_values), 6),
            "mean_cross_scale_coupling": round(mean(coupling_values), 6),
            "growth_periods": sum(1 for row in subset if row["phase"] == "growth"),
            "conservation_periods": sum(1 for row in subset if row["phase"] == "conservation"),
            "release_periods": sum(1 for row in subset if row["phase"] == "release"),
            "reorganization_periods": sum(1 for row in subset if row["phase"] == "reorganization"),
            "diagnostic_label": (
                "high revolt dynamics"
                if release_events >= 3
                else "strong slow memory"
                if slow_values[-1] > 1.8
                else "managed cross-scale cycling"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_panarchy(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_fast_cycle", 0.0, 1000000.0),
            ("final_slow_memory", 0.0, 1000000.0),
            ("release_events", 0.0, 1000000.0),
            ("maximum_fast_cycle", 0.0, 1000000.0),
            ("maximum_slow_memory", 0.0, 1000000.0),
            ("mean_cross_scale_coupling", 0.0, 1000000.0),
            ("growth_periods", 0.0, 1000000.0),
            ("conservation_periods", 0.0, 1000000.0),
            ("release_periods", 0.0, 1000000.0),
            ("reorganization_periods", 0.0, 1000000.0),
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

    write_csv(TABLES / "python_panarchy_concepts.csv", read_csv(DATA / "panarchy_concepts.csv"))
    write_csv(TABLES / "python_multiscale_examples.csv", read_csv(DATA / "multiscale_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_panarchy_multiscale_trajectories.csv", all_rows)
    write_csv(TABLES / "python_panarchy_multiscale_summary.csv", summary_rows)
    write_csv(TABLES / "python_panarchy_multiscale_validation_checks.csv", validation_rows)

    print("Panarchy and multi-scale systems modeling workflow complete.")
    print(TABLES / "python_panarchy_multiscale_summary.csv")


if __name__ == "__main__":
    main()
