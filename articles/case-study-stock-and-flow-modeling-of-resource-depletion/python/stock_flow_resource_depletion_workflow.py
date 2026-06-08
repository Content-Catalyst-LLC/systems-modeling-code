#!/usr/bin/env python3
"""
Case study: stock-and-flow modeling of resource depletion.

Dependency-light workflow demonstrating:

1. Resource stock simulation
2. Regeneration and extraction flows
3. Demand growth
4. Scarcity-triggered conservation
5. Scenario comparison
6. Depletion diagnostics and validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import csv
from typing import Optional


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


@dataclass(frozen=True)
class Scenario:
    name: str
    periods: int
    carrying_capacity: float
    initial_stock: float
    regeneration_rate: float
    initial_demand: float
    demand_growth: float
    extraction_efficiency: float
    conservation_sensitivity: float
    max_conservation: float
    reference_stock_fraction: float
    critical_threshold_fraction: float
    description: str


def read_scenarios(path: Path) -> list[Scenario]:
    scenarios: list[Scenario] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            scenarios.append(
                Scenario(
                    name=row["scenario"],
                    periods=int(row["periods"]),
                    carrying_capacity=float(row["carrying_capacity"]),
                    initial_stock=float(row["initial_stock"]),
                    regeneration_rate=float(row["regeneration_rate"]),
                    initial_demand=float(row["initial_demand"]),
                    demand_growth=float(row["demand_growth"]),
                    extraction_efficiency=float(row["extraction_efficiency"]),
                    conservation_sensitivity=float(row["conservation_sensitivity"]),
                    max_conservation=float(row["max_conservation"]),
                    reference_stock_fraction=float(row["reference_stock_fraction"]),
                    critical_threshold_fraction=float(row["critical_threshold_fraction"]),
                    description=row["description"],
                )
            )
    return scenarios


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError(f"No rows to write: {path}")

    fieldnames: list[str] = []
    for row in rows:
        for key in row:
            if key not in fieldnames:
                fieldnames.append(key)

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def simulate(scenario: Scenario) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    stock = scenario.initial_stock
    reference_stock = scenario.reference_stock_fraction * scenario.carrying_capacity
    critical_threshold = scenario.critical_threshold_fraction * scenario.carrying_capacity

    for time in range(scenario.periods):
        demand = scenario.initial_demand * ((1.0 + scenario.demand_growth) ** time)
        scarcity = max(0.0, 1.0 - stock / max(reference_stock, 1e-9))
        conservation = min(
            scenario.max_conservation,
            scenario.conservation_sensitivity * scarcity,
        )

        effective_demand = demand * (1.0 - conservation)
        regeneration = scenario.regeneration_rate * stock * (1.0 - stock / scenario.carrying_capacity)
        regeneration = max(0.0, regeneration)

        extraction_capacity = scenario.extraction_efficiency * stock
        extraction = min(effective_demand, extraction_capacity, stock + regeneration)
        unmet_demand = max(0.0, demand - extraction)
        overshoot = extraction > regeneration
        next_stock = max(0.0, stock + regeneration - extraction)

        rows.append(
            {
                "scenario": scenario.name,
                "time": time,
                "resource_stock": round(stock, 6),
                "demand": round(demand, 6),
                "scarcity": round(scarcity, 6),
                "conservation": round(conservation, 6),
                "regeneration": round(regeneration, 6),
                "extraction": round(extraction, 6),
                "unmet_demand": round(unmet_demand, 6),
                "critical_threshold": round(critical_threshold, 6),
                "below_critical_threshold": stock < critical_threshold,
                "overshoot": overshoot,
            }
        )

        stock = next_stock

    return rows


def summarize(rows: list[dict[str, object]], scenario: Scenario) -> dict[str, object]:
    stocks = [float(row["resource_stock"]) for row in rows]
    extraction = [float(row["extraction"]) for row in rows]
    regeneration = [float(row["regeneration"]) for row in rows]
    unmet_demand = [float(row["unmet_demand"]) for row in rows]
    overshoot_periods = sum(1 for row in rows if bool(row["overshoot"]))

    threshold_times = [
        int(row["time"])
        for row in rows
        if bool(row["below_critical_threshold"])
    ]

    threshold_crossing_time: Optional[int]
    threshold_crossing_time = min(threshold_times) if threshold_times else None

    initial_stock = stocks[0]
    final_stock = stocks[-1]
    depletion_ratio = 1.0 - final_stock / max(initial_stock, 1e-9)

    return {
        "scenario": scenario.name,
        "initial_stock": round(initial_stock, 6),
        "final_stock": round(final_stock, 6),
        "minimum_stock": round(min(stocks), 6),
        "depletion_ratio": round(depletion_ratio, 6),
        "cumulative_extraction": round(sum(extraction), 6),
        "cumulative_regeneration": round(sum(regeneration), 6),
        "cumulative_unmet_demand": round(sum(unmet_demand), 6),
        "overshoot_periods": overshoot_periods,
        "threshold_crossing_time": threshold_crossing_time if threshold_crossing_time is not None else "not_crossed",
    }


def main() -> None:
    scenarios = read_scenarios(DATA / "scenario_parameters.csv")

    all_rows: list[dict[str, object]] = []
    summary_rows: list[dict[str, object]] = []

    for scenario in scenarios:
        rows = simulate(scenario)
        all_rows.extend(rows)
        summary_rows.append(summarize(rows, scenario))

    validation_rows = [
        {"check": "scenario_runs_created", "passed": len(all_rows) > 0, "value": len(all_rows)},
        {"check": "resource_stock_nonnegative", "passed": all(float(row["resource_stock"]) >= 0 for row in all_rows), "value": "all_resource_stocks_checked"},
        {"check": "extraction_nonnegative", "passed": all(float(row["extraction"]) >= 0 for row in all_rows), "value": "all_extraction_values_checked"},
        {"check": "regeneration_nonnegative", "passed": all(float(row["regeneration"]) >= 0 for row in all_rows), "value": "all_regeneration_values_checked"},
        {"check": "summary_created", "passed": len(summary_rows) == len(scenarios), "value": len(summary_rows)},
    ]

    write_csv(TABLES / "python_resource_depletion_scenario_timeseries.csv", all_rows)
    write_csv(TABLES / "python_resource_depletion_scenario_summary.csv", summary_rows)
    write_csv(TABLES / "python_resource_depletion_scenario_parameters.csv", [scenario.__dict__ for scenario in scenarios])
    write_csv(TABLES / "python_resource_depletion_validation_checks.csv", validation_rows)

    print("Stock-and-flow resource depletion workflow complete.")
    print(TABLES / "python_resource_depletion_scenario_summary.csv")


if __name__ == "__main__":
    main()
