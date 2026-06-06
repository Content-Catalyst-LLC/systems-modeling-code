#!/usr/bin/env python3
"""
System dynamics modeling workflow.

Dependency-light workflow demonstrating:

1. Stock-flow accumulation
2. Capacity-limited reinforcing inflow
3. Delayed balancing outflow
4. Threshold-sensitive correction
5. Shock response
6. Scenario comparison
7. Sensitivity diagnostics
8. Synthetic validation checks

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
    capacity: float
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
            capacity=float(row["capacity"]),
            threshold=float(row["threshold"]),
            threshold_correction=float(row["threshold_correction"]),
            shock_time=int(row["shock_time"]),
            shock_size=float(row["shock_size"]),
        )
        for row in rows
    ]


def simulate(scenario: Scenario) -> list[dict[str, object]]:
    stock = [20.0]
    rows: list[dict[str, object]] = []

    for time in range(scenario.periods + 1):
        current = stock[-1]
        delayed_index = max(0, len(stock) - 1 - scenario.delay)
        delayed_stock = stock[delayed_index]

        inflow = scenario.growth_rate * current * (1.0 - current / scenario.capacity)
        outflow = scenario.balancing_strength * max(delayed_stock - scenario.target, 0.0)

        threshold_penalty = 0.0
        if current >= scenario.threshold:
            threshold_penalty = scenario.threshold_correction * (current - scenario.threshold)

        shock = scenario.shock_size if time == scenario.shock_time else 0.0
        next_stock = clamp(current + inflow - outflow - threshold_penalty + shock)

        rows.append({
            "scenario": scenario.name,
            "time": time,
            "stock": round(current, 6),
            "delayed_stock": round(delayed_stock, 6),
            "inflow": round(inflow, 6),
            "outflow": round(outflow, 6),
            "threshold_penalty": round(threshold_penalty, 6),
            "shock": round(shock, 6),
            "next_stock": round(next_stock, 6),
        })

        stock.append(next_stock)

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        stocks = [float(row["stock"]) for row in subset]
        inflows = [float(row["inflow"]) for row in subset]
        outflows = [float(row["outflow"]) for row in subset]
        penalties = [float(row["threshold_penalty"]) for row in subset]

        maximum_stock = max(stocks)
        minimum_stock = min(stocks)
        final_stock = stocks[-1]
        time_to_peak = int(subset[stocks.index(maximum_stock)]["time"])

        if maximum_stock > 125:
            diagnostic = "large overshoot from reinforcing growth and delayed correction"
        elif sum(1 for value in penalties if value > 0) > 45:
            diagnostic = "persistent nonlinear threshold pressure"
        elif max(outflows) > max(inflows):
            diagnostic = "balancing feedback eventually dominates reinforcing inflow"
        else:
            diagnostic = "contained trajectory under current assumptions"

        output.append({
            "scenario": scenario,
            "minimum_stock": round(minimum_stock, 6),
            "maximum_stock": round(maximum_stock, 6),
            "final_stock": round(final_stock, 6),
            "average_stock": round(mean(stocks), 6),
            "time_to_peak": time_to_peak,
            "maximum_inflow": round(max(inflows), 6),
            "maximum_outflow": round(max(outflows), 6),
            "threshold_active_periods": sum(1 for value in penalties if value > 0),
            "diagnostic": diagnostic,
        })

    return output


def sensitivity(base: Scenario) -> list[dict[str, object]]:
    parameters = [
        ("growth_rate", 0.01),
        ("balancing_strength", 0.01),
        ("target", 5.0),
        ("delay", 2),
        ("capacity", 10.0),
        ("threshold", 5.0),
        ("threshold_correction", 0.01),
        ("shock_size", 5.0),
    ]

    base_summary = summarize(simulate(base))[0]
    base_peak = float(base_summary["maximum_stock"])

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
            revised_peak = float(revised_summary["maximum_stock"])

            rows.append({
                "parameter": parameter,
                "direction": direction,
                "base_value": current,
                "revised_value": revised_value,
                "base_peak_stock": round(base_peak, 6),
                "revised_peak_stock": round(revised_peak, 6),
                "peak_change": round(revised_peak - base_peak, 6),
                "absolute_peak_change": round(abs(revised_peak - base_peak), 6),
            })

    return sorted(rows, key=lambda row: float(row["absolute_peak_change"]), reverse=True)


def validate(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {row["metric"]: row for row in read_csv(DATA / "validation_targets.csv")}
    diagnostics: list[dict[str, object]] = []

    for row in summary_rows:
        for metric in [
            "minimum_stock",
            "maximum_stock",
            "final_stock",
            "average_stock",
            "time_to_peak",
            "maximum_inflow",
            "maximum_outflow",
            "threshold_active_periods",
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

    write_csv(TABLES / "python_causal_loop_inventory.csv", read_csv(DATA / "causal_loop_inventory.csv"))
    write_csv(TABLES / "python_system_dynamics_timeseries.csv", rows)
    write_csv(TABLES / "python_system_dynamics_summary.csv", summary_rows)
    write_csv(TABLES / "python_system_dynamics_sensitivity.csv", sensitivity_rows)
    write_csv(TABLES / "python_system_dynamics_validation.csv", validation_rows)

    print("System dynamics modeling workflow complete.")
    print(TABLES / "python_system_dynamics_summary.csv")


if __name__ == "__main__":
    main()
