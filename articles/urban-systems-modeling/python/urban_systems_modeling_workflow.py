#!/usr/bin/env python3
"""
Urban systems modeling workflow.

Dependency-light workflow demonstrating:

1. Population growth
2. Housing capacity
3. Transport and infrastructure service capacity
4. Accessibility and congestion feedback
5. Periodic policy investment
6. Scenario comparison
7. Validation checks
8. Urban component, feedback, and equity taxonomies

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
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

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def simulate_urban_system(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    population = float(row["initial_population"])
    housing = float(row["initial_housing"])
    transport = float(row["initial_transport"])
    service_capacity = float(row["initial_service_capacity"])
    growth_pressure = float(row["growth_pressure"])
    accessibility_attraction = float(row["accessibility_attraction"])
    congestion_penalty = float(row["congestion_penalty"])
    housing_constraint_penalty = float(row["housing_constraint_penalty"])
    housing_build_rate = float(row["housing_build_rate"])
    transport_investment_rate = float(row["transport_investment_rate"])
    service_investment_rate = float(row["service_investment_rate"])
    periodic_policy_investment = float(row["periodic_policy_investment"])
    policy_interval = int(float(row["policy_interval"]))
    pressure_penalty = float(row["pressure_penalty"])
    seed = int(float(row["seed"]))

    rng = random.Random(seed)

    rows: list[dict[str, object]] = []

    for time in range(1, n_steps + 1):
        accessibility = transport / (1.0 + 0.010 * population)
        congestion = population / max(transport, 1.0)
        housing_gap = max(population - housing, 0.0)
        housing_pressure = population / max(housing, 1.0)
        service_pressure = population / max(service_capacity, 1.0)
        policy_investment = periodic_policy_investment if time % policy_interval == 0 else 0.0

        pressure_drag = pressure_penalty * max(service_pressure - 1.0, 0.0)
        congestion_drag = congestion_penalty * max(congestion - 1.0, 0.0)
        housing_drag = housing_constraint_penalty * housing_gap / 20.0

        population_change = (
            growth_pressure
            + accessibility_attraction * accessibility / 55.0
            - congestion_drag
            - housing_drag
            - pressure_drag
            + rng.gauss(0.0, 0.10)
        )

        rows.append({
            "scenario": scenario,
            "time": time,
            "population": round(population, 6),
            "housing": round(housing, 6),
            "transport": round(transport, 6),
            "service_capacity": round(service_capacity, 6),
            "accessibility": round(accessibility, 6),
            "congestion": round(congestion, 6),
            "housing_gap": round(housing_gap, 6),
            "housing_pressure": round(housing_pressure, 6),
            "service_pressure": round(service_pressure, 6),
            "policy_investment": round(policy_investment, 6),
        })

        population = max(0.0, population + population_change)

        housing = max(
            0.0,
            housing
            + housing_build_rate
            + 0.020 * population
            - 0.004 * housing
        )

        transport = max(
            1.0,
            transport
            + transport_investment_rate
            + 0.010 * housing
            - 0.030 * max(congestion - 1.0, 0.0)
        )

        service_capacity = max(
            1.0,
            service_capacity
            + service_investment_rate
            + policy_investment
            - 0.003 * service_capacity
        )

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]

        maximum_service_pressure = max(float(row["service_pressure"]) for row in subset)
        maximum_housing_gap = max(float(row["housing_gap"]) for row in subset)
        maximum_congestion = max(float(row["congestion"]) for row in subset)
        average_accessibility = mean(float(row["accessibility"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_population": final["population"],
            "final_housing": final["housing"],
            "final_transport": final["transport"],
            "final_service_capacity": final["service_capacity"],
            "final_accessibility": final["accessibility"],
            "final_congestion": final["congestion"],
            "maximum_congestion": round(maximum_congestion, 6),
            "maximum_service_pressure": round(maximum_service_pressure, 6),
            "maximum_housing_gap": round(maximum_housing_gap, 6),
            "average_accessibility": round(average_accessibility, 6),
            "diagnostic_label": (
                "capacity constrained pathway"
                if maximum_service_pressure > 1.0 or maximum_housing_gap > 10
                else "managed growth pathway"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_urban_system(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_population", 0.0, 1000000.0),
            ("final_housing", 0.0, 1000000.0),
            ("final_transport", 0.0, 1000000.0),
            ("final_service_capacity", 0.0, 1000000.0),
            ("final_accessibility", 0.0, 1000000.0),
            ("final_congestion", 0.0, 1000000.0),
            ("maximum_congestion", 0.0, 1000000.0),
            ("maximum_service_pressure", 0.0, 1000000.0),
            ("maximum_housing_gap", 0.0, 1000000.0),
            ("average_accessibility", 0.0, 1000000.0),
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

    write_csv(TABLES / "python_urban_system_components.csv", read_csv(DATA / "urban_system_components.csv"))
    write_csv(TABLES / "python_urban_feedback_loops.csv", read_csv(DATA / "urban_feedback_loops.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_equity_dimensions.csv", read_csv(DATA / "equity_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_urban_system_trajectories.csv", all_rows)
    write_csv(TABLES / "python_urban_system_summary.csv", summary_rows)
    write_csv(TABLES / "python_urban_system_validation_checks.csv", validation_rows)

    print("Urban systems modeling workflow complete.")
    print(TABLES / "python_urban_system_summary.csv")


if __name__ == "__main__":
    main()
