#!/usr/bin/env python3
"""
History of systems modeling workflow.

This dependency-light workflow demonstrates major historical model structures:

1. Exponential reinforcing growth
2. Logistic constrained growth
3. Delayed balancing feedback
4. Shock response
5. Scenario comparison
6. Sensitivity analysis
7. Synthetic validation checks

All data are synthetic and pedagogical.
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
class HistoricalScenario:
    name: str
    growth_rate: float
    carrying_capacity: float
    balancing_strength: float
    target: float
    delay: int
    shock_time: int
    shock_size: float
    n_steps: int = 160


def load_scenarios() -> list[HistoricalScenario]:
    rows = read_csv(DATA / "scenario_parameters.csv")
    return [
        HistoricalScenario(
            name=row["scenario"],
            growth_rate=float(row["growth_rate"]),
            carrying_capacity=float(row["carrying_capacity"]),
            balancing_strength=float(row["balancing_strength"]),
            target=float(row["target"]),
            delay=int(row["delay"]),
            shock_time=int(row["shock_time"]),
            shock_size=float(row["shock_size"]),
        )
        for row in rows
    ]


def simulate(scenario: HistoricalScenario) -> list[dict[str, object]]:
    exponential = [10.0]
    logistic = [10.0]
    delayed_feedback = [10.0]
    rows: list[dict[str, object]] = []

    for time in range(scenario.n_steps + 1):
        current_exponential = exponential[-1]
        current_logistic = logistic[-1]
        current_delayed = delayed_feedback[-1]

        delayed_index = max(0, len(delayed_feedback) - 1 - scenario.delay)
        delayed_state = delayed_feedback[delayed_index]

        exponential_next = clamp(current_exponential + scenario.growth_rate * current_exponential)

        logistic_next = clamp(
            current_logistic
            + scenario.growth_rate
            * current_logistic
            * (1.0 - current_logistic / scenario.carrying_capacity)
        )

        inflow = scenario.growth_rate * current_delayed
        outflow = scenario.balancing_strength * max(delayed_state - scenario.target, 0.0)
        shock = scenario.shock_size if time == scenario.shock_time else 0.0
        delayed_next = clamp(current_delayed + inflow - outflow + shock)

        rows.append({
            "scenario": scenario.name,
            "time": time,
            "exponential": round(current_exponential, 6),
            "logistic": round(current_logistic, 6),
            "delayed_feedback": round(current_delayed, 6),
            "delayed_state": round(delayed_state, 6),
            "delayed_feedback_inflow": round(inflow, 6),
            "delayed_feedback_outflow": round(outflow, 6),
            "shock": round(shock, 6),
        })

        exponential.append(exponential_next)
        logistic.append(logistic_next)
        delayed_feedback.append(delayed_next)

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]

        exponential = [float(row["exponential"]) for row in subset]
        logistic = [float(row["logistic"]) for row in subset]
        delayed = [float(row["delayed_feedback"]) for row in subset]
        outflows = [float(row["delayed_feedback_outflow"]) for row in subset]

        max_delayed = max(delayed)
        final_delayed = delayed[-1]
        time_to_peak = int(subset[delayed.index(max_delayed)]["time"])

        if max_delayed > max(logistic) * 1.25:
            diagnostic = "delayed feedback produces overshoot relative to logistic constraint"
        elif max(outflows) > 5:
            diagnostic = "balancing feedback becomes active after delay"
        else:
            diagnostic = "delayed feedback remains weak under current assumptions"

        output.append({
            "scenario": scenario,
            "final_exponential": round(exponential[-1], 6),
            "final_logistic": round(logistic[-1], 6),
            "final_delayed_feedback": round(final_delayed, 6),
            "maximum_delayed_feedback": round(max_delayed, 6),
            "average_delayed_feedback": round(mean(delayed), 6),
            "time_to_delayed_feedback_peak": time_to_peak,
            "maximum_delayed_feedback_outflow": round(max(outflows), 6),
            "diagnostic": diagnostic,
        })

    return output


def sensitivity(base: HistoricalScenario) -> list[dict[str, object]]:
    parameters = [
        ("growth_rate", 0.01),
        ("carrying_capacity", 10.0),
        ("balancing_strength", 0.01),
        ("target", 5.0),
        ("delay", 2),
        ("shock_size", 4.0),
    ]

    base_summary = summarize(simulate(base))[0]
    base_peak = float(base_summary["maximum_delayed_feedback"])

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
            revised_peak = float(revised_summary["maximum_delayed_feedback"])

            rows.append({
                "parameter": parameter,
                "direction": direction,
                "base_value": current,
                "revised_value": revised_value,
                "base_peak_delayed_feedback": round(base_peak, 6),
                "revised_peak_delayed_feedback": round(revised_peak, 6),
                "peak_change": round(revised_peak - base_peak, 6),
                "absolute_peak_change": round(abs(revised_peak - base_peak), 6),
            })

    return sorted(rows, key=lambda row: float(row["absolute_peak_change"]), reverse=True)


def validate(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {row["metric"]: row for row in read_csv(DATA / "validation_targets.csv")}
    diagnostics: list[dict[str, object]] = []

    for row in summary_rows:
        for metric in [
            "final_exponential",
            "final_logistic",
            "final_delayed_feedback",
            "maximum_delayed_feedback",
            "average_delayed_feedback",
            "time_to_delayed_feedback_peak",
            "maximum_delayed_feedback_outflow",
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
    rows: list[dict[str, object]] = []

    for scenario in scenarios:
        rows.extend(simulate(scenario))

    summary_rows = summarize(rows)
    sensitivity_rows = sensitivity(scenarios[0])
    validation_rows = validate(summary_rows)

    write_csv(TABLES / "python_historical_milestones.csv", read_csv(DATA / "historical_modeling_milestones.csv"))
    write_csv(TABLES / "python_historical_dynamics_timeseries.csv", rows)
    write_csv(TABLES / "python_historical_dynamics_summary.csv", summary_rows)
    write_csv(TABLES / "python_historical_dynamics_sensitivity.csv", sensitivity_rows)
    write_csv(TABLES / "python_historical_dynamics_validation.csv", validation_rows)

    print("History of systems modeling workflow complete.")
    print(TABLES / "python_historical_dynamics_summary.csv")


if __name__ == "__main__":
    main()
