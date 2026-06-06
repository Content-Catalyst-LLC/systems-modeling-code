#!/usr/bin/env python3
"""
Validation diagnostics for the synthetic systems modeling workflow.

Reads Python network model outputs and compares high-level metrics against
synthetic plausibility targets.
"""

from __future__ import annotations

from pathlib import Path
import csv


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
TABLES = ARTICLE_ROOT / "outputs" / "tables"
DATA = ARTICLE_ROOT / "data"


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError("No rows to write.")
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    summary_path = TABLES / "python_scenario_summary.csv"
    targets_path = DATA / "synthetic_validation_targets.csv"

    if not summary_path.exists():
        raise SystemExit("Missing python_scenario_summary.csv. Run network_shock_propagation.py first.")

    summary = read_csv(summary_path)
    targets = {row["metric"]: row for row in read_csv(targets_path)}

    diagnostics: list[dict[str, object]] = []
    for scenario in summary:
        for metric, target in targets.items():
            if metric not in scenario:
                continue
            value = float(scenario[metric])
            low = float(target["target_low"])
            high = float(target["target_high"])
            passed = low <= value <= high

            diagnostics.append({
                "scenario": scenario["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": passed,
                "notes": target.get("notes", ""),
            })

    write_csv(TABLES / "python_validation_diagnostics.csv", diagnostics)

    passed_count = sum(1 for row in diagnostics if row["passed"])
    print(f"Validation diagnostics complete: {passed_count}/{len(diagnostics)} checks passed.")
    print(TABLES / "python_validation_diagnostics.csv")


if __name__ == "__main__":
    main()
