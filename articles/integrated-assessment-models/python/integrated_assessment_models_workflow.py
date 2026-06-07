#!/usr/bin/env python3
"""Synthetic integrated assessment modeling workflow."""
from __future__ import annotations

from pathlib import Path
import csv
import math
from statistics import mean

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
TABLES = ROOT / "outputs" / "tables"


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


def simulate(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    start_year = int(float(row["start_year"]))
    end_year = int(float(row["end_year"]))
    step = int(float(row["step"]))
    output = float(row["initial_output"])
    productivity_growth = float(row["productivity_growth"])
    emissions_intensity = float(row["initial_emissions_intensity"])
    emissions_intensity_decline = float(row["emissions_intensity_decline"])
    mitigation_rate = float(row["mitigation_start"])
    mitigation_growth = float(row["mitigation_growth"])
    max_mitigation = float(row["max_mitigation"])
    damage_coefficient = float(row["damage_coefficient"])
    mitigation_cost_scale = float(row["mitigation_cost_scale"])
    discount_rate = float(row["discount_rate"])

    atmospheric_pressure = 1.0
    temperature_proxy = 1.2
    rows: list[dict[str, object]] = []

    for index, year in enumerate(range(start_year, end_year + 1, step)):
        if index > 0:
            output *= (1.0 + productivity_growth) ** step
            emissions_intensity = max(0.02, emissions_intensity * (1.0 - emissions_intensity_decline) ** step)
            mitigation_rate = min(max_mitigation, mitigation_rate + mitigation_growth)

        emissions = output * emissions_intensity * (1.0 - mitigation_rate)
        if index > 0:
            atmospheric_pressure = max(0.0, atmospheric_pressure + 0.012 * emissions - 0.010 * atmospheric_pressure)
            temperature_proxy = max(0.0, temperature_proxy + 0.030 * atmospheric_pressure - 0.012 * temperature_proxy)

        damages = damage_coefficient * temperature_proxy**2 * output
        mitigation_cost = mitigation_cost_scale * mitigation_rate**2 * output
        consumption_proxy = max(0.0, output - damages - mitigation_cost)
        welfare = math.log(consumption_proxy + 1.0) / ((1.0 + discount_rate) ** (year - start_year))

        rows.append({
            "scenario": scenario,
            "year": year,
            "output": round(output, 6),
            "emissions_intensity": round(emissions_intensity, 6),
            "mitigation_rate": round(mitigation_rate, 6),
            "emissions": round(emissions, 6),
            "atmospheric_pressure": round(atmospheric_pressure, 6),
            "temperature_proxy": round(temperature_proxy, 6),
            "damages": round(damages, 6),
            "mitigation_cost": round(mitigation_cost, 6),
            "consumption_proxy": round(consumption_proxy, 6),
            "discounted_welfare_proxy": round(welfare, 6),
        })
    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    out: list[dict[str, object]] = []
    for scenario in sorted({str(r["scenario"]) for r in rows}):
        subset = [r for r in rows if r["scenario"] == scenario]
        final = subset[-1]
        cumulative_emissions = sum(float(r["emissions"]) for r in subset)
        cumulative_damages = sum(float(r["damages"]) for r in subset)
        cumulative_mitigation_cost = sum(float(r["mitigation_cost"]) for r in subset)
        welfare = sum(float(r["discounted_welfare_proxy"]) for r in subset)
        avg_mitigation = mean(float(r["mitigation_rate"]) for r in subset)
        out.append({
            "scenario": scenario,
            "final_emissions": final["emissions"],
            "final_temperature_proxy": final["temperature_proxy"],
            "cumulative_emissions": round(cumulative_emissions, 6),
            "cumulative_damages": round(cumulative_damages, 6),
            "cumulative_mitigation_cost": round(cumulative_mitigation_cost, 6),
            "discounted_welfare_proxy": round(welfare, 6),
            "average_mitigation_rate": round(avg_mitigation, 6),
            "diagnostic_label": "high climate pressure pathway" if float(final["temperature_proxy"]) > 3.0 else "lower climate pressure pathway",
        })
    return out


def main() -> None:
    scenarios = read_csv(DATA / "scenario_definitions.csv")
    trajectories: list[dict[str, object]] = []
    for scenario in scenarios:
        trajectories.extend(simulate(scenario))
    summary = summarize(trajectories)

    validation: list[dict[str, object]] = []
    checks = [
        ("final_emissions", 0.0, 1_000_000.0),
        ("final_temperature_proxy", 0.0, 1_000_000.0),
        ("cumulative_emissions", 0.0, 1_000_000.0),
        ("cumulative_damages", 0.0, 1_000_000.0),
        ("cumulative_mitigation_cost", 0.0, 1_000_000.0),
        ("discounted_welfare_proxy", -1_000_000.0, 1_000_000.0),
        ("average_mitigation_rate", 0.0, 1.0),
    ]
    for row in summary:
        for metric, low, high in checks:
            value = float(row[metric])
            validation.append({"scenario": row["scenario"], "metric": metric, "value": value, "target_low": low, "target_high": high, "passed": low <= value <= high})

    write_csv(TABLES / "python_iam_system_components.csv", read_csv(DATA / "iam_system_components.csv"))
    write_csv(TABLES / "python_iam_feedback_loops.csv", read_csv(DATA / "iam_feedback_loops.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_ethics_dimensions.csv", read_csv(DATA / "ethics_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenarios)
    write_csv(TABLES / "python_iam_pathway_trajectories.csv", trajectories)
    write_csv(TABLES / "python_iam_pathway_summary.csv", summary)
    write_csv(TABLES / "python_iam_validation_checks.csv", validation)
    print("Stylized IAM workflow complete.")
    print(TABLES / "python_iam_pathway_summary.csv")


if __name__ == "__main__":
    main()
