#!/usr/bin/env python3
"""
Ethics, power, and systems modeling workflow.

Dependency-light workflow demonstrating stakeholder coverage diagnostics,
power-burden gap scoring, governance registers, ethical model-use risk scoring,
boundary-power questions, safeguards, misuse patterns, and validation checks.

All data are synthetic.
"""

from __future__ import annotations

import csv
from pathlib import Path


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

    fieldnames: list[str] = []
    for row in rows:
        for key in row:
            if key not in fieldnames:
                fieldnames.append(key)

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def burden_label(score: float) -> str:
    if score >= 0.45:
        return "high_power_burden_gap"
    if score >= 0.20:
        return "moderate_power_burden_gap"
    return "lower_power_burden_gap"


def score_stakeholders(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    scored: list[dict[str, object]] = []

    for row in rows:
        affected = float(row["affected"])
        influence = float(row["influence"])
        expected_benefit = float(row["expected_benefit"])
        expected_burden = float(row["expected_burden"])

        net_benefit = expected_benefit - expected_burden
        burden_gap = expected_burden - expected_benefit
        power_burden_gap = affected * expected_burden * (1.0 - influence)

        output = dict(row)
        output["net_benefit"] = round(net_benefit, 6)
        output["burden_gap"] = round(burden_gap, 6)
        output["power_burden_gap"] = round(power_burden_gap, 6)
        output["risk_label"] = burden_label(power_burden_gap)
        scored.append(output)

    scored.sort(key=lambda item: float(item["power_burden_gap"]), reverse=True)
    return scored


def score_model_use_risks(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    scored: list[dict[str, object]] = []

    for row in rows:
        ethical_risk_score = (
            float(row["uncertainty"])
            * float(row["consequence"])
            * (1.0 + 0.50 * float(row["representation_gap"]))
            * (1.0 + 0.50 * float(row["misuse_potential"]))
        )

        output = dict(row)
        output["ethical_risk_score"] = round(ethical_risk_score, 6)
        scored.append(output)

    scored.sort(key=lambda item: float(item["ethical_risk_score"]), reverse=True)
    return scored


def coverage_summary(stakeholders: list[dict[str, object]]) -> list[dict[str, object]]:
    return [
        {"metric": "stakeholder_groups", "value": len(stakeholders)},
        {"metric": "affected_groups", "value": sum(1 for row in stakeholders if float(row["affected"]) >= 0.50)},
        {"metric": "represented_groups", "value": sum(1 for row in stakeholders if int(row["represented"]) == 1)},
        {"metric": "missing_or_unrepresented_groups", "value": sum(1 for row in stakeholders if int(row["represented"]) == 0)},
        {"metric": "high_power_burden_gap_groups", "value": sum(1 for row in stakeholders if row["risk_label"] == "high_power_burden_gap")},
    ]


def governance_summary(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["status"]] = counts.get(row["status"], 0) + 1
    return [{"status": key, "governance_item_count": value} for key, value in sorted(counts.items())]


def main() -> None:
    stakeholders = score_stakeholders(read_csv(DATA / "stakeholders.csv"))
    governance_register = read_csv(DATA / "governance_register.csv")
    model_use_risks = score_model_use_risks(read_csv(DATA / "model_use_risks.csv"))
    boundary_power_questions = read_csv(DATA / "boundary_power_questions.csv")
    model_safeguards = read_csv(DATA / "model_safeguards.csv")
    misuse_patterns = read_csv(DATA / "misuse_patterns.csv")

    validation_rows = [
        {"check": "stakeholder_table_created", "passed": len(stakeholders) > 0, "value": len(stakeholders)},
        {"check": "power_burden_gaps_nonnegative", "passed": all(float(row["power_burden_gap"]) >= 0 for row in stakeholders), "value": "all_power_burden_gaps_checked"},
        {"check": "governance_register_created", "passed": len(governance_register) > 0, "value": len(governance_register)},
        {"check": "model_use_risks_created", "passed": len(model_use_risks) > 0, "value": len(model_use_risks)},
        {"check": "ethical_risk_scores_nonnegative", "passed": all(float(row["ethical_risk_score"]) >= 0 for row in model_use_risks), "value": "all_ethical_risk_scores_checked"},
        {"check": "safeguards_created", "passed": len(model_safeguards) > 0, "value": len(model_safeguards)},
    ]

    write_csv(TABLES / "python_ethics_stakeholder_distributional_diagnostics.csv", stakeholders)
    write_csv(TABLES / "python_ethics_stakeholder_coverage_summary.csv", coverage_summary(stakeholders))
    write_csv(TABLES / "python_ethics_governance_register.csv", governance_register)
    write_csv(TABLES / "python_ethics_governance_status_summary.csv", governance_summary(governance_register))
    write_csv(TABLES / "python_ethics_model_use_risk_register.csv", model_use_risks)
    write_csv(TABLES / "python_boundary_power_questions.csv", boundary_power_questions)
    write_csv(TABLES / "python_model_safeguards.csv", model_safeguards)
    write_csv(TABLES / "python_misuse_patterns.csv", misuse_patterns)
    write_csv(TABLES / "python_ethics_validation_checks.csv", validation_rows)

    print("Ethics, power, and systems modeling workflow complete.")
    print(TABLES / "python_ethics_model_use_risk_register.csv")


if __name__ == "__main__":
    main()
