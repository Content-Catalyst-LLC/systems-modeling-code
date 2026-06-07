#!/usr/bin/env python3
"""
Economic systems modeling workflow.

Dependency-light workflow demonstrating:

1. Output, consumption, investment, and government demand
2. Capital accumulation
3. Credit and debt dynamics
4. Fragility accumulation
5. Shock propagation
6. Scenario comparison
7. Validation checks
8. Economic component and feedback taxonomies

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


def simulate_economy(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    demand_sensitivity = float(row["demand_sensitivity"])
    investment_sensitivity = float(row["investment_sensitivity"])
    interest_rate = float(row["interest_rate"])
    depreciation = float(row["depreciation"])
    credit_sensitivity = float(row["credit_sensitivity"])
    shock_step = int(float(row["shock_step"]))
    shock_size = float(row["shock_size"])
    seed = int(float(row["seed"]))

    rng = random.Random(seed)

    output = 100.0
    capital = 190.0
    debt = 60.0
    government = 22.0

    rows: list[dict[str, object]] = []

    for time in range(1, n_steps + 1):
        consumption = max(0.0, 18.0 + demand_sensitivity * output - 0.025 * debt)
        investment = max(0.0, investment_sensitivity * output - interest_rate * debt)

        if time > 1:
            capital = max(0.0, capital + investment - depreciation * capital)

            new_credit = max(0.0, credit_sensitivity * investment)
            repayment = 0.025 * debt
            debt = max(0.0, debt + new_credit - repayment)

            shock = shock_size if time == shock_step else 0.0
            noise = rng.gauss(0.0, 0.35)

            output = max(0.0, 0.33 * capital + consumption + government + shock + noise)

        fragility = debt / max(capital, 1.0)
        debt_service = interest_rate * debt
        demand_gap = output - consumption - investment - government

        rows.append({
            "scenario": scenario,
            "time": time,
            "output": round(output, 6),
            "consumption": round(consumption, 6),
            "investment": round(investment, 6),
            "capital": round(capital, 6),
            "debt": round(debt, 6),
            "debt_service": round(debt_service, 6),
            "fragility": round(fragility, 6),
            "government": round(government, 6),
            "demand_gap": round(demand_gap, 6),
        })

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]

        maximum_fragility = max(float(row["fragility"]) for row in subset)
        minimum_output = min(float(row["output"]) for row in subset)
        average_output = mean(float(row["output"]) for row in subset)
        average_investment = mean(float(row["investment"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_output": final["output"],
            "final_capital": final["capital"],
            "final_debt": final["debt"],
            "final_fragility": final["fragility"],
            "maximum_fragility": round(maximum_fragility, 6),
            "minimum_output": round(minimum_output, 6),
            "average_output": round(average_output, 6),
            "average_investment": round(average_investment, 6),
            "diagnostic_label": (
                "high fragility pathway"
                if maximum_fragility > 0.75
                else "moderate fragility pathway"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_economy(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_output", 0.0, 1000000.0),
            ("final_capital", 0.0, 1000000.0),
            ("final_debt", 0.0, 1000000.0),
            ("final_fragility", 0.0, 1000000.0),
            ("maximum_fragility", 0.0, 1000000.0),
            ("minimum_output", 0.0, 1000000.0),
            ("average_output", 0.0, 1000000.0),
            ("average_investment", 0.0, 1000000.0),
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

    write_csv(TABLES / "python_economic_system_components.csv", read_csv(DATA / "economic_system_components.csv"))
    write_csv(TABLES / "python_economic_feedback_loops.csv", read_csv(DATA / "economic_feedback_loops.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_sectoral_balance_examples.csv", read_csv(DATA / "sectoral_balance_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_economic_feedback_trajectories.csv", all_rows)
    write_csv(TABLES / "python_economic_feedback_summary.csv", summary_rows)
    write_csv(TABLES / "python_economic_feedback_validation_checks.csv", validation_rows)

    print("Economic systems modeling workflow complete.")
    print(TABLES / "python_economic_feedback_summary.csv")


if __name__ == "__main__":
    main()
