#!/usr/bin/env python3
"""
Communicating model results responsibly workflow.

Dependency-light workflow demonstrating model result briefing tables,
uncertainty range calculation, communication quality scoring, false precision
risk labels, valid-use registers, communication controls, visualization
safeguards, and validation checks.

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


def false_precision_label(uncertainty_disclosure: float, uncertainty_width: float) -> str:
    if uncertainty_disclosure < 0.60 and uncertainty_width > 0.20:
        return "high_false_precision_risk"
    if uncertainty_disclosure < 0.70:
        return "moderate_false_precision_risk"
    return "lower_false_precision_risk"


def score_results(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    scored: list[dict[str, object]] = []

    for row in rows:
        uncertainty_width = float(row["upper_bound"]) - float(row["lower_bound"])
        communication_quality_score = (
            0.30 * float(row["assumption_disclosure"])
            + 0.30 * float(row["uncertainty_disclosure"])
            + 0.20 * float(row["boundary_disclosure"])
            + 0.20 * float(row["misuse_warning"])
        )

        output = dict(row)
        output["uncertainty_width"] = round(uncertainty_width, 6)
        output["communication_quality_score"] = round(communication_quality_score, 6)
        output["false_precision_risk"] = false_precision_label(
            float(row["uncertainty_disclosure"]),
            uncertainty_width,
        )
        scored.append(output)

    scored.sort(key=lambda item: float(item["communication_quality_score"]))
    return scored


def control_summary(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    present_count = sum(1 for row in rows if row["present"].lower() == "true")
    missing_count = len(rows) - present_count
    return [
        {"metric": "communication_controls", "value": len(rows)},
        {"metric": "present_controls", "value": present_count},
        {"metric": "missing_controls", "value": missing_count},
    ]


def main() -> None:
    model_results = score_results(read_csv(DATA / "model_results.csv"))
    communication_controls = read_csv(DATA / "communication_controls.csv")
    valid_use_register = read_csv(DATA / "valid_use_register.csv")
    audience_briefing_needs = read_csv(DATA / "audience_briefing_needs.csv")
    visualization_safeguards = read_csv(DATA / "visualization_safeguards.csv")

    validation_rows = [
        {"check": "model_results_created", "passed": len(model_results) > 0, "value": len(model_results)},
        {
            "check": "communication_scores_between_zero_and_one",
            "passed": all(0 <= float(row["communication_quality_score"]) <= 1 for row in model_results),
            "value": "all_scores_checked",
        },
        {
            "check": "uncertainty_widths_nonnegative",
            "passed": all(float(row["uncertainty_width"]) >= 0 for row in model_results),
            "value": "all_widths_checked",
        },
        {"check": "communication_controls_created", "passed": len(communication_controls) > 0, "value": len(communication_controls)},
        {"check": "valid_use_register_created", "passed": len(valid_use_register) > 0, "value": len(valid_use_register)},
        {"check": "visualization_safeguards_created", "passed": len(visualization_safeguards) > 0, "value": len(visualization_safeguards)},
    ]

    write_csv(TABLES / "python_model_result_communication_diagnostics.csv", model_results)
    write_csv(TABLES / "python_model_communication_controls.csv", communication_controls)
    write_csv(TABLES / "python_model_communication_control_summary.csv", control_summary(communication_controls))
    write_csv(TABLES / "python_model_valid_use_register.csv", valid_use_register)
    write_csv(TABLES / "python_audience_briefing_needs.csv", audience_briefing_needs)
    write_csv(TABLES / "python_visualization_safeguards.csv", visualization_safeguards)
    write_csv(TABLES / "python_model_communication_validation_checks.csv", validation_rows)

    print("Communicating model results responsibly workflow complete.")
    print(TABLES / "python_model_result_communication_diagnostics.csv")


if __name__ == "__main__":
    main()
