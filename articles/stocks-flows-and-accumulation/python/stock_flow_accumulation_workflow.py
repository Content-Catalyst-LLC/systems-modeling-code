#!/usr/bin/env python3
"""
Stocks, flows, and accumulation workflow.

Dependency-light workflow demonstrating:

1. Backlog accumulation
2. Resource depletion and regeneration
3. Infrastructure condition and maintenance
4. Scenario comparison
5. Net-flow diagnostics
6. Recovery-time diagnostics
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


def parameter_map() -> dict[str, float]:
    result: dict[str, float] = {}
    for row in read_csv(DATA / "stock_flow_parameters.csv"):
        result[row["parameter"]] = float(row["value"])
    return result


def simulate_scenario(scenario_row: dict[str, str], parameters: dict[str, float]) -> list[dict[str, object]]:
    scenario = scenario_row["scenario"]
    steps = int(parameters["time_steps"])

    backlog = parameters["initial_backlog"]
    resource = parameters["initial_resource"]
    condition = parameters["initial_condition"]

    rows: list[dict[str, object]] = []

    arrival_multiplier = float(scenario_row["arrival_multiplier"])
    completion_capacity_shift = float(scenario_row["completion_capacity_shift"])

    resource_extraction_before = float(scenario_row["resource_extraction_before"])
    resource_extraction_after = float(scenario_row["resource_extraction_after"])
    resource_policy_time = int(float(scenario_row["resource_policy_time"]))

    maintenance_before = float(scenario_row["maintenance_before"])
    maintenance_after = float(scenario_row["maintenance_after"])
    maintenance_policy_time = int(float(scenario_row["maintenance_policy_time"]))

    for time in range(1, steps + 1):
        if scenario in {"capacity_and_conservation", "adaptive_recovery"} and time >= 50:
            backlog_arrivals = parameters["base_arrivals"] * 0.72 * arrival_multiplier
        elif scenario == "delayed_response" and time >= 75:
            backlog_arrivals = parameters["base_arrivals"] * 0.72 * arrival_multiplier
        else:
            backlog_arrivals = parameters["base_arrivals"] * arrival_multiplier

        resource_extraction = resource_extraction_after if time >= resource_policy_time else resource_extraction_before
        maintenance = maintenance_after if time >= maintenance_policy_time else maintenance_before

        backlog_completion_capacity = (
            parameters["base_completion_capacity"]
            + completion_capacity_shift
            + parameters["completion_pressure_response"] * backlog
        )
        backlog_completions = min(backlog + backlog_arrivals, backlog_completion_capacity)
        backlog_net_flow = backlog_arrivals - backlog_completions
        backlog = max(0.0, backlog + backlog_net_flow)

        regeneration = (
            parameters["resource_growth_rate"]
            * resource
            * (1.0 - resource / parameters["resource_capacity"])
        )
        resource_net_flow = regeneration - resource_extraction
        resource = max(0.0, resource + resource_net_flow)

        wear = parameters["condition_base_wear"] + parameters["condition_wear_pressure"] * max(0.0, 100.0 - condition)
        condition_net_flow = maintenance - wear
        condition = min(100.0, max(0.0, condition + condition_net_flow))

        rows.append({
            "scenario": scenario,
            "time": time,
            "backlog": round(backlog, 6),
            "backlog_arrivals": round(backlog_arrivals, 6),
            "backlog_completions": round(backlog_completions, 6),
            "backlog_net_flow": round(backlog_net_flow, 6),
            "resource": round(resource, 6),
            "resource_regeneration": round(regeneration, 6),
            "resource_extraction": round(resource_extraction, 6),
            "resource_net_flow": round(resource_net_flow, 6),
            "infrastructure_condition": round(condition, 6),
            "condition_maintenance": round(maintenance, 6),
            "condition_wear": round(wear, 6),
            "condition_net_flow": round(condition_net_flow, 6),
        })

    return rows


def first_time_condition(rows: list[dict[str, object]], column: str, predicate) -> int | str:
    for row in rows:
        if predicate(float(row[column])):
            return int(row["time"])
    return ""


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]

        stock_specs = [
            ("backlog", "backlog", "backlog_net_flow", "lower_is_better", 75.0),
            ("resource", "resource", "resource_net_flow", "higher_is_better", 500.0),
            ("infrastructure_condition", "infrastructure_condition", "condition_net_flow", "higher_is_better", 70.0),
        ]

        for stock_name, column, net_flow_column, preferred_direction, recovery_threshold in stock_specs:
            values = [float(row[column]) for row in subset]
            net_flows = [float(row[net_flow_column]) for row in subset]

            if preferred_direction == "lower_is_better":
                recovery_time = first_time_condition(subset, column, lambda value: value <= recovery_threshold)
            else:
                recovery_time = first_time_condition(subset, column, lambda value: value >= recovery_threshold)

            summary_rows.append({
                "scenario": scenario,
                "stock": stock_name,
                "initial_value": round(values[0], 6),
                "final_value": round(values[-1], 6),
                "minimum_value": round(min(values), 6),
                "maximum_value": round(max(values), 6),
                "mean_net_flow": round(mean(net_flows), 6),
                "final_net_flow": round(net_flows[-1], 6),
                "recovery_threshold": recovery_threshold,
                "first_recovery_time": recovery_time,
                "final_direction": (
                    "accumulating"
                    if net_flows[-1] > 0
                    else "depleting"
                    if net_flows[-1] < 0
                    else "balanced"
                ),
                "interpretation": (
                    "stock pressure is lower when sustained outflow exceeds inflow"
                    if stock_name == "backlog"
                    else "resource recovery requires regeneration to exceed extraction"
                    if stock_name == "resource"
                    else "condition recovery requires maintenance to exceed wear"
                ),
            })

    return summary_rows


def main() -> None:
    parameters = parameter_map()
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario_row in scenario_rows:
        all_rows.extend(simulate_scenario(scenario_row, parameters))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []
    for row in summary_rows:
        for metric, low, high in [
            ("initial_value", 0.0, 1000000.0),
            ("final_value", 0.0, 1000000.0),
            ("minimum_value", 0.0, 1000000.0),
            ("maximum_value", 0.0, 1000000.0),
            ("mean_net_flow", -1000000.0, 1000000.0),
            ("final_net_flow", -1000000.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "stock": row["stock"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

        if row["stock"] == "infrastructure_condition":
            for metric in ["initial_value", "final_value", "minimum_value", "maximum_value"]:
                value = float(row[metric])
                validation_rows.append({
                    "scenario": row["scenario"],
                    "stock": row["stock"],
                    "metric": f"{metric}_bounded_condition",
                    "value": round(value, 6),
                    "target_low": 0.0,
                    "target_high": 100.0,
                    "passed": 0.0 <= value <= 100.0,
                })

    write_csv(TABLES / "python_stock_flow_taxonomy.csv", read_csv(DATA / "stock_flow_taxonomy.csv"))
    write_csv(TABLES / "python_domain_stock_flow_examples.csv", read_csv(DATA / "domain_stock_flow_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_stock_flow_parameters.csv", read_csv(DATA / "stock_flow_parameters.csv"))
    write_csv(TABLES / "python_stock_flow_trajectories.csv", all_rows)
    write_csv(TABLES / "python_stock_flow_summary.csv", summary_rows)
    write_csv(TABLES / "python_stock_flow_validation_checks.csv", validation_rows)

    print("Stock-flow accumulation workflow complete.")
    print(TABLES / "python_stock_flow_summary.csv")


if __name__ == "__main__":
    main()
