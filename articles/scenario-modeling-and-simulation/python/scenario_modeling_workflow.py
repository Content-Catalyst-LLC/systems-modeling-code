#!/usr/bin/env python3
"""
Scenario modeling workflow.

Dependency-light workflow demonstrating:

1. Scenario ensembles
2. Policy comparison
3. External shocks
4. Outcome distributions
5. Regret analysis
6. Robustness diagnostics
7. Synthetic validation checks

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


def simulate_policy(
    growth: float,
    policy_drag: float,
    external_shock: float,
    shock_time: int,
    resilience_buffer: float,
    implementation_delay: int = 0,
    steps: int = 60,
    initial_state: float = 20.0,
) -> dict[str, float]:
    state = initial_state
    cumulative_cost = 0.0
    maximum_state = state
    minimum_state = state

    for time in range(1, steps + 1):
        active_policy_drag = policy_drag if time >= implementation_delay else 0.0
        state = state + growth * state - active_policy_drag * state

        if time == shock_time:
            state = max(0.0, state - external_shock / max(1.0, resilience_buffer))

        policy_cost = 4.0 * active_policy_drag + 0.08 * resilience_buffer
        stress_cost = 0.03 * max(state - 35.0, 0.0) ** 2
        cumulative_cost += policy_cost + stress_cost

        maximum_state = max(maximum_state, state)
        minimum_state = min(minimum_state, state)

    return {
        "final_state": state,
        "maximum_state": maximum_state,
        "minimum_state": minimum_state,
        "cumulative_cost": cumulative_cost,
        "resilience_score": final_resilience_score(state, maximum_state, cumulative_cost),
    }


def final_resilience_score(final_state: float, maximum_state: float, cumulative_cost: float) -> float:
    score = 100.0 - 0.8 * final_state - 0.3 * maximum_state - 0.2 * cumulative_cost
    return max(0.0, min(100.0, score))


def percentile(values: list[float], q: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = int(round((len(ordered) - 1) * q))
    return ordered[index]


def validate_summary(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    checks = {
        "mean_resilience_score": (0.0, 100.0),
        "p10_resilience_score": (0.0, 100.0),
        "p90_resilience_score": (0.0, 100.0),
        "worst_resilience_score": (0.0, 100.0),
        "mean_regret": (0.0, 100.0),
        "maximum_regret": (0.0, 100.0),
    }

    rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, (low, high) in checks.items():
            value = float(row[metric])
            rows.append({
                "policy": row["policy"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    return rows


def main() -> None:
    rng = random.Random(42)

    policy_rows = read_csv(DATA / "policy_levers.csv")
    policies = [
        {
            "policy": row["policy"],
            "policy_drag": float(row["policy_drag"]),
            "resilience_buffer": float(row["resilience_buffer"]),
            "implementation_delay": int(row["implementation_delay"]),
        }
        for row in policy_rows
    ]

    scenario_driver_rows: list[dict[str, object]] = []
    outcome_rows: list[dict[str, object]] = []

    n_scenarios = 400

    for scenario_id in range(1, n_scenarios + 1):
        growth = rng.uniform(0.030, 0.075)
        external_shock = rng.uniform(0.0, 18.0)
        shock_time = rng.randint(20, 45)

        scenario_driver_rows.append({
            "scenario_id": scenario_id,
            "growth": round(growth, 6),
            "external_shock": round(external_shock, 6),
            "shock_time": shock_time,
        })

        scenario_policy_results: list[dict[str, object]] = []

        for policy in policies:
            result = simulate_policy(
                growth=growth,
                policy_drag=policy["policy_drag"],
                external_shock=external_shock,
                shock_time=shock_time,
                resilience_buffer=policy["resilience_buffer"],
                implementation_delay=policy["implementation_delay"],
            )

            row = {
                "scenario_id": scenario_id,
                "policy": policy["policy"],
                "policy_drag": policy["policy_drag"],
                "resilience_buffer": policy["resilience_buffer"],
                "implementation_delay": policy["implementation_delay"],
                "growth": round(growth, 6),
                "external_shock": round(external_shock, 6),
                "shock_time": shock_time,
                "final_state": round(result["final_state"], 6),
                "maximum_state": round(result["maximum_state"], 6),
                "minimum_state": round(result["minimum_state"], 6),
                "cumulative_cost": round(result["cumulative_cost"], 6),
                "resilience_score": round(result["resilience_score"], 6),
            }

            scenario_policy_results.append(row)

        best_score = max(float(row["resilience_score"]) for row in scenario_policy_results)

        for row in scenario_policy_results:
            row["regret"] = round(best_score - float(row["resilience_score"]), 6)
            outcome_rows.append(row)

    summary_rows: list[dict[str, object]] = []

    for policy in [policy["policy"] for policy in policies]:
        subset = [row for row in outcome_rows if row["policy"] == policy]
        scores = [float(row["resilience_score"]) for row in subset]
        regrets = [float(row["regret"]) for row in subset]
        final_states = [float(row["final_state"]) for row in subset]

        summary_rows.append({
            "policy": policy,
            "mean_resilience_score": round(mean(scores), 6),
            "p10_resilience_score": round(percentile(scores, 0.10), 6),
            "p90_resilience_score": round(percentile(scores, 0.90), 6),
            "worst_resilience_score": round(min(scores), 6),
            "mean_final_state": round(mean(final_states), 6),
            "worst_final_state": round(max(final_states), 6),
            "mean_regret": round(mean(regrets), 6),
            "maximum_regret": round(max(regrets), 6),
            "robustness_diagnostic": (
                "strong robust performance"
                if percentile(scores, 0.10) >= 40 and mean(regrets) <= 10
                else "scenario-sensitive performance"
            ),
        })

    write_csv(TABLES / "python_scenario_definitions.csv", read_csv(DATA / "scenario_definitions.csv"))
    write_csv(TABLES / "python_policy_levers.csv", policy_rows)
    write_csv(TABLES / "python_scenario_driver_inventory.csv", scenario_driver_rows)
    write_csv(TABLES / "python_policy_scenario_ensemble.csv", outcome_rows)
    write_csv(TABLES / "python_policy_robustness_summary.csv", summary_rows)
    write_csv(TABLES / "python_scenario_validation.csv", validate_summary(summary_rows))

    print("Scenario modeling workflow complete.")
    print(TABLES / "python_policy_robustness_summary.csv")


if __name__ == "__main__":
    main()
