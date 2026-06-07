#!/usr/bin/env python3
"""
Model assumptions and boundary judgment workflow.

Dependency-light workflow demonstrating:

1. Assumption register ingestion
2. Assumption risk scoring
3. Boundary scenario comparison
4. Assumption category summaries
5. Exclusion log and boundary critique exports
6. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv


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


def risk_label(score: float) -> str:
    if score >= 0.45:
        return "high"
    if score >= 0.25:
        return "moderate"
    return "lower"


def score_assumptions(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    scored: list[dict[str, object]] = []

    for row in rows:
        uncertainty = float(row["uncertainty"])
        sensitivity = float(row["sensitivity"])
        consequence = float(row["consequence"])
        score = uncertainty * sensitivity * consequence

        output = dict(row)
        output["risk_score"] = round(score, 6)
        output["risk_label"] = risk_label(score)
        scored.append(output)

    return scored


def summarize_assumptions(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary: dict[str, dict[str, object]] = {}

    for row in rows:
        category = str(row["category"])
        if category not in summary:
            summary[category] = {
                "category": category,
                "assumption_count": 0,
                "total_risk_score": 0.0,
                "high_risk_count": 0,
                "contested_or_review_count": 0,
            }

        summary[category]["assumption_count"] += 1
        summary[category]["total_risk_score"] += float(row["risk_score"])
        if row["risk_label"] == "high":
            summary[category]["high_risk_count"] += 1
        if "contested" in str(row["review_status"]) or "review" in str(row["review_status"]):
            summary[category]["contested_or_review_count"] += 1

    rows_out: list[dict[str, object]] = []
    for item in summary.values():
        count = int(item["assumption_count"])
        rows_out.append({
            "category": item["category"],
            "assumption_count": count,
            "average_risk_score": round(float(item["total_risk_score"]) / max(count, 1), 6),
            "high_risk_count": item["high_risk_count"],
            "contested_or_review_count": item["contested_or_review_count"],
        })

    rows_out.sort(key=lambda row: str(row["category"]))
    return rows_out


def score_boundaries(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    scored: list[dict[str, object]] = []

    for row in rows:
        composite_score = (
            0.20 * float(row["capital_cost"])
            + 0.30 * float(row["service_reliability"])
            + 0.25 * float(row["equity_performance"])
            + 0.25 * float(row["long_term_resilience"])
        )
        output = dict(row)
        output["composite_score"] = round(composite_score, 6)
        scored.append(output)

    scored.sort(key=lambda row: float(row["composite_score"]), reverse=True)
    return scored


def main() -> None:
    assumptions = score_assumptions(read_csv(DATA / "assumption_register.csv"))
    category_summary = summarize_assumptions(assumptions)
    boundary_scenarios = score_boundaries(read_csv(DATA / "boundary_scenarios.csv"))
    exclusion_log = read_csv(DATA / "exclusion_log.csv")
    boundary_critique = read_csv(DATA / "boundary_critique_questions.csv")
    evidence_strength = read_csv(DATA / "evidence_strength.csv")

    validation_rows = [
        {
            "check": "assumption_register_created",
            "passed": len(assumptions) > 0,
            "value": len(assumptions),
        },
        {
            "check": "risk_scores_between_zero_and_one",
            "passed": all(0 <= float(row["risk_score"]) <= 1 for row in assumptions),
            "value": "all_risk_scores_checked",
        },
        {
            "check": "boundary_scenarios_created",
            "passed": len(boundary_scenarios) > 0,
            "value": len(boundary_scenarios),
        },
        {
            "check": "composite_scores_between_zero_and_one",
            "passed": all(0 <= float(row["composite_score"]) <= 1 for row in boundary_scenarios),
            "value": "all_boundary_scores_checked",
        },
        {
            "check": "exclusion_log_created",
            "passed": len(exclusion_log) > 0,
            "value": len(exclusion_log),
        },
        {
            "check": "boundary_critique_questions_created",
            "passed": len(boundary_critique) > 0,
            "value": len(boundary_critique),
        },
    ]

    write_csv(TABLES / "python_assumption_register.csv", assumptions)
    write_csv(TABLES / "python_assumption_category_summary.csv", category_summary)
    write_csv(TABLES / "python_boundary_scenario_comparison.csv", boundary_scenarios)
    write_csv(TABLES / "python_exclusion_log.csv", exclusion_log)
    write_csv(TABLES / "python_boundary_critique_questions.csv", boundary_critique)
    write_csv(TABLES / "python_evidence_strength.csv", evidence_strength)
    write_csv(TABLES / "python_assumption_boundary_validation_checks.csv", validation_rows)

    print("Model assumptions and boundary judgment workflow complete.")
    print(TABLES / "python_boundary_scenario_comparison.csv")


if __name__ == "__main__":
    main()
