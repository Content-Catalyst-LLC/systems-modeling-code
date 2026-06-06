#!/usr/bin/env python3
"""
Uncertainty and model interpretation workflow.

Dependency-light workflow demonstrating:

1. Scenario ensembles
2. Parameter uncertainty
3. Shock uncertainty
4. Policy robustness
5. Regret analysis
6. Confidence-style interpretation summaries
7. Validation checks

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


def percentile(values: list[float], q: float) -> float:
    ordered = sorted(values)
    index = int(round((len(ordered) - 1) * q))
    return ordered[index]


def load_policies() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for row in read_csv(DATA / "policy_options.csv"):
        rows.append({
            "policy": row["policy"],
            "policy_strength": float(row["policy_strength"]),
            "adaptive_capacity": float(row["adaptive_capacity"]),
            "description": row["description"],
        })
    return rows


def simulate_policy(
    growth: float,
    shock_intensity: float,
    shock_timing: int,
    policy_strength: float,
    adaptive_capacity: float,
    n_steps: int = 60,
    initial_state: float = 20.0,
) -> dict[str, float]:
    state = initial_state
    maximum_state = state
    minimum_state = state
    cumulative_stress = 0.0

    for time in range(1, n_steps + 1):
        shock_wave = shock_intensity if time == shock_timing else 0.0
        adaptation_effect = adaptive_capacity * max(state - 35.0, 0.0)

        state = (
            state
            + growth * state
            - policy_strength * state
            - adaptation_effect
            - shock_wave
        )

        state = max(0.0, state)
        maximum_state = max(maximum_state, state)
        minimum_state = min(minimum_state, state)
        cumulative_stress += max(state - 40.0, 0.0)

    resilience_score = max(
        0.0,
        100.0
        - 0.60 * state
        - 0.25 * maximum_state
        - 0.10 * cumulative_stress
    )

    return {
        "final_state": state,
        "maximum_state": maximum_state,
        "minimum_state": minimum_state,
        "cumulative_stress": cumulative_stress,
        "resilience_score": min(100.0, resilience_score),
    }


def scenario_class(growth: float, shock_intensity: float) -> str:
    if shock_intensity > 18.0 and growth > 0.075:
        return "compound_stress_future"
    if shock_intensity > 16.0 or growth > 0.080:
        return "stressful_future"
    if shock_intensity < 6.0 and growth < 0.055:
        return "low_pressure_future"
    return "moderate_future"


def confidence_note(p10_score: float, p90_score: float, mean_regret: float) -> str:
    spread = p90_score - p10_score

    if spread > 25:
        return "wide ensemble spread; communicate ranges before point estimates"
    if mean_regret <= 5:
        return "relative robustness is stronger than exact point prediction"
    return "conditional result; robustness depends on tested uncertainty space"


def robustness_label(p10_score: float, worst_score: float, mean_regret: float) -> str:
    if p10_score >= 45 and mean_regret <= 8:
        return "robust across tested futures"
    if worst_score < 20:
        return "lower-tail fragility under adverse futures"
    return "scenario-sensitive performance"


def main() -> None:
    rng = random.Random(42)
    policies = load_policies()

    scenario_rows: list[dict[str, object]] = []
    result_rows: list[dict[str, object]] = []

    n_scenarios = 500

    for scenario_id in range(1, n_scenarios + 1):
        growth = rng.uniform(0.035, 0.095)
        shock_intensity = rng.uniform(0.0, 24.0)
        shock_timing = rng.randint(20, 45)
        uncertainty_class = scenario_class(growth, shock_intensity)

        scenario_rows.append({
            "scenario_id": scenario_id,
            "growth": round(growth, 6),
            "shock_intensity": round(shock_intensity, 6),
            "shock_timing": shock_timing,
            "uncertainty_class": uncertainty_class,
        })

        scenario_results: list[dict[str, object]] = []

        for policy in policies:
            output = simulate_policy(
                growth=growth,
                shock_intensity=shock_intensity,
                shock_timing=shock_timing,
                policy_strength=float(policy["policy_strength"]),
                adaptive_capacity=float(policy["adaptive_capacity"]),
            )

            row = {
                "scenario_id": scenario_id,
                "uncertainty_class": uncertainty_class,
                "policy": policy["policy"],
                "growth": round(growth, 6),
                "shock_intensity": round(shock_intensity, 6),
                "shock_timing": shock_timing,
                "policy_strength": policy["policy_strength"],
                "adaptive_capacity": policy["adaptive_capacity"],
                "final_state": round(output["final_state"], 6),
                "maximum_state": round(output["maximum_state"], 6),
                "minimum_state": round(output["minimum_state"], 6),
                "cumulative_stress": round(output["cumulative_stress"], 6),
                "resilience_score": round(output["resilience_score"], 6),
            }

            scenario_results.append(row)

        best_score = max(float(row["resilience_score"]) for row in scenario_results)

        for row in scenario_results:
            row["regret"] = round(best_score - float(row["resilience_score"]), 6)
            result_rows.append(row)

    summary_rows: list[dict[str, object]] = []

    for policy in sorted(set(str(row["policy"]) for row in result_rows)):
        subset = [row for row in result_rows if row["policy"] == policy]
        scores = [float(row["resilience_score"]) for row in subset]
        regrets = [float(row["regret"]) for row in subset]
        final_states = [float(row["final_state"]) for row in subset]

        p10_score = percentile(scores, 0.10)
        p90_score = percentile(scores, 0.90)
        worst_score = min(scores)
        mean_regret = mean(regrets)

        summary_rows.append({
            "policy": policy,
            "mean_resilience_score": round(mean(scores), 6),
            "p10_resilience_score": round(p10_score, 6),
            "p90_resilience_score": round(p90_score, 6),
            "worst_resilience_score": round(worst_score, 6),
            "mean_final_state": round(mean(final_states), 6),
            "worst_final_state": round(max(final_states), 6),
            "mean_regret": round(mean_regret, 6),
            "maximum_regret": round(max(regrets), 6),
            "robustness_interpretation": robustness_label(p10_score, worst_score, mean_regret),
            "confidence_note": confidence_note(p10_score, p90_score, mean_regret),
        })

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("mean_resilience_score", 0.0, 100.0),
            ("p10_resilience_score", 0.0, 100.0),
            ("p90_resilience_score", 0.0, 100.0),
            ("worst_resilience_score", 0.0, 100.0),
            ("mean_regret", 0.0, 100.0),
            ("maximum_regret", 0.0, 100.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "policy": row["policy"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_uncertainty_sources.csv", read_csv(DATA / "uncertainty_sources.csv"))
    write_csv(TABLES / "python_confidence_language.csv", read_csv(DATA / "confidence_language.csv"))
    write_csv(TABLES / "python_uncertainty_scenario_inventory.csv", scenario_rows)
    write_csv(TABLES / "python_deep_uncertainty_policy_ensemble.csv", result_rows)
    write_csv(TABLES / "python_policy_robustness_summary.csv", summary_rows)
    write_csv(TABLES / "python_uncertainty_validation_checks.csv", validation_rows)

    print("Uncertainty interpretation workflow complete.")
    print(TABLES / "python_policy_robustness_summary.csv")


if __name__ == "__main__":
    main()
