#!/usr/bin/env python3
"""
When systems models clarify and when they distort.

Dependency-light workflow demonstrating:

1. Clarification scoring
2. Distortion risk scoring
3. Net interpretive value
4. Model-use labels
5. Risk, communication, scope, and distortion registers
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


def use_label(net_value: float) -> str:
    if net_value >= 0.20:
        return "strong_clarification_with_managed_risk"
    if net_value >= 0:
        return "useful_with_strong_caveats"
    return "high_distortion_risk_without_revision"


def score_model_cases(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    scored: list[dict[str, object]] = []

    for row in rows:
        clarification_score = (
            0.30 * float(row["structural_clarity"])
            + 0.25 * float(row["dynamic_clarity"])
            + 0.25 * float(row["scenario_clarity"])
            + 0.20 * float(row["assumption_transparency"])
        )

        distortion_risk_score = (
            0.25 * float(row["false_precision_risk"])
            + 0.30 * float(row["boundary_risk"])
            + 0.20 * float(row["proxy_risk"])
            + 0.25 * float(row["misuse_risk"])
        )

        net_interpretive_value = clarification_score - distortion_risk_score

        output = dict(row)
        output["clarification_score"] = round(clarification_score, 6)
        output["distortion_risk_score"] = round(distortion_risk_score, 6)
        output["net_interpretive_value"] = round(net_interpretive_value, 6)
        output["use_label"] = use_label(net_interpretive_value)
        scored.append(output)

    scored.sort(key=lambda item: float(item["net_interpretive_value"]), reverse=True)
    return scored


def label_summary(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    counts: dict[str, dict[str, object]] = {}
    for row in rows:
        label = str(row["use_label"])
        if label not in counts:
            counts[label] = {
                "use_label": label,
                "model_case_count": 0,
                "average_clarification_score": 0.0,
                "average_distortion_risk_score": 0.0,
                "average_net_interpretive_value": 0.0,
            }
        counts[label]["model_case_count"] += 1
        counts[label]["average_clarification_score"] += float(row["clarification_score"])
        counts[label]["average_distortion_risk_score"] += float(row["distortion_risk_score"])
        counts[label]["average_net_interpretive_value"] += float(row["net_interpretive_value"])

    summary_rows: list[dict[str, object]] = []
    for item in counts.values():
        count = max(int(item["model_case_count"]), 1)
        summary_rows.append({
            "use_label": item["use_label"],
            "model_case_count": count,
            "average_clarification_score": round(float(item["average_clarification_score"]) / count, 6),
            "average_distortion_risk_score": round(float(item["average_distortion_risk_score"]) / count, 6),
            "average_net_interpretive_value": round(float(item["average_net_interpretive_value"]) / count, 6),
        })

    summary_rows.sort(key=lambda row: str(row["use_label"]))
    return summary_rows


def main() -> None:
    model_cases = score_model_cases(read_csv(DATA / "model_cases.csv"))
    risk_register = read_csv(DATA / "risk_register.csv")
    communication_controls = read_csv(DATA / "communication_controls.csv")
    use_scope_register = read_csv(DATA / "use_scope_register.csv")
    distortion_patterns = read_csv(DATA / "distortion_patterns.csv")

    validation_rows = [
        {
            "check": "model_cases_created",
            "passed": len(model_cases) > 0,
            "value": len(model_cases),
        },
        {
            "check": "clarification_scores_between_zero_and_one",
            "passed": all(0 <= float(row["clarification_score"]) <= 1 for row in model_cases),
            "value": "all_clarification_scores_checked",
        },
        {
            "check": "distortion_scores_between_zero_and_one",
            "passed": all(0 <= float(row["distortion_risk_score"]) <= 1 for row in model_cases),
            "value": "all_distortion_scores_checked",
        },
        {
            "check": "risk_register_created",
            "passed": len(risk_register) > 0,
            "value": len(risk_register),
        },
        {
            "check": "communication_controls_created",
            "passed": len(communication_controls) > 0,
            "value": len(communication_controls),
        },
        {
            "check": "use_scope_register_created",
            "passed": len(use_scope_register) > 0,
            "value": len(use_scope_register),
        },
    ]

    write_csv(TABLES / "python_clarification_distortion_model_cases.csv", model_cases)
    write_csv(TABLES / "python_clarification_distortion_label_summary.csv", label_summary(model_cases))
    write_csv(TABLES / "python_clarification_distortion_risk_register.csv", risk_register)
    write_csv(TABLES / "python_communication_controls.csv", communication_controls)
    write_csv(TABLES / "python_use_scope_register.csv", use_scope_register)
    write_csv(TABLES / "python_distortion_patterns.csv", distortion_patterns)
    write_csv(TABLES / "python_clarification_distortion_validation_checks.csv", validation_rows)

    print("Clarification and distortion workflow complete.")
    print(TABLES / "python_clarification_distortion_model_cases.csv")


if __name__ == "__main__":
    main()
