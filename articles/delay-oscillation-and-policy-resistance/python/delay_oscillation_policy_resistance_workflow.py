#!/usr/bin/env python3
"""
Delay, oscillation, and policy resistance workflow.

Dependency-light workflow demonstrating:

1. Timely corrective feedback
2. Delayed corrective feedback
3. Overcorrection and undercorrection
4. Policy resistance through counterresponse
5. Target-crossing diagnostics
6. Overshoot and mean-gap diagnostics
7. Validation checks

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


def target_crossings(values: list[float], target: float) -> int:
    crossings = 0
    for left, right in zip(values, values[1:]):
        left_gap = left - target
        right_gap = right - target

        if left_gap == 0 or right_gap == 0:
            continue

        if (left_gap < 0 < right_gap) or (left_gap > 0 > right_gap):
            crossings += 1

    return crossings


def simulate_delay_system(row: dict[str, str], steps: int = 100) -> list[dict[str, object]]:
    scenario = row["scenario"]
    delay = int(float(row["delay"]))
    correction_strength = float(row["correction_strength"])
    counterresponse_strength = float(row["counterresponse_strength"])
    perception_smoothing = float(row["perception_smoothing"])
    natural_pressure_base = float(row["natural_pressure_base"])
    natural_pressure_slope = float(row["natural_pressure_slope"])
    target = float(row["target"])
    initial_state = float(row["initial_state"])

    state = [initial_state]
    perceived_state = [initial_state]
    intervention = [0.0]
    counterresponse = [0.0]

    for time in range(1, steps):
        perceived_state.append(
            perception_smoothing * state[-1]
            + (1.0 - perception_smoothing) * perceived_state[-1]
        )

        observed_index = max(0, time - delay)
        observed_gap = perceived_state[observed_index] - target

        action = correction_strength * max(0.0, observed_gap)
        response = counterresponse_strength * action
        natural_pressure = natural_pressure_base + natural_pressure_slope * state[-1]

        next_state = max(
            0.0,
            state[-1] + natural_pressure + response - action,
        )

        intervention.append(action)
        counterresponse.append(response)
        state.append(next_state)

    rows: list[dict[str, object]] = []

    for time in range(steps):
        rows.append({
            "scenario": scenario,
            "time": time + 1,
            "state": round(state[time], 6),
            "perceived_state": round(perceived_state[time], 6),
            "target": target,
            "intervention": round(intervention[time], 6),
            "counterresponse": round(counterresponse[time], 6),
            "target_gap": round(state[time] - target, 6),
            "delay": delay,
            "correction_strength": correction_strength,
            "counterresponse_strength": counterresponse_strength,
            "perception_smoothing": perception_smoothing,
            "natural_pressure_base": natural_pressure_base,
            "natural_pressure_slope": natural_pressure_slope,
        })

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        states = [float(row["state"]) for row in subset]
        target = float(subset[0]["target"])
        interventions = [float(row["intervention"]) for row in subset]
        counterresponses = [float(row["counterresponse"]) for row in subset]
        gaps = [float(row["target_gap"]) for row in subset]

        final_gap = states[-1] - target
        overshoot = max(0.0, max(value - target for value in states))
        undershoot = max(0.0, target - min(states))
        cumulative_intervention = sum(interventions)
        cumulative_counterresponse = sum(counterresponses)

        summary_rows.append({
            "scenario": scenario,
            "delay": subset[0]["delay"],
            "correction_strength": subset[0]["correction_strength"],
            "counterresponse_strength": subset[0]["counterresponse_strength"],
            "perception_smoothing": subset[0]["perception_smoothing"],
            "initial_state": round(states[0], 6),
            "final_state": round(states[-1], 6),
            "minimum_state": round(min(states), 6),
            "maximum_state": round(max(states), 6),
            "final_target_gap": round(final_gap, 6),
            "target_crossings": target_crossings(states, target),
            "maximum_overshoot_above_target": round(overshoot, 6),
            "maximum_undershoot_below_target": round(undershoot, 6),
            "mean_absolute_target_gap": round(mean(abs(gap) for gap in gaps), 6),
            "cumulative_intervention": round(cumulative_intervention, 6),
            "cumulative_counterresponse": round(cumulative_counterresponse, 6),
            "resistance_ratio": round(
                cumulative_counterresponse / cumulative_intervention
                if cumulative_intervention > 0
                else 0.0,
                6,
            ),
            "diagnostic_label": (
                "policy resistance"
                if cumulative_counterresponse > 0.25 * max(cumulative_intervention, 1.0)
                else "oscillation risk"
                if target_crossings(states, target) >= 2 or overshoot > 10
                else "persistent pressure"
                if states[-1] > target
                else "stabilized below target"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []

    for scenario in scenario_rows:
        all_rows.extend(simulate_delay_system(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_state", 0.0, 1000000.0),
            ("minimum_state", 0.0, 1000000.0),
            ("maximum_state", 0.0, 1000000.0),
            ("target_crossings", 0.0, 1000.0),
            ("maximum_overshoot_above_target", 0.0, 1000000.0),
            ("maximum_undershoot_below_target", 0.0, 1000000.0),
            ("mean_absolute_target_gap", 0.0, 1000000.0),
            ("cumulative_intervention", 0.0, 1000000.0),
            ("cumulative_counterresponse", 0.0, 1000000.0),
            ("resistance_ratio", 0.0, 100.0),
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

    write_csv(TABLES / "python_delay_taxonomy.csv", read_csv(DATA / "delay_taxonomy.csv"))
    write_csv(TABLES / "python_policy_resistance_examples.csv", read_csv(DATA / "policy_resistance_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_delay_oscillation_trajectories.csv", all_rows)
    write_csv(TABLES / "python_delay_oscillation_summary.csv", summary_rows)
    write_csv(TABLES / "python_delay_oscillation_validation_checks.csv", validation_rows)

    print("Delay, oscillation, and policy resistance workflow complete.")
    print(TABLES / "python_delay_oscillation_summary.csv")


if __name__ == "__main__":
    main()
