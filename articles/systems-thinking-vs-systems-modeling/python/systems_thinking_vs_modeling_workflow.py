#!/usr/bin/env python3
"""
Systems Thinking vs Systems Modeling professional workflow.

This dependency-light workflow demonstrates how conceptual systems thinking
can be translated into formal systems modeling.

It includes:

1. Conceptual relationship inventory
2. Dynamic simulation of demand, capacity, backlog, trust, rework, and learning
3. Conceptual score versus modeled score comparison
4. Scenario diagnostics
5. Sensitivity analysis
6. Validation checks against synthetic targets
7. Reproducible CSV outputs

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from pathlib import Path
import csv
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


def clamp(value: float, low: float = 0.0, high: float = 200.0) -> float:
    return max(low, min(high, value))


@dataclass(frozen=True)
class Scenario:
    name: str
    demand_growth: float
    capacity_growth: float
    rework_rate: float
    trust_loss_from_backlog: float
    trust_gain_from_service: float
    intervention_pressure: float
    systems_redesign_strength: float
    delay_factor: float
    uncertainty_humility: float
    periods: int = 80


def load_scenarios() -> list[Scenario]:
    rows = read_csv(DATA / "scenario_parameters.csv")
    return [
        Scenario(
            name=row["scenario"],
            demand_growth=float(row["demand_growth"]),
            capacity_growth=float(row["capacity_growth"]),
            rework_rate=float(row["rework_rate"]),
            trust_loss_from_backlog=float(row["trust_loss_from_backlog"]),
            trust_gain_from_service=float(row["trust_gain_from_service"]),
            intervention_pressure=float(row["intervention_pressure"]),
            systems_redesign_strength=float(row["systems_redesign_strength"]),
            delay_factor=float(row["delay_factor"]),
            uncertainty_humility=float(row["uncertainty_humility"]),
        )
        for row in rows
    ]


def simulate(scenario: Scenario) -> list[dict[str, object]]:
    demand = 80.0
    capacity = 70.0
    backlog = 22.0
    trust = 58.0
    rework = 8.0
    learning = 22.0

    rows: list[dict[str, object]] = []

    for period in range(scenario.periods + 1):
        service_gap = max(demand + backlog - capacity, 0.0)
        service_quality = clamp(100.0 - service_gap * 0.50 - rework * 0.35, 0.0, 100.0)

        conceptual_score = clamp(
            50.0
            + scenario.systems_redesign_strength * 24.0
            + scenario.uncertainty_humility * 14.0
            - scenario.intervention_pressure * 8.0
            - service_gap * 0.08,
            0.0,
            100.0,
        )

        modeled_score = clamp(
            service_quality * 0.30
            + trust * 0.25
            + learning * 0.20
            + capacity * 0.10
            - backlog * 0.10
            - rework * 0.15,
            0.0,
            100.0,
        )

        rows.append({
            "scenario": scenario.name,
            "period": period,
            "demand": round(demand, 3),
            "capacity": round(capacity, 3),
            "backlog": round(backlog, 3),
            "trust": round(trust, 3),
            "rework": round(rework, 3),
            "learning": round(learning, 3),
            "service_gap": round(service_gap, 3),
            "service_quality": round(service_quality, 3),
            "conceptual_systems_score": round(conceptual_score, 3),
            "modeled_systems_score": round(modeled_score, 3),
            "conceptual_model_gap": round(conceptual_score - modeled_score, 3),
        })

        pressure_gain = scenario.intervention_pressure * 4.0
        redesign_gain = scenario.systems_redesign_strength * 3.2
        delayed_learning_effect = learning * 0.03 * (1.0 - scenario.delay_factor)

        demand = demand + scenario.demand_growth * demand
        capacity = capacity + scenario.capacity_growth * capacity + redesign_gain + delayed_learning_effect - rework * 0.015
        backlog = backlog + demand * 0.10 + rework * 0.30 - capacity * 0.09 - redesign_gain * 0.80
        rework = rework + service_gap * scenario.rework_rate + pressure_gain * 0.15 - redesign_gain * 0.45
        trust = trust - backlog * scenario.trust_loss_from_backlog + service_quality * scenario.trust_gain_from_service + redesign_gain * 0.10
        learning = learning + scenario.uncertainty_humility * 1.3 + scenario.systems_redesign_strength * 1.1 - scenario.intervention_pressure * 0.45

        demand = clamp(demand, 0.0, 200.0)
        capacity = clamp(capacity, 0.0, 200.0)
        backlog = clamp(backlog, 0.0, 200.0)
        trust = clamp(trust, 0.0, 100.0)
        rework = clamp(rework, 0.0, 120.0)
        learning = clamp(learning, 0.0, 100.0)

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]

        avg_gap = mean(abs(float(row["conceptual_model_gap"])) for row in subset)
        avg_modeled_score = mean(float(row["modeled_systems_score"]) for row in subset)
        max_backlog = max(float(row["backlog"]) for row in subset)
        min_trust = min(float(row["trust"]) for row in subset)

        if avg_gap > 18:
            diagnostic = "conceptual map and formal model diverge; assumptions need revision"
        elif max_backlog > 90:
            diagnostic = "formal model reveals backlog amplification"
        elif min_trust < 35:
            diagnostic = "formal model reveals trust depletion"
        elif avg_modeled_score >= 65:
            diagnostic = "conceptual framing and formal model support systemic improvement"
        else:
            diagnostic = "partial improvement with unresolved structural pressure"

        output.append({
            "scenario": scenario,
            "final_modeled_score": final["modeled_systems_score"],
            "final_conceptual_score": final["conceptual_systems_score"],
            "final_service_quality": final["service_quality"],
            "final_learning": final["learning"],
            "average_absolute_conceptual_model_gap": round(avg_gap, 3),
            "average_modeled_score": round(avg_modeled_score, 3),
            "maximum_backlog": round(max_backlog, 3),
            "minimum_trust": round(min_trust, 3),
            "diagnostic": diagnostic,
        })

    return output


def sensitivity(base: Scenario, delta: float = 0.10) -> list[dict[str, object]]:
    base_score = float(simulate(base)[-1]["modeled_systems_score"])
    parameters = [
        "demand_growth",
        "capacity_growth",
        "rework_rate",
        "trust_loss_from_backlog",
        "trust_gain_from_service",
        "intervention_pressure",
        "systems_redesign_strength",
        "delay_factor",
        "uncertainty_humility",
    ]

    output: list[dict[str, object]] = []

    for parameter in parameters:
        current = getattr(base, parameter)
        for direction in [-1, 1]:
            revised_value = max(0.0, current + direction * delta)
            revised = replace(base, name=f"{base.name}_{parameter}_{direction}", **{parameter: revised_value})
            revised_score = float(simulate(revised)[-1]["modeled_systems_score"])

            output.append({
                "parameter": parameter,
                "delta": round(direction * delta, 3),
                "base_value": round(current, 4),
                "revised_value": round(revised_value, 4),
                "base_final_modeled_score": round(base_score, 3),
                "revised_final_modeled_score": round(revised_score, 3),
                "score_change": round(revised_score - base_score, 3),
                "absolute_score_change": round(abs(revised_score - base_score), 3),
            })

    return sorted(output, key=lambda row: float(row["absolute_score_change"]), reverse=True)


def validate(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {row["metric"]: row for row in read_csv(DATA / "validation_targets.csv")}
    diagnostics: list[dict[str, object]] = []

    metric_map = {
        "final_modeled_score": "final_modeled_score",
        "average_absolute_conceptual_model_gap": "average_absolute_conceptual_model_gap",
        "maximum_backlog": "maximum_backlog",
        "minimum_trust": "minimum_trust",
        "final_service_quality": "final_service_quality",
        "final_learning": "final_learning",
    }

    for row in summary_rows:
        for metric, field in metric_map.items():
            target = targets[metric]
            value = float(row[field])
            low = float(target["target_low"])
            high = float(target["target_high"])

            diagnostics.append({
                "scenario": row["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
                "notes": target["notes"],
            })

    return diagnostics


def main() -> None:
    TABLES.mkdir(parents=True, exist_ok=True)

    conceptual_relationships = read_csv(DATA / "conceptual_relationships.csv")
    scenarios = load_scenarios()

    rows: list[dict[str, object]] = []
    for scenario in scenarios:
        rows.extend(simulate(scenario))

    summary_rows = summarize(rows)
    sensitivity_rows = sensitivity(scenarios[2])
    validation_rows = validate(summary_rows)

    write_csv(TABLES / "python_conceptual_relationship_inventory.csv", conceptual_relationships)
    write_csv(TABLES / "python_systems_thinking_vs_modeling_timeseries.csv", rows)
    write_csv(TABLES / "python_systems_thinking_vs_modeling_summary.csv", summary_rows)
    write_csv(TABLES / "python_systems_thinking_vs_modeling_sensitivity.csv", sensitivity_rows)
    write_csv(TABLES / "python_systems_thinking_vs_modeling_validation.csv", validation_rows)

    print("Systems thinking vs systems modeling workflow complete.")
    print(TABLES / "python_systems_thinking_vs_modeling_summary.csv")


if __name__ == "__main__":
    main()
