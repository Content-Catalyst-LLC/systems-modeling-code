#!/usr/bin/env python3
"""
Case study: resilience modeling under climate stress.

Dependency-light workflow demonstrating:

1. Climate stress scenario generation
2. Service-level resilience simulation
3. Adaptive capacity and degradation dynamics
4. Threshold risk tracking
5. Adaptation and transformation scenarios
6. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from pathlib import Path
import csv
from typing import Any


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"
THRESHOLD = 0.55


@dataclass(frozen=True)
class Scenario:
    name: str
    exposure: float
    sensitivity: float
    initial_capacity: float
    recovery_rate: float
    investment_start: int
    investment_rate: float
    degradation_rate: float
    transformation_trigger: bool
    description: str


def read_scenarios(path: Path) -> list[Scenario]:
    scenarios: list[Scenario] = []

    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            scenarios.append(
                Scenario(
                    name=row["scenario"],
                    exposure=float(row["exposure"]),
                    sensitivity=float(row["sensitivity"]),
                    initial_capacity=float(row["initial_capacity"]),
                    recovery_rate=float(row["recovery_rate"]),
                    investment_start=int(row["investment_start"]),
                    investment_rate=float(row["investment_rate"]),
                    degradation_rate=float(row["degradation_rate"]),
                    transformation_trigger=row["transformation_trigger"] == "1",
                    description=row["description"],
                )
            )

    return scenarios


def read_csv_dicts(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
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


def clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def stress_value(scenario_name: str, time: int) -> float:
    base = 0.28 + 0.004 * time

    if scenario_name == "moderate_climate_stress":
        return base + (0.16 if time % 18 == 0 else 0.0)

    if scenario_name == "repeated_shocks":
        return base + (0.34 if time in {10, 15, 21, 33, 42} else 0.0)

    if scenario_name == "delayed_adaptation":
        return base + (0.30 if time in {12, 24, 36, 48} else 0.0)

    if scenario_name == "targeted_resilience_investment":
        return base + (0.28 if time in {14, 28, 44} else 0.0)

    if scenario_name == "compound_climate_stress":
        return base + 0.10 + (0.42 if time in {9, 17, 26, 34, 43, 52} else 0.0)

    if scenario_name == "transformation_pathway":
        return base + 0.08 + (0.36 if time in {13, 22, 31, 41, 50} else 0.0)

    return base


def simulate(scenario: Scenario, periods: int = 60) -> list[dict[str, Any]]:
    service = 0.92
    adaptive_capacity = scenario.initial_capacity
    degradation = 0.0
    transformed = False
    rows: list[dict[str, Any]] = []

    for time in range(periods + 1):
        stress = stress_value(scenario.name, time)
        investment = scenario.investment_rate if time >= scenario.investment_start else 0.0

        if (
            scenario.transformation_trigger
            and service < THRESHOLD
            and degradation > 0.18
            and not transformed
        ):
            transformed = True
            adaptive_capacity = clamp(adaptive_capacity + 0.10)
            service = max(service, 0.62)

        vulnerability_pressure = scenario.exposure * scenario.sensitivity * stress * (1.0 - adaptive_capacity)
        recovery = scenario.recovery_rate * (1.0 - service)
        next_service = clamp(service - vulnerability_pressure + recovery)

        excess_stress = max(0.0, stress - adaptive_capacity)
        next_degradation = clamp(degradation + scenario.degradation_rate * excess_stress)
        next_capacity = clamp(adaptive_capacity + investment - 0.018 * next_degradation)

        rows.append(
            {
                "scenario": scenario.name,
                "time": time,
                "climate_stress": round(stress, 6),
                "service_level": round(service, 6),
                "adaptive_capacity": round(adaptive_capacity, 6),
                "degradation": round(degradation, 6),
                "vulnerability_pressure": round(vulnerability_pressure, 6),
                "recovery": round(recovery, 6),
                "adaptation_investment": round(investment, 6),
                "below_threshold": service < THRESHOLD,
                "transformed": transformed,
            }
        )

        service = next_service
        degradation = next_degradation
        adaptive_capacity = next_capacity

    return rows


def summarize(rows: list[dict[str, Any]]) -> dict[str, Any]:
    service_values = [float(row["service_level"]) for row in rows]
    degradation_values = [float(row["degradation"]) for row in rows]
    capacity_values = [float(row["adaptive_capacity"]) for row in rows]
    below_values = [bool(row["below_threshold"]) for row in rows]

    threshold_crossings = 0
    for previous, current in zip(below_values, below_values[1:]):
        if not previous and current:
            threshold_crossings += 1

    time_below_threshold = sum(1 for value in below_values if value)
    final_degradation = degradation_values[-1]
    average_service = sum(service_values) / len(service_values)

    resilience_score = average_service - 0.015 * time_below_threshold - 0.35 * final_degradation

    return {
        "scenario": rows[-1]["scenario"],
        "average_service": round(average_service, 6),
        "minimum_service": round(min(service_values), 6),
        "time_below_threshold": time_below_threshold,
        "threshold_crossings": threshold_crossings,
        "final_adaptive_capacity": round(capacity_values[-1], 6),
        "final_degradation": round(final_degradation, 6),
        "transformed": any(bool(row["transformed"]) for row in rows),
        "resilience_score": round(resilience_score, 6),
    }


def main() -> None:
    scenarios = read_scenarios(DATA / "climate_resilience_scenarios.csv")
    assumptions = read_csv_dicts(DATA / "model_assumptions.csv")
    diagnostics = read_csv_dicts(DATA / "diagnostic_definitions.csv")

    all_rows: list[dict[str, Any]] = []
    summary_rows: list[dict[str, Any]] = []

    for scenario in scenarios:
        rows = simulate(scenario)
        all_rows.extend(rows)
        summary_rows.append(summarize(rows))

    scenario_rows = [asdict(scenario) for scenario in scenarios]

    validation_rows = [
        {"check": "scenario_runs_created", "passed": len(all_rows) > 0, "value": len(all_rows)},
        {
            "check": "service_level_normalized",
            "passed": all(0 <= float(row["service_level"]) <= 1 for row in all_rows),
            "value": "all_service_levels_checked",
        },
        {
            "check": "adaptive_capacity_normalized",
            "passed": all(0 <= float(row["adaptive_capacity"]) <= 1 for row in all_rows),
            "value": "all_capacity_values_checked",
        },
        {
            "check": "degradation_normalized",
            "passed": all(0 <= float(row["degradation"]) <= 1 for row in all_rows),
            "value": "all_degradation_values_checked",
        },
        {
            "check": "climate_stress_nonnegative",
            "passed": all(float(row["climate_stress"]) >= 0 for row in all_rows),
            "value": "all_climate_stress_values_checked",
        },
        {"check": "summary_created", "passed": len(summary_rows) == len(scenarios), "value": len(summary_rows)},
    ]

    write_csv(TABLES / "python_climate_resilience_scenarios.csv", scenario_rows)
    write_csv(TABLES / "python_climate_resilience_timeseries.csv", all_rows)
    write_csv(TABLES / "python_climate_resilience_summary.csv", summary_rows)
    write_csv(TABLES / "python_model_assumptions.csv", assumptions)
    write_csv(TABLES / "python_diagnostic_definitions.csv", diagnostics)
    write_csv(TABLES / "python_climate_resilience_validation_checks.csv", validation_rows)

    print("Climate resilience scenario workflow complete.")
    print(TABLES / "python_climate_resilience_summary.csv")


if __name__ == "__main__":
    main()
