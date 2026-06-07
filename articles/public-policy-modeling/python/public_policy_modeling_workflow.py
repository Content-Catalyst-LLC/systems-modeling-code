#!/usr/bin/env python3
"""
Public policy modeling workflow.

Dependency-light workflow demonstrating:

1. Adaptive policy intensity
2. Delayed institutional capacity
3. Administrative burden
4. Public trust and uptake
5. Side effects and unintended consequences
6. Scenario comparison
7. Validation checks
8. Public policy component, feedback, and equity taxonomies

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


def bounded(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def simulate_policy_system(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    target_state = float(row["target_state"])
    system_state = float(row["initial_state"])
    institutional_capacity = float(row["initial_capacity"])
    trust = float(row["initial_trust"])
    administrative_burden = float(row["initial_burden"])
    policy_intensity = float(row["starting_policy"])
    max_policy = float(row["max_policy"])
    min_policy = float(row["min_policy"])
    policy_increase_rate = float(row["policy_increase_rate"])
    policy_decrease_rate = float(row["policy_decrease_rate"])
    policy_effect = float(row["policy_effect"])
    capacity_learning_rate = float(row["capacity_learning_rate"])
    burden_growth = float(row["burden_growth"])
    burden_relief = float(row["burden_relief"])
    side_effect_rate = float(row["side_effect_rate"])
    seed = int(float(row["seed"]))

    rng = random.Random(seed)
    side_effect = 0.0

    rows: list[dict[str, object]] = []

    for time in range(n_steps):
        uptake = bounded(
            0.42
            + 0.30 * trust
            + 0.035 * institutional_capacity
            - 0.45 * administrative_burden,
            0.0,
            1.0,
        )

        performance_gap = target_state - system_state

        if performance_gap > 0:
            policy_intensity = min(max_policy, policy_intensity + policy_increase_rate)
        else:
            policy_intensity = max(min_policy, policy_intensity - policy_decrease_rate)

        rows.append({
            "scenario": scenario,
            "time": time,
            "system_state": round(system_state, 6),
            "target_state": target_state,
            "performance_gap": round(performance_gap, 6),
            "policy_intensity": round(policy_intensity, 6),
            "institutional_capacity": round(institutional_capacity, 6),
            "trust": round(trust, 6),
            "administrative_burden": round(administrative_burden, 6),
            "uptake": round(uptake, 6),
            "side_effect": round(side_effect, 6),
        })

        next_state = (
            system_state
            + policy_effect * policy_intensity * uptake
            - 0.12 * system_state
            + 0.05 * institutional_capacity
            + rng.gauss(0.0, 0.12)
        )

        next_capacity = institutional_capacity + capacity_learning_rate * (system_state - institutional_capacity)

        next_burden = max(
            0.0,
            administrative_burden
            + burden_growth * policy_intensity
            - burden_relief * institutional_capacity,
        )

        next_side_effect = max(
            0.0,
            side_effect
            + side_effect_rate * policy_intensity
            - 0.06 * side_effect,
        )

        next_trust = bounded(
            trust
            + 0.015 * uptake
            - 0.018 * next_burden
            - 0.010 * next_side_effect,
            0.0,
            1.0,
        )

        system_state = max(0.0, next_state)
        institutional_capacity = max(0.0, next_capacity)
        administrative_burden = next_burden
        side_effect = next_side_effect
        trust = next_trust

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]

        maximum_burden = max(float(row["administrative_burden"]) for row in subset)
        maximum_side_effect = max(float(row["side_effect"]) for row in subset)
        average_uptake = mean(float(row["uptake"]) for row in subset)
        average_policy = mean(float(row["policy_intensity"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_system_state": final["system_state"],
            "final_policy_intensity": final["policy_intensity"],
            "final_capacity": final["institutional_capacity"],
            "final_trust": final["trust"],
            "maximum_burden": round(maximum_burden, 6),
            "maximum_side_effect": round(maximum_side_effect, 6),
            "average_uptake": round(average_uptake, 6),
            "average_policy_intensity": round(average_policy, 6),
            "diagnostic_label": (
                "high burden policy pathway"
                if maximum_burden > 1.0 or maximum_side_effect > 1.0
                else "manageable policy pathway"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_policy_system(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_system_state", 0.0, 1000000.0),
            ("final_policy_intensity", 0.0, 1000000.0),
            ("final_capacity", 0.0, 1000000.0),
            ("final_trust", 0.0, 1.0),
            ("maximum_burden", 0.0, 1000000.0),
            ("maximum_side_effect", 0.0, 1000000.0),
            ("average_uptake", 0.0, 1.0),
            ("average_policy_intensity", 0.0, 1000000.0),
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

    write_csv(TABLES / "python_policy_system_components.csv", read_csv(DATA / "policy_system_components.csv"))
    write_csv(TABLES / "python_policy_feedback_loops.csv", read_csv(DATA / "policy_feedback_loops.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_equity_dimensions.csv", read_csv(DATA / "equity_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_public_policy_adaptive_trajectories.csv", all_rows)
    write_csv(TABLES / "python_public_policy_adaptive_summary.csv", summary_rows)
    write_csv(TABLES / "python_public_policy_validation_checks.csv", validation_rows)

    print("Public policy modeling workflow complete.")
    print(TABLES / "python_public_policy_adaptive_summary.csv")


if __name__ == "__main__":
    main()
