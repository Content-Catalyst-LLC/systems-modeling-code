#!/usr/bin/env python3
"""
Infrastructure systems modeling workflow.

Dependency-light workflow demonstrating:

1. Infrastructure service availability
2. Cross-sector interdependence
3. Capacity shock and recovery
4. Cascading service degradation
5. Scenario comparison
6. Validation checks
7. Infrastructure component, dependency, and equity taxonomies

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


def simulate_cascade(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    shock_start = int(float(row["shock_start"]))
    shock_end = int(float(row["shock_end"]))
    power_loss_rate = float(row["power_loss_rate"])
    power_recovery_rate = float(row["power_recovery_rate"])
    communications_dependency = float(row["communications_dependency"])
    water_power_dependency = float(row["water_power_dependency"])
    water_comms_dependency = float(row["water_comms_dependency"])
    transport_power_dependency = float(row["transport_power_dependency"])
    transport_comms_dependency = float(row["transport_comms_dependency"])

    power = 1.0
    communications = 1.0
    water = 1.0
    transport = 1.0

    rows: list[dict[str, object]] = []

    for time in range(n_steps):
        if shock_start <= time <= shock_end:
            power = max(0.45, power - power_loss_rate)
        elif time > shock_end:
            power = min(1.0, power + power_recovery_rate)
        else:
            power = 1.0

        communications = max(
            0.40,
            communications_dependency * power
            + (1.0 - communications_dependency) * communications,
        )

        water = max(
            0.35,
            water_power_dependency * power
            + water_comms_dependency * communications
            + (1.0 - water_power_dependency - water_comms_dependency) * water,
        )

        transport = max(
            0.35,
            transport_power_dependency * power
            + transport_comms_dependency * communications
            + (1.0 - transport_power_dependency - transport_comms_dependency) * transport,
        )

        composite_service = mean([power, communications, water, transport])
        unmet_service = 1.0 - composite_service

        rows.append({
            "scenario": scenario,
            "time": time,
            "power": round(power, 6),
            "communications": round(communications, 6),
            "water": round(water, 6),
            "transport": round(transport, 6),
            "composite_service": round(composite_service, 6),
            "unmet_service": round(unmet_service, 6),
            "shock_active": int(shock_start <= time <= shock_end),
        })

    return rows


def simulate_load_capacity(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    shock_start = int(float(row["shock_start"]))
    shock_end = int(float(row["shock_end"]))
    power_demand_base = float(row["power_demand_base"])
    water_demand_base = float(row["water_demand_base"])
    demand_growth = float(row["demand_growth"])
    dependency_strength = float(row["dependency_strength"])

    initial_power_capacity = 100.0
    initial_water_capacity = 90.0
    power_capacity_loss = 30.0 if scenario != "larger_power_loss" else 45.0
    recovery_rate = 2.0 if scenario != "faster_recovery" else 4.0

    power_capacity = initial_power_capacity
    rows: list[dict[str, object]] = []

    for time in range(1, n_steps + 1):
        if shock_start <= time <= shock_end:
            power_capacity = max(0.0, initial_power_capacity - power_capacity_loss)
        elif time > shock_end:
            power_capacity = min(initial_power_capacity, power_capacity + recovery_rate)
        else:
            power_capacity = initial_power_capacity

        power_demand = power_demand_base + demand_growth * time
        water_demand = water_demand_base + 0.25 * demand_growth * time
        power_availability = min(1.0, power_capacity / max(power_demand, 1.0))
        water_dependency_factor = (1.0 - dependency_strength) + dependency_strength * power_availability
        water_capacity = initial_water_capacity * water_dependency_factor

        unmet_power = max(power_demand - power_capacity, 0.0)
        unmet_water = max(water_demand - water_capacity, 0.0)
        total_unmet = unmet_power + unmet_water

        rows.append({
            "scenario": scenario,
            "time": time,
            "power_capacity": round(power_capacity, 6),
            "water_capacity": round(water_capacity, 6),
            "power_demand": round(power_demand, 6),
            "water_demand": round(water_demand, 6),
            "power_availability": round(power_availability, 6),
            "water_dependency_factor": round(water_dependency_factor, 6),
            "unmet_power": round(unmet_power, 6),
            "unmet_water": round(unmet_water, 6),
            "total_unmet": round(total_unmet, 6),
        })

    return rows


def summarize_cascade(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]
        maximum_unmet = max(float(row["unmet_service"]) for row in subset)
        total_unmet = sum(float(row["unmet_service"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_composite_service": final["composite_service"],
            "minimum_power": round(min(float(row["power"]) for row in subset), 6),
            "minimum_communications": round(min(float(row["communications"]) for row in subset), 6),
            "minimum_water": round(min(float(row["water"]) for row in subset), 6),
            "minimum_transport": round(min(float(row["transport"]) for row in subset), 6),
            "maximum_unmet_service": round(maximum_unmet, 6),
            "total_unmet_service": round(total_unmet, 6),
            "diagnostic_label": "severe cascade pathway" if maximum_unmet > 0.35 else "managed cascade pathway",
        })

    return summary_rows


def summarize_load_capacity(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        max_total_unmet = max(float(row["total_unmet"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "max_unmet_power": round(max(float(row["unmet_power"]) for row in subset), 6),
            "max_unmet_water": round(max(float(row["unmet_water"]) for row in subset), 6),
            "max_total_unmet": round(max_total_unmet, 6),
            "total_unmet_service": round(sum(float(row["total_unmet"]) for row in subset), 6),
            "minimum_power_availability": round(min(float(row["power_availability"]) for row in subset), 6),
            "minimum_water_capacity": round(min(float(row["water_capacity"]) for row in subset), 6),
            "diagnostic_label": "severe disruption pathway" if max_total_unmet > 25 else "managed disruption pathway",
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    cascade_rows: list[dict[str, object]] = []
    load_capacity_rows: list[dict[str, object]] = []

    for scenario in scenario_rows:
        cascade_rows.extend(simulate_cascade(scenario))
        load_capacity_rows.extend(simulate_load_capacity(scenario))

    cascade_summary_rows = summarize_cascade(cascade_rows)
    load_capacity_summary_rows = summarize_load_capacity(load_capacity_rows)

    validation_rows: list[dict[str, object]] = []

    for row in cascade_summary_rows:
        for metric, low, high in [
            ("final_composite_service", 0.0, 1.0),
            ("minimum_power", 0.0, 1.0),
            ("minimum_communications", 0.0, 1.0),
            ("minimum_water", 0.0, 1.0),
            ("minimum_transport", 0.0, 1.0),
            ("maximum_unmet_service", 0.0, 1.0),
            ("total_unmet_service", 0.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "workflow": "cascade",
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    for row in load_capacity_summary_rows:
        for metric, low, high in [
            ("max_unmet_power", 0.0, 1000000.0),
            ("max_unmet_water", 0.0, 1000000.0),
            ("max_total_unmet", 0.0, 1000000.0),
            ("total_unmet_service", 0.0, 1000000.0),
            ("minimum_power_availability", 0.0, 1.0),
            ("minimum_water_capacity", 0.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "workflow": "load_capacity",
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_infrastructure_system_components.csv", read_csv(DATA / "infrastructure_system_components.csv"))
    write_csv(TABLES / "python_infrastructure_dependencies.csv", read_csv(DATA / "infrastructure_dependencies.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_equity_dimensions.csv", read_csv(DATA / "equity_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_infrastructure_cascade_trajectories.csv", cascade_rows)
    write_csv(TABLES / "python_infrastructure_cascade_summary.csv", cascade_summary_rows)
    write_csv(TABLES / "python_infrastructure_load_capacity_trajectories.csv", load_capacity_rows)
    write_csv(TABLES / "python_infrastructure_load_capacity_summary.csv", load_capacity_summary_rows)
    write_csv(TABLES / "python_infrastructure_validation_checks.csv", validation_rows)

    print("Infrastructure systems modeling workflow complete.")
    print(TABLES / "python_infrastructure_cascade_summary.csv")
    print(TABLES / "python_infrastructure_load_capacity_summary.csv")


if __name__ == "__main__":
    main()
