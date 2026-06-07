#!/usr/bin/env python3
"""
Participatory modeling and stakeholder systems workflow.

Dependency-light workflow demonstrating:

1. Stakeholder group definitions
2. Outcome weights
3. Scenario performance values
4. Stakeholder-specific scenario scoring
5. Disagreement diagnostics
6. Legitimacy-adjusted rankings
7. Assumption and governance registers
8. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import math
from statistics import mean, pstdev


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


OUTCOMES = ["access", "cost", "resilience", "equity", "feasibility"]


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


def stakeholder_weight_sum(stakeholder: dict[str, str]) -> float:
    return sum(float(stakeholder[outcome]) for outcome in OUTCOMES)


def score_scenarios(
    stakeholders: list[dict[str, str]],
    scenarios: list[dict[str, str]],
) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    for stakeholder in stakeholders:
        for scenario in scenarios:
            score = sum(float(stakeholder[outcome]) * float(scenario[outcome]) for outcome in OUTCOMES)

            rows.append({
                "stakeholder_group": stakeholder["stakeholder_group"],
                "scenario": scenario["scenario"],
                "score": round(score, 6),
            })

    return rows


def summarize_scores(score_rows: list[dict[str, object]], scenarios: list[dict[str, str]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in scenarios:
        scenario_name = scenario["scenario"]
        scores = [
            float(row["score"])
            for row in score_rows
            if row["scenario"] == scenario_name
        ]

        mean_score = mean(scores)
        disagreement_sd = pstdev(scores)
        minimum_score = min(scores)
        maximum_score = max(scores)
        legitimacy_adjusted_score = mean_score - 0.50 * disagreement_sd

        if disagreement_sd >= 0.08:
            consensus_label = "high disagreement"
        elif disagreement_sd >= 0.04:
            consensus_label = "moderate disagreement"
        else:
            consensus_label = "low disagreement"

        summary_rows.append({
            "scenario": scenario_name,
            "mean_score": round(mean_score, 6),
            "disagreement_sd": round(disagreement_sd, 6),
            "minimum_score": round(minimum_score, 6),
            "maximum_score": round(maximum_score, 6),
            "score_range": round(maximum_score - minimum_score, 6),
            "legitimacy_adjusted_score": round(legitimacy_adjusted_score, 6),
            "consensus_label": consensus_label,
        })

    summary_rows.sort(key=lambda row: float(row["legitimacy_adjusted_score"]), reverse=True)
    return summary_rows


def assumption_status_summary(assumptions: list[dict[str, str]]) -> list[dict[str, object]]:
    counts: dict[str, int] = {}
    for row in assumptions:
        counts[row["status"]] = counts.get(row["status"], 0) + 1

    return [
        {
            "status": status,
            "assumption_count": count,
        }
        for status, count in sorted(counts.items())
    ]


def main() -> None:
    stakeholders = read_csv(DATA / "stakeholder_weights.csv")
    scenarios = read_csv(DATA / "scenarios.csv")
    assumptions = read_csv(DATA / "assumption_register.csv")

    score_rows = score_scenarios(stakeholders, scenarios)
    summary_rows = summarize_scores(score_rows, scenarios)
    assumption_summary = assumption_status_summary(assumptions)

    validation_rows = [
        {
            "check": "stakeholder_weights_sum_to_one",
            "passed": all(math.isclose(stakeholder_weight_sum(stakeholder), 1.0, abs_tol=1e-9) for stakeholder in stakeholders),
            "value": "all_groups_checked",
        },
        {
            "check": "scenario_scores_between_zero_and_one",
            "passed": all(0.0 <= float(row["score"]) <= 1.0 for row in score_rows),
            "value": "all_scores_checked",
        },
        {
            "check": "scenario_summary_created",
            "passed": len(summary_rows) == len(scenarios),
            "value": len(summary_rows),
        },
        {
            "check": "assumption_register_created",
            "passed": len(assumptions) > 0,
            "value": len(assumptions),
        },
        {
            "check": "participation_levels_exported",
            "passed": len(read_csv(DATA / "participation_levels.csv")) > 0,
            "value": "participation_levels_available",
        },
    ]

    write_csv(TABLES / "python_participatory_stakeholder_weights.csv", stakeholders)
    write_csv(TABLES / "python_participatory_scenarios.csv", scenarios)
    write_csv(TABLES / "python_participatory_stakeholder_scenario_scores.csv", score_rows)
    write_csv(TABLES / "python_participatory_scenario_summary.csv", summary_rows)
    write_csv(TABLES / "python_participatory_assumption_register.csv", assumptions)
    write_csv(TABLES / "python_participatory_assumption_status_summary.csv", assumption_summary)
    write_csv(TABLES / "python_participation_levels.csv", read_csv(DATA / "participation_levels.csv"))
    write_csv(TABLES / "python_facilitation_risks.csv", read_csv(DATA / "facilitation_risks.csv"))
    write_csv(TABLES / "python_evidence_sources.csv", read_csv(DATA / "evidence_sources.csv"))
    write_csv(TABLES / "python_modeling_approaches.csv", read_csv(DATA / "modeling_approaches.csv"))
    write_csv(TABLES / "python_participatory_validation_checks.csv", validation_rows)

    print("Participatory modeling workflow complete.")
    print(TABLES / "python_participatory_scenario_summary.csv")


if __name__ == "__main__":
    main()
