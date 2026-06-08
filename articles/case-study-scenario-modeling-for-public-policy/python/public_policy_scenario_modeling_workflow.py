#!/usr/bin/env python3
"""
Case study: scenario modeling for public policy.

Dependency-light workflow demonstrating:

1. Public policy option comparison
2. Future scenario stress testing
3. Multi-criteria scoring
4. Robustness diagnostics
5. Regret analysis
6. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import csv
import math


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"
ACCEPTABILITY_THRESHOLD = 0.50


@dataclass(frozen=True)
class Policy:
    name: str
    base_benefit: float
    base_cost: float
    base_equity: float
    base_resilience: float
    base_feasibility: float
    base_legitimacy: float
    description: str


@dataclass(frozen=True)
class Scenario:
    name: str
    cost_multiplier: float
    benefit_multiplier: float
    equity_multiplier: float
    resilience_multiplier: float
    feasibility_multiplier: float
    legitimacy_multiplier: float
    description: str


def read_policies(path: Path) -> list[Policy]:
    policies: list[Policy] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            policies.append(
                Policy(
                    name=row["policy"],
                    base_benefit=float(row["base_benefit"]),
                    base_cost=float(row["base_cost"]),
                    base_equity=float(row["base_equity"]),
                    base_resilience=float(row["base_resilience"]),
                    base_feasibility=float(row["base_feasibility"]),
                    base_legitimacy=float(row["base_legitimacy"]),
                    description=row["description"],
                )
            )
    return policies


def read_scenarios(path: Path) -> list[Scenario]:
    scenarios: list[Scenario] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            scenarios.append(
                Scenario(
                    name=row["scenario"],
                    cost_multiplier=float(row["cost_multiplier"]),
                    benefit_multiplier=float(row["benefit_multiplier"]),
                    equity_multiplier=float(row["equity_multiplier"]),
                    resilience_multiplier=float(row["resilience_multiplier"]),
                    feasibility_multiplier=float(row["feasibility_multiplier"]),
                    legitimacy_multiplier=float(row["legitimacy_multiplier"]),
                    description=row["description"],
                )
            )
    return scenarios


def read_weights(path: Path) -> dict[str, float]:
    weights: dict[str, float] = {}
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            weights[row["metric"]] = float(row["weight"])
    return weights


def read_csv_dicts(path: Path) -> list[dict[str, str]]:
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


def clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def score_policy_scenario(policy: Policy, scenario: Scenario, weights: dict[str, float]) -> dict[str, object]:
    benefit = clamp(policy.base_benefit * scenario.benefit_multiplier)
    cost = clamp(policy.base_cost * scenario.cost_multiplier)
    equity = clamp(policy.base_equity * scenario.equity_multiplier)
    resilience = clamp(policy.base_resilience * scenario.resilience_multiplier)
    feasibility = clamp(policy.base_feasibility * scenario.feasibility_multiplier)
    legitimacy = clamp(policy.base_legitimacy * scenario.legitimacy_multiplier)

    composite_score = (
        weights["benefit"] * benefit
        - weights["cost"] * cost
        + weights["equity"] * equity
        + weights["resilience"] * resilience
        + weights["feasibility"] * feasibility
        + weights["legitimacy"] * legitimacy
    )

    return {
        "policy": policy.name,
        "scenario": scenario.name,
        "benefit": round(benefit, 6),
        "cost": round(cost, 6),
        "equity": round(equity, 6),
        "resilience": round(resilience, 6),
        "feasibility": round(feasibility, 6),
        "legitimacy": round(legitimacy, 6),
        "composite_score": round(composite_score, 6),
        "acceptable": composite_score >= ACCEPTABILITY_THRESHOLD,
    }


def add_regret(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    best_by_scenario: dict[str, float] = {}

    for row in rows:
        scenario = str(row["scenario"])
        score = float(row["composite_score"])
        best_by_scenario[scenario] = max(best_by_scenario.get(scenario, score), score)

    updated: list[dict[str, object]] = []

    for row in rows:
        scenario = str(row["scenario"])
        score = float(row["composite_score"])
        best = best_by_scenario[scenario]
        output = dict(row)
        output["best_score_in_scenario"] = round(best, 6)
        output["regret"] = round(best - score, 6)
        updated.append(output)

    return updated


def summarize(rows: list[dict[str, object]], policies: list[Policy]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for policy in policies:
        subset = [row for row in rows if row["policy"] == policy.name]
        scores = [float(row["composite_score"]) for row in subset]
        regrets = [float(row["regret"]) for row in subset]
        acceptable = [bool(row["acceptable"]) for row in subset]

        average_score = sum(scores) / len(scores)
        worst_case_score = min(scores)
        best_case_score = max(scores)
        maximum_regret = max(regrets)
        acceptable_scenario_share = sum(1 for value in acceptable if value) / len(acceptable)
        scenario_failure_count = sum(1 for value in acceptable if not value)

        robustness_score = (
            0.55 * average_score
            + 0.45 * worst_case_score
            - 0.25 * maximum_regret
        )

        summary_rows.append(
            {
                "policy": policy.name,
                "average_score": round(average_score, 6),
                "worst_case_score": round(worst_case_score, 6),
                "best_case_score": round(best_case_score, 6),
                "maximum_regret": round(maximum_regret, 6),
                "acceptable_scenario_share": round(acceptable_scenario_share, 6),
                "scenario_failure_count": scenario_failure_count,
                "robustness_score": round(robustness_score, 6),
            }
        )

    summary_rows.sort(key=lambda row: float(row["robustness_score"]), reverse=True)
    return summary_rows


def main() -> None:
    policies = read_policies(DATA / "policy_options.csv")
    scenarios = read_scenarios(DATA / "future_scenarios.csv")
    weights = read_weights(DATA / "metric_weights.csv")
    assumptions = read_csv_dicts(DATA / "model_assumptions.csv")
    diagnostics = read_csv_dicts(DATA / "diagnostic_definitions.csv")

    scenario_results: list[dict[str, object]] = []

    for policy in policies:
        for scenario in scenarios:
            scenario_results.append(score_policy_scenario(policy, scenario, weights))

    scenario_results = add_regret(scenario_results)
    summary_rows = summarize(scenario_results, policies)

    policy_rows = [policy.__dict__ for policy in policies]
    scenario_rows = [scenario.__dict__ for scenario in scenarios]
    weight_rows = read_csv_dicts(DATA / "metric_weights.csv")

    validation_rows = [
        {"check": "policies_created", "passed": len(policies) > 0, "value": len(policies)},
        {"check": "scenarios_created", "passed": len(scenarios) > 0, "value": len(scenarios)},
        {"check": "scenario_results_created", "passed": len(scenario_results) == len(policies) * len(scenarios), "value": len(scenario_results)},
        {"check": "scores_are_finite", "passed": all(math.isfinite(float(row["composite_score"])) for row in scenario_results), "value": "all_scores_checked"},
        {"check": "regret_nonnegative", "passed": all(float(row["regret"]) >= 0 for row in scenario_results), "value": "all_regrets_checked"},
        {"check": "summary_created", "passed": len(summary_rows) == len(policies), "value": len(summary_rows)},
        {"check": "weights_sum_reasonable", "passed": abs(sum(weights.values()) - 1.0) < 0.000001, "value": round(sum(weights.values()), 6)},
    ]

    write_csv(TABLES / "python_policy_options.csv", policy_rows)
    write_csv(TABLES / "python_future_scenarios.csv", scenario_rows)
    write_csv(TABLES / "python_metric_weights.csv", weight_rows)
    write_csv(TABLES / "python_policy_scenario_results.csv", scenario_results)
    write_csv(TABLES / "python_policy_robustness_summary.csv", summary_rows)
    write_csv(TABLES / "python_model_assumptions.csv", assumptions)
    write_csv(TABLES / "python_diagnostic_definitions.csv", diagnostics)
    write_csv(TABLES / "python_policy_scenario_validation_checks.csv", validation_rows)

    print("Public policy scenario modeling workflow complete.")
    print(TABLES / "python_policy_robustness_summary.csv")


if __name__ == "__main__":
    main()
