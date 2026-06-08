#!/usr/bin/env python3
"""
Case study: integrated assessment and sustainability pathways.

Dependency-light workflow demonstrating:

1. Sustainability pathway comparison
2. Energy demand and clean energy transition
3. Annual and cumulative emissions
4. Climate stress and damages
5. Adaptation capacity
6. Land, water, equity, and sustainability diagnostics

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


@dataclass(frozen=True)
class Pathway:
    name: str
    demand_growth: float
    efficiency_gain: float
    clean_growth_early: float
    clean_growth_late: float
    adaptation_investment: float
    transition_cost_factor: float
    equity_support: float
    ecological_constraint: float
    description: str


def clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def read_pathways(path: Path) -> list[Pathway]:
    pathways: list[Pathway] = []

    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            pathways.append(
                Pathway(
                    name=row["pathway"],
                    demand_growth=float(row["demand_growth"]),
                    efficiency_gain=float(row["efficiency_gain"]),
                    clean_growth_early=float(row["clean_growth_early"]),
                    clean_growth_late=float(row["clean_growth_late"]),
                    adaptation_investment=float(row["adaptation_investment"]),
                    transition_cost_factor=float(row["transition_cost_factor"]),
                    equity_support=float(row["equity_support"]),
                    ecological_constraint=float(row["ecological_constraint"]),
                    description=row["description"],
                )
            )

    return pathways


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


def simulate_pathway(pathway: Pathway, years: int = 40) -> list[dict[str, Any]]:
    demand = 1.00
    clean_share = 0.22
    cumulative_emissions = 0.0
    adaptation_capacity = 0.28
    rows: list[dict[str, Any]] = []

    for year in range(years + 1):
        clean_growth = pathway.clean_growth_early if year < 15 else pathway.clean_growth_late
        emissions_intensity = 0.72 * (1.0 - clean_share)
        annual_emissions = demand * emissions_intensity
        cumulative_emissions += annual_emissions

        climate_stress = clamp(0.18 + 0.018 * cumulative_emissions)
        adaptation_capacity = clamp(adaptation_capacity + pathway.adaptation_investment - 0.010 * climate_stress)

        climate_damages = 0.42 * climate_stress**2 * (1.0 - adaptation_capacity)
        transition_cost = pathway.transition_cost_factor * clean_growth * 4.0

        land_pressure = clamp(0.22 + 0.18 * demand + 0.25 * clean_share - 0.18 * pathway.ecological_constraint)
        water_stress = clamp(0.25 + 0.16 * demand + 0.34 * climate_stress - 0.14 * adaptation_capacity)
        equity_score = clamp(0.42 + 0.36 * pathway.equity_support - 0.18 * transition_cost - 0.22 * climate_damages)

        sustainability_score = (
            0.24 * equity_score
            + 0.20 * clean_share
            + 0.16 * adaptation_capacity
            - 0.15 * annual_emissions
            - 0.10 * climate_damages
            - 0.08 * land_pressure
            - 0.07 * water_stress
        )

        rows.append(
            {
                "pathway": pathway.name,
                "year": year,
                "energy_demand": round(demand, 6),
                "clean_energy_share": round(clean_share, 6),
                "emissions_intensity": round(emissions_intensity, 6),
                "annual_emissions": round(annual_emissions, 6),
                "cumulative_emissions": round(cumulative_emissions, 6),
                "climate_stress": round(climate_stress, 6),
                "adaptation_capacity": round(adaptation_capacity, 6),
                "climate_damages": round(climate_damages, 6),
                "transition_cost": round(transition_cost, 6),
                "land_pressure": round(land_pressure, 6),
                "water_stress": round(water_stress, 6),
                "equity_score": round(equity_score, 6),
                "sustainability_score": round(sustainability_score, 6),
                "land_breach": land_pressure > 0.72,
                "water_breach": water_stress > 0.72,
                "equity_breach": equity_score < 0.45,
            }
        )

        demand = demand * (1.0 + pathway.demand_growth - pathway.efficiency_gain)
        clean_share = clamp(clean_share + clean_growth)

    return rows


def summarize(rows: list[dict[str, Any]]) -> dict[str, Any]:
    final = rows[-1]

    def mean(key: str) -> float:
        return sum(float(row[key]) for row in rows) / len(rows)

    constraint_breach_count = sum(
        1
        for row in rows
        if bool(row["land_breach"]) or bool(row["water_breach"]) or bool(row["equity_breach"])
    )

    return {
        "pathway": final["pathway"],
        "final_clean_energy_share": final["clean_energy_share"],
        "cumulative_emissions": final["cumulative_emissions"],
        "average_climate_damages": round(mean("climate_damages"), 6),
        "average_transition_cost": round(mean("transition_cost"), 6),
        "average_land_pressure": round(mean("land_pressure"), 6),
        "average_water_stress": round(mean("water_stress"), 6),
        "average_equity_score": round(mean("equity_score"), 6),
        "final_adaptation_capacity": final["adaptation_capacity"],
        "constraint_breach_count": constraint_breach_count,
        "average_sustainability_score": round(mean("sustainability_score"), 6),
    }


def main() -> None:
    pathways = read_pathways(DATA / "sustainability_pathways.csv")
    assumptions = read_csv_dicts(DATA / "model_assumptions.csv")
    diagnostics = read_csv_dicts(DATA / "diagnostic_definitions.csv")

    all_rows: list[dict[str, Any]] = []
    summary_rows: list[dict[str, Any]] = []

    for pathway in pathways:
        rows = simulate_pathway(pathway)
        all_rows.extend(rows)
        summary_rows.append(summarize(rows))

    summary_rows.sort(key=lambda row: float(row["average_sustainability_score"]), reverse=True)

    validation_rows = [
        {"check": "pathway_runs_created", "passed": len(all_rows) > 0, "value": len(all_rows)},
        {
            "check": "clean_share_normalized",
            "passed": all(0 <= float(row["clean_energy_share"]) <= 1 for row in all_rows),
            "value": "all_clean_shares_checked",
        },
        {
            "check": "adaptation_capacity_normalized",
            "passed": all(0 <= float(row["adaptation_capacity"]) <= 1 for row in all_rows),
            "value": "all_adaptation_values_checked",
        },
        {
            "check": "equity_score_normalized",
            "passed": all(0 <= float(row["equity_score"]) <= 1 for row in all_rows),
            "value": "all_equity_values_checked",
        },
        {
            "check": "land_pressure_normalized",
            "passed": all(0 <= float(row["land_pressure"]) <= 1 for row in all_rows),
            "value": "all_land_pressure_values_checked",
        },
        {
            "check": "water_stress_normalized",
            "passed": all(0 <= float(row["water_stress"]) <= 1 for row in all_rows),
            "value": "all_water_stress_values_checked",
        },
        {
            "check": "emissions_nonnegative",
            "passed": all(float(row["annual_emissions"]) >= 0 for row in all_rows),
            "value": "all_emissions_checked",
        },
        {"check": "summary_created", "passed": len(summary_rows) == len(pathways), "value": len(summary_rows)},
    ]

    write_csv(TABLES / "python_sustainability_pathways.csv", [asdict(pathway) for pathway in pathways])
    write_csv(TABLES / "python_integrated_assessment_timeseries.csv", all_rows)
    write_csv(TABLES / "python_integrated_assessment_summary.csv", summary_rows)
    write_csv(TABLES / "python_model_assumptions.csv", assumptions)
    write_csv(TABLES / "python_diagnostic_definitions.csv", diagnostics)
    write_csv(TABLES / "python_integrated_assessment_validation_checks.csv", validation_rows)

    print("Integrated assessment sustainability pathways workflow complete.")
    print(TABLES / "python_integrated_assessment_summary.csv")


if __name__ == "__main__":
    main()
