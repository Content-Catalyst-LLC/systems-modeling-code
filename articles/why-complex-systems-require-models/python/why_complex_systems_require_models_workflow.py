#!/usr/bin/env python3
"""
Why complex systems require models.

Dependency-light workflow demonstrating:

1. Reinforcing feedback
2. Delayed balancing feedback
3. Threshold-sensitive correction
4. Shock response
5. Scenario comparison
6. Sensitivity analysis
7. Validation against synthetic targets

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
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


def clamp(value: float, low: float = 0.0, high: float = 250.0) -> float:
    return max(low, min(high, value))


@dataclass(frozen=True)
class Scenario:
    name: str
    growth_rate: float
    balancing_strength: float
    target: float
    delay: int
    threshold: float
    threshold_correction: float
    shock_time: int
    shock_size: float
    periods: int = 160


def load_scenarios() -> list[Scenario]:
    rows = read_csv(DATA / "scenario_parameters.csv")
    return [
        Scenario(
            name=row["scenario"],
            growth_rate=float(row["growth_rate"]),
            balancing_strength=float(row["balancing_strength"]),
            target=float(row["target"]),
            delay=int(row["delay"]),
            threshold=float(row["threshold"]),
            threshold_correction=float(row["threshold_correction"]),
            shock_time=int(row["shock_time"]),
            shock_size=float(row["shock_size"]),
        )
        for row in rows
    ]


def simulate(scenario: Scenario) -> list[dict[str, object]]:
    state = [12.0]
    rows: list[dict[str, object]] = []

    for time in range(scenario.periods + 1):
        current = state[-1]
        delayed_index = max(0, len(state) - 1 - scenario.delay)
        delayed_state = state[delayed_index]

        inflow = scenario.growth_rate * current
        balancing_outflow = scenario.balancing_strength * max(delayed_state - scenario.target, 0.0)

        threshold_penalty = 0.0
        if current >= scenario.threshold:
            threshold_penalty = scenario.threshold_correction * (current - scenario.threshold)

        shock = scenario.shock_size if time == scenario.shock_time else 0.0
        next_state = clamp(current + inflow - balancing_outflow - threshold_penalty + shock)

        rows.append({
            "scenario": scenario.name,
            "time": time,
            "state": round(current, 6),
            "delayed_state": round(delayed_state, 6),
            "inflow": round(inflow, 6),
            "balancing_outflow": round(balancing_outflow, 6),
            "threshold_penalty": round(threshold_penalty, 6),
            "shock": round(shock, 6),
            "next_state": round(next_state, 6),
        })

        state.append(next_state)

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        states = [float(row["state"]) for row in subset]
        threshold_penalties = [float(row["threshold_penalty"]) for row in subset]
        outflows = [float(row["balancing_outflow"]) for row in subset]

        maximum_state = max(states)
        minimum_state = min(states)
        final_state = states[-1]
        average_state = mean(states)
        maximum_overshoot = max(maximum_state - states[0], 0.0)
        time_to_peak = int(subset[states.index(maximum_state)]["time"])

        if maximum_state >= 125:
            diagnostic = "severe overshoot from reinforcing growth and delayed correction"
        elif sum(1 for value in threshold_penalties if value > 0) > 50:
            diagnostic = "persistent threshold pressure"
        elif max(outflows) > 10:
            diagnostic = "balancing feedback eventually dominates growth"
        else:
            diagnostic = "contained trajectory under current assumptions"

        output.append({
            "scenario": scenario,
            "minimum_state": round(minimum_state, 6),
            "maximum_state": round(maximum_state, 6),
            "final_state": round(final_state, 6),
            "average_state": round(average_state, 6),
            "maximum_overshoot": round(maximum_overshoot, 6),
            "time_to_peak": time_to_peak,
            "threshold_active_periods": sum(1 for value in threshold_penalties if value > 0),
            "maximum_balancing_outflow": round(max(outflows), 6),
            "diagnostic": diagnostic,
        })

    return output


def sensitivity(base: Scenario) -> list[dict[str, object]]:
    parameters = [
        ("growth_rate", 0.01),
        ("balancing_strength", 0.01),
        ("target", 5.0),
        ("delay", 2),
        ("threshold", 5.0),
        ("threshold_correction", 0.01),
        ("shock_size", 4.0),
    ]

    base_summary = summarize(simulate(base))[0]
    base_final = float(base_summary["final_state"])
    base_peak = float(base_summary["maximum_state"])

    rows: list[dict[str, object]] = []

    for parameter, delta in parameters:
        current = getattr(base, parameter)

        for direction in [-1, 1]:
            if parameter == "delay":
                revised_value = max(0, int(current + direction * delta))
            else:
                revised_value = max(0.0, float(current) + direction * float(delta))

            revised = replace(base, name=f"{base.name}_{parameter}_{direction}", **{parameter: revised_value})
            revised_summary = summarize(simulate(revised))[0]
            revised_final = float(revised_summary["final_state"])
            revised_peak = float(revised_summary["maximum_state"])

            rows.append({
                "parameter": parameter,
                "direction": direction,
                "base_value": current,
                "revised_value": revised_value,
                "base_final_state": round(base_final, 6),
                "revised_final_state": round(revised_final, 6),
                "final_state_change": round(revised_final - base_final, 6),
                "base_peak_state": round(base_peak, 6),
                "revised_peak_state": round(revised_peak, 6),
                "peak_state_change": round(revised_peak - base_peak, 6),
                "absolute_peak_change": round(abs(revised_peak - base_peak), 6),
            })

    return sorted(rows, key=lambda row: float(row["absolute_peak_change"]), reverse=True)


def validate(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {row["metric"]: row for row in read_csv(DATA / "validation_targets.csv")}
    diagnostics: list[dict[str, object]] = []

    for row in summary_rows:
        for metric in [
            "minimum_state",
            "maximum_state",
            "final_state",
            "maximum_overshoot",
            "time_to_peak",
            "threshold_active_periods",
            "maximum_balancing_outflow",
        ]:
            target = targets[metric]
            value = float(row[metric])
            low = float(target["target_low"])
            high = float(target["target_high"])

            diagnostics.append({
                "scenario": row["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
                "notes": target["notes"],
            })

    return diagnostics


def main() -> None:
    TABLES.mkdir(parents=True, exist_ok=True)

    scenarios = load_scenarios()
    all_rows: list[dict[str, object]] = []

    for scenario in scenarios:
        all_rows.extend(simulate(scenario))

    summary_rows = summarize(all_rows)
    sensitivity_rows = sensitivity(scenarios[0])
    validation_rows = validate(summary_rows)

    write_csv(TABLES / "python_dynamic_system_timeseries.csv", all_rows)
    write_csv(TABLES / "python_dynamic_system_summary.csv", summary_rows)
    write_csv(TABLES / "python_dynamic_system_sensitivity.csv", sensitivity_rows)
    write_csv(TABLES / "python_dynamic_system_validation.csv", validation_rows)

    print("Why complex systems require models workflow complete.")
    print(TABLES / "python_dynamic_system_summary.csv")


if __name__ == "__main__":
    main()
