#!/usr/bin/env python3
"""
Environmental systems modeling workflow.

Dependency-light workflow demonstrating:

1. Environmental stock-flow dynamics
2. Resource regeneration, extraction, restoration, and disturbance
3. Pollutant loading, decay, flow removal, and exposure
4. Intervention scenario comparison
5. Cumulative burden and resilience diagnostics
6. Validation checks
7. Environmental component and justice taxonomies

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


def simulate_environmental_stock(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    stock = float(row["initial_stock"])
    carrying_capacity = float(row["carrying_capacity"])
    growth_rate = float(row["growth_rate"])
    extraction_rate = float(row["extraction_rate"])
    restoration_rate = float(row["restoration_rate"])
    disturbance_step = int(float(row["disturbance_step"]))
    disturbance_size = float(row["disturbance_size"])

    rows: list[dict[str, object]] = []

    for time in range(1, n_steps + 1):
        regeneration = growth_rate * stock * (1.0 - stock / carrying_capacity)
        extraction = extraction_rate * stock
        restoration = restoration_rate * (carrying_capacity - stock)
        disturbance = disturbance_size if time == disturbance_step else 0.0

        next_stock = stock + regeneration - extraction + restoration - disturbance
        next_stock = max(0.0, min(carrying_capacity, next_stock))

        resilience_index = next_stock / carrying_capacity

        rows.append({
            "scenario": scenario,
            "time": time,
            "stock": round(next_stock, 6),
            "regeneration": round(regeneration, 6),
            "extraction": round(extraction, 6),
            "restoration": round(restoration, 6),
            "disturbance": round(disturbance, 6),
            "resilience_index": round(resilience_index, 6),
        })

        stock = next_stock

    return rows


def simulate_pollution_system(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    concentration = float(row["initial_concentration"])
    volume = 100.0
    baseline_load = float(row["baseline_load"])
    decay_rate = float(row["decay_rate"])
    flow_rate = float(row["flow_rate"])
    exposure_weight = float(row["exposure_weight"])
    intervention_step = int(float(row["intervention_step"]))
    load_reduction_fraction = float(row["load_reduction_fraction"])

    cumulative_exposure = 0.0
    rows: list[dict[str, object]] = []

    for time in range(1, n_steps + 1):
        active_load = baseline_load

        if time >= intervention_step:
            active_load = baseline_load * (1.0 - load_reduction_fraction)

        load_increment = active_load / volume
        decay_loss = decay_rate * concentration
        flow_loss = (flow_rate / volume) * concentration

        concentration = max(0.0, concentration + load_increment - decay_loss - flow_loss)

        exposure = concentration * exposure_weight
        cumulative_exposure += exposure

        rows.append({
            "scenario": scenario,
            "time": time,
            "active_load": round(active_load, 6),
            "concentration": round(concentration, 6),
            "decay_loss": round(decay_loss, 6),
            "flow_loss": round(flow_loss, 6),
            "exposure_weight": exposure_weight,
            "exposure": round(exposure, 6),
            "cumulative_exposure": round(cumulative_exposure, 6),
            "intervention_active": int(time >= intervention_step),
        })

    return rows


def summarize_stock(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]
        final_resilience = float(final["resilience_index"])

        summary_rows.append({
            "scenario": scenario,
            "final_stock": final["stock"],
            "minimum_stock": round(min(float(row["stock"]) for row in subset), 6),
            "maximum_stock": round(max(float(row["stock"]) for row in subset), 6),
            "final_resilience_index": final["resilience_index"],
            "average_extraction": round(mean(float(row["extraction"]) for row in subset), 6),
            "average_restoration": round(mean(float(row["restoration"]) for row in subset), 6),
            "diagnostic_label": "recovering pathway" if final_resilience >= 0.70 else "degraded pathway",
        })

    return summary_rows


def summarize_pollution(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]
        final_burden = float(final["cumulative_exposure"])

        summary_rows.append({
            "scenario": scenario,
            "final_concentration": final["concentration"],
            "maximum_concentration": round(max(float(row["concentration"]) for row in subset), 6),
            "minimum_concentration": round(min(float(row["concentration"]) for row in subset), 6),
            "average_concentration": round(mean(float(row["concentration"]) for row in subset), 6),
            "final_cumulative_exposure": final["cumulative_exposure"],
            "average_exposure": round(mean(float(row["exposure"]) for row in subset), 6),
            "diagnostic_label": "reduced burden pathway" if final_burden < 900 else "high burden pathway",
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    stock_rows: list[dict[str, object]] = []
    pollution_rows: list[dict[str, object]] = []

    for scenario in scenario_rows:
        stock_rows.extend(simulate_environmental_stock(scenario))
        pollution_rows.extend(simulate_pollution_system(scenario))

    stock_summary_rows = summarize_stock(stock_rows)
    pollution_summary_rows = summarize_pollution(pollution_rows)

    validation_rows: list[dict[str, object]] = []

    for row in stock_summary_rows:
        for metric, low, high in [
            ("final_stock", 0.0, 1000000.0),
            ("minimum_stock", 0.0, 1000000.0),
            ("maximum_stock", 0.0, 1000000.0),
            ("final_resilience_index", 0.0, 1000000.0),
            ("average_extraction", 0.0, 1000000.0),
            ("average_restoration", 0.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "workflow": "environmental_stock",
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    for row in pollution_summary_rows:
        for metric, low, high in [
            ("final_concentration", 0.0, 1000000.0),
            ("maximum_concentration", 0.0, 1000000.0),
            ("minimum_concentration", 0.0, 1000000.0),
            ("average_concentration", 0.0, 1000000.0),
            ("final_cumulative_exposure", 0.0, 1000000.0),
            ("average_exposure", 0.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "workflow": "pollution_exposure",
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_environmental_system_components.csv", read_csv(DATA / "environmental_system_components.csv"))
    write_csv(TABLES / "python_environmental_feedback_loops.csv", read_csv(DATA / "environmental_feedback_loops.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_environmental_justice_dimensions.csv", read_csv(DATA / "environmental_justice_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_environmental_stock_trajectories.csv", stock_rows)
    write_csv(TABLES / "python_environmental_stock_summary.csv", stock_summary_rows)
    write_csv(TABLES / "python_pollution_exposure_trajectories.csv", pollution_rows)
    write_csv(TABLES / "python_pollution_exposure_summary.csv", pollution_summary_rows)
    write_csv(TABLES / "python_environmental_validation_checks.csv", validation_rows)

    print("Environmental systems modeling workflow complete.")
    print(TABLES / "python_environmental_stock_summary.csv")
    print(TABLES / "python_pollution_exposure_summary.csv")


if __name__ == "__main__":
    main()
