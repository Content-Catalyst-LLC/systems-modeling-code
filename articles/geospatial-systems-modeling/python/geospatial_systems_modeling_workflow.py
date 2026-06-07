#!/usr/bin/env python3
"""
Geospatial systems modeling workflow.

Dependency-light workflow demonstrating:

1. Synthetic spatial grid generation
2. Hazard, population, and vulnerability surfaces
3. Distance-based service accessibility
4. Risk and service-gap scoring
5. Priority-zone classification
6. Scenario comparison and validation checks
7. Spatial component, data-structure, scale-risk, and ethics taxonomies

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import math
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

    fieldnames: list[str] = []
    for row in rows:
        for key in row:
            if key not in fieldnames:
                fieldnames.append(key)

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def distance(x1: float, y1: float, x2: float, y2: float) -> float:
    return math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)


def percentile(values: list[float], p: float) -> float:
    sorted_values = sorted(values)
    index = min(len(sorted_values) - 1, max(0, round((len(sorted_values) - 1) * p)))
    return sorted_values[index]


def services_for_shift(service_shift: int, capacity_multiplier: float) -> list[dict[str, object]]:
    base_services = [
        {"service_id": "clinic_a", "x": 5 + service_shift, "y": 6, "capacity": 900},
        {"service_id": "clinic_b", "x": 9, "y": 20 - service_shift, "capacity": 650},
        {"service_id": "clinic_c", "x": 18 - service_shift, "y": 10 + service_shift, "capacity": 800},
        {"service_id": "clinic_d", "x": 22, "y": 21, "capacity": 500},
    ]

    adjusted = []
    for item in base_services:
        adjusted.append({
            "service_id": item["service_id"],
            "x": int(item["x"]),
            "y": int(item["y"]),
            "capacity": round(float(item["capacity"]) * capacity_multiplier, 6),
        })
    return adjusted


def simulate_scenario(scenario_row: dict[str, str]) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    scenario = scenario_row["scenario"]
    grid_size = int(float(scenario_row["grid_size"]))
    hazard_multiplier = float(scenario_row["hazard_multiplier"])
    vulnerability_multiplier = float(scenario_row["vulnerability_multiplier"])
    population_multiplier = float(scenario_row["population_multiplier"])
    service_capacity_multiplier = float(scenario_row["service_capacity_multiplier"])
    service_shift = int(float(scenario_row["service_shift"]))

    rng = random.Random(42)
    center_x = (grid_size + 1) / 2
    center_y = (grid_size + 1) / 2

    services = services_for_shift(service_shift, service_capacity_multiplier)

    rows: list[dict[str, object]] = []

    for x in range(1, grid_size + 1):
        for y in range(1, grid_size + 1):
            distance_to_center = distance(x, y, center_x, center_y)
            distance_to_river = abs(y - (0.45 * x + 4))

            population = round((120 + 500 * math.exp(-distance_to_center / 7) + rng.gauss(0, 25)) * population_multiplier)
            population = max(0, population)

            hazard = min(1.0, (math.exp(-distance_to_river / 3) + rng.uniform(0, 0.12)) * hazard_multiplier)
            vulnerability = min(
                1.0,
                max(0.0, (0.25 + 0.45 * math.exp(-distance_to_center / 9) + rng.uniform(-0.1, 0.1)) * vulnerability_multiplier),
            )

            risk_score = hazard * population * vulnerability

            accessibility = 0.0
            nearest_service = ""
            nearest_distance = float("inf")

            for service in services:
                d = distance(x, y, float(service["x"]), float(service["y"]))
                impedance = 1.0 / (1.0 + d ** 2)
                accessibility += float(service["capacity"]) * impedance

                if d < nearest_distance:
                    nearest_distance = d
                    nearest_service = str(service["service_id"])

            service_gap_score = population / (accessibility + 1.0)

            rows.append({
                "scenario": scenario,
                "cell_id": f"{scenario}_cell_{x}_{y}",
                "x": x,
                "y": y,
                "population": population,
                "hazard": round(hazard, 6),
                "vulnerability": round(vulnerability, 6),
                "risk_score": round(risk_score, 6),
                "accessibility": round(accessibility, 6),
                "nearest_service": nearest_service,
                "nearest_distance": round(nearest_distance, 6),
                "service_gap_score": round(service_gap_score, 6),
            })

    risk_threshold = percentile([float(row["risk_score"]) for row in rows], 0.85)
    gap_threshold = percentile([float(row["service_gap_score"]) for row in rows], 0.85)

    for row in rows:
        high_risk = float(row["risk_score"]) >= risk_threshold
        high_gap = float(row["service_gap_score"]) >= gap_threshold

        if high_risk and high_gap:
            priority = "high_risk_high_service_gap"
        elif high_risk:
            priority = "high_risk"
        elif high_gap:
            priority = "high_service_gap"
        else:
            priority = "standard_monitoring"

        row["priority_zone"] = priority

    summary: dict[str, dict[str, float]] = {}

    for row in rows:
        priority = str(row["priority_zone"])
        if priority not in summary:
            summary[priority] = {
                "cell_count": 0,
                "population": 0,
                "risk_score": 0.0,
                "accessibility": 0.0,
                "service_gap_score": 0.0,
            }

        summary[priority]["cell_count"] += 1
        summary[priority]["population"] += float(row["population"])
        summary[priority]["risk_score"] += float(row["risk_score"])
        summary[priority]["accessibility"] += float(row["accessibility"])
        summary[priority]["service_gap_score"] += float(row["service_gap_score"])

    summary_rows: list[dict[str, object]] = []

    for priority, values in sorted(summary.items()):
        summary_rows.append({
            "scenario": scenario,
            "priority_zone": priority,
            "cell_count": int(values["cell_count"]),
            "population": round(values["population"], 6),
            "total_risk_score": round(values["risk_score"], 6),
            "average_risk_score": round(values["risk_score"] / max(values["cell_count"], 1), 6),
            "average_accessibility": round(values["accessibility"] / max(values["cell_count"], 1), 6),
            "total_service_gap_score": round(values["service_gap_score"], 6),
            "average_service_gap_score": round(values["service_gap_score"] / max(values["cell_count"], 1), 6),
        })

    validation_rows = [
        {
            "scenario": scenario,
            "check": "grid_cell_count_expected",
            "passed": len(rows) == grid_size * grid_size,
            "value": len(rows),
            "expected": grid_size * grid_size,
        },
        {
            "scenario": scenario,
            "check": "all_population_nonnegative",
            "passed": all(float(row["population"]) >= 0 for row in rows),
            "value": min(float(row["population"]) for row in rows),
            "expected": "minimum_population_at_least_zero",
        },
        {
            "scenario": scenario,
            "check": "all_hazard_between_zero_and_one",
            "passed": all(0 <= float(row["hazard"]) <= 1 for row in rows),
            "value": round(mean(float(row["hazard"]) for row in rows), 6),
            "expected": "hazard_in_unit_interval",
        },
        {
            "scenario": scenario,
            "check": "all_vulnerability_between_zero_and_one",
            "passed": all(0 <= float(row["vulnerability"]) <= 1 for row in rows),
            "value": round(mean(float(row["vulnerability"]) for row in rows), 6),
            "expected": "vulnerability_in_unit_interval",
        },
        {
            "scenario": scenario,
            "check": "priority_zones_created",
            "passed": len(summary_rows) > 0,
            "value": len(summary_rows),
            "expected": "positive_number_of_priority_groups",
        },
    ]

    service_rows = []
    for service in services:
        row = {"scenario": scenario}
        row.update(service)
        service_rows.append(row)

    return rows, service_rows, summary_rows, validation_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_grid_rows: list[dict[str, object]] = []
    all_service_rows: list[dict[str, object]] = []
    all_summary_rows: list[dict[str, object]] = []
    all_validation_rows: list[dict[str, object]] = []

    for scenario in scenario_rows:
        grid_rows, service_rows, summary_rows, validation_rows = simulate_scenario(scenario)
        all_grid_rows.extend(grid_rows)
        all_service_rows.extend(service_rows)
        all_summary_rows.extend(summary_rows)
        all_validation_rows.extend(validation_rows)

    write_csv(TABLES / "python_spatial_components.csv", read_csv(DATA / "spatial_components.csv"))
    write_csv(TABLES / "python_spatial_data_structures.csv", read_csv(DATA / "spatial_data_structures.csv"))
    write_csv(TABLES / "python_scale_boundary_risks.csv", read_csv(DATA / "scale_boundary_risks.csv"))
    write_csv(TABLES / "python_spatial_ethics_register.csv", read_csv(DATA / "spatial_ethics_register.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_geospatial_grid_risk_access.csv", all_grid_rows)
    write_csv(TABLES / "python_geospatial_services.csv", all_service_rows)
    write_csv(TABLES / "python_geospatial_priority_summary.csv", all_summary_rows)
    write_csv(TABLES / "python_geospatial_validation_checks.csv", all_validation_rows)

    print("Geospatial systems modeling workflow complete.")
    print(TABLES / "python_geospatial_priority_summary.csv")


if __name__ == "__main__":
    main()
