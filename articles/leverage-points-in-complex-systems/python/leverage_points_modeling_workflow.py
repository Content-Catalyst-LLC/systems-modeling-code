#!/usr/bin/env python3
"""
Leverage points in complex systems workflow.

Dependency-light workflow demonstrating:

1. Meadows-style leverage hierarchy inventory
2. Baseline system behavior
3. Parameter, buffer, delay, feedback, information, rule, self-organization, and goal interventions
4. Implementation-delay stress
5. Leverage ratio diagnostics
6. Validation checks

All data are synthetic.
"""

from __future__ import annotations

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


def optional_float(value: str, default: float | None = None) -> float | None:
    if value == "" or value is None:
        return default
    return float(value)


def simulate_system(
    scenario: str,
    feedback_gain: float,
    external_correction: float,
    information_delay: int,
    information_quality: float,
    buffer_capacity: float,
    rule_threshold: float | None,
    rule_feedback_gain: float,
    self_organization_rate: float,
    goal_weight_resilience: float,
    implementation_delay: int,
    steps: int = 96,
) -> list[dict[str, object]]:
    state = [70.0]
    pressure = [50.0]
    resilience = [30.0]
    learning_capacity = [0.0]
    intervention = [0.0]
    buffer_remaining = [buffer_capacity]

    rows: list[dict[str, object]] = []

    for time in range(1, steps):
        observed_index = max(0, time - information_delay)
        delayed_signal = state[observed_index]
        current_signal = state[-1]
        observed_state = information_quality * current_signal + (1.0 - information_quality) * delayed_signal

        current_gain = feedback_gain
        if rule_threshold is not None and observed_state > rule_threshold:
            current_gain = rule_feedback_gain

        learning_next = min(
            100.0,
            learning_capacity[-1] + self_organization_rate * (100.0 - learning_capacity[-1]) / 8.0,
        )

        resilience_gap = max(0.0, 100.0 - resilience[-1])
        resilience_investment = goal_weight_resilience * resilience_gap

        buffer_absorption = min(buffer_remaining[-1], 0.10 * pressure[-1])
        next_buffer = max(0.0, buffer_remaining[-1] - buffer_absorption + 0.02 * buffer_capacity)

        correction = 0.0
        if time >= implementation_delay:
            correction = (
                external_correction
                + 0.05 * max(0.0, observed_state - 40.0)
                + resilience_investment
                + 0.04 * learning_next
            )

        next_pressure = max(
            0.0,
            0.91 * pressure[-1]
            + 0.07 * state[-1]
            - 0.30 * correction
            - 0.08 * buffer_absorption
            - 0.04 * resilience[-1],
        )

        next_resilience = min(
            100.0,
            max(
                0.0,
                resilience[-1]
                + 0.18 * resilience_investment
                + 0.05 * learning_next
                - 0.025 * pressure[-1],
            ),
        )

        next_state = max(
            0.0,
            current_gain * state[-1]
            + 0.24 * next_pressure
            - 0.34 * correction
            - 0.08 * buffer_absorption
            - 0.045 * next_resilience,
        )

        pressure.append(next_pressure)
        resilience.append(next_resilience)
        state.append(next_state)
        learning_capacity.append(learning_next)
        intervention.append(correction)
        buffer_remaining.append(next_buffer)

    for time in range(steps):
        rows.append({
            "scenario": scenario,
            "time": time + 1,
            "state": round(state[time], 6),
            "pressure": round(pressure[time], 6),
            "resilience": round(resilience[time], 6),
            "learning_capacity": round(learning_capacity[time], 6),
            "intervention": round(intervention[time], 6),
            "buffer_remaining": round(buffer_remaining[time], 6),
        })

    return rows


def classify_depth(scenario: str) -> str:
    if scenario == "baseline":
        return "baseline"
    if scenario == "parameter_intervention":
        return "shallow"
    if scenario in {"buffer_intervention", "delay_intervention"}:
        return "moderate"
    if scenario in {"feedback_intervention", "information_flow_intervention", "rule_intervention"}:
        return "structural"
    return "deep"


def summarize(rows: list[dict[str, object]], baseline_final_state: float) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        states = [float(row["state"]) for row in subset]
        pressures = [float(row["pressure"]) for row in subset]
        resilience_values = [float(row["resilience"]) for row in subset]
        learning_values = [float(row["learning_capacity"]) for row in subset]
        interventions = [float(row["intervention"]) for row in subset]

        final_state = states[-1]
        cumulative_intervention = sum(interventions)
        behavior_change = baseline_final_state - final_state
        leverage_ratio = behavior_change / cumulative_intervention if cumulative_intervention > 0 else 0.0

        summary_rows.append({
            "scenario": scenario,
            "intervention_depth": classify_depth(scenario),
            "initial_state": round(states[0], 6),
            "final_state": round(final_state, 6),
            "maximum_state": round(max(states), 6),
            "minimum_state": round(min(states), 6),
            "mean_pressure": round(mean(pressures), 6),
            "final_resilience": round(resilience_values[-1], 6),
            "final_learning_capacity": round(learning_values[-1], 6),
            "cumulative_intervention": round(cumulative_intervention, 6),
            "behavior_change_from_baseline": round(behavior_change, 6),
            "leverage_ratio": round(leverage_ratio, 6),
            "interpretation": (
                "reference case"
                if scenario == "baseline"
                else "changes a number inside the existing structure"
                if classify_depth(scenario) == "shallow"
                else "changes timing or buffers without fully changing rules"
                if classify_depth(scenario) == "moderate"
                else "changes feedback information or rule logic"
                if classify_depth(scenario) == "structural"
                else "changes adaptive capacity goals or implementation logic"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "intervention_scenarios.csv")

    all_rows: list[dict[str, object]] = []

    for row in scenario_rows:
        all_rows.extend(
            simulate_system(
                scenario=row["scenario"],
                feedback_gain=float(row["feedback_gain"]),
                external_correction=float(row["external_correction"]),
                information_delay=int(row["information_delay"]),
                information_quality=float(row["information_quality"]),
                buffer_capacity=float(row["buffer_capacity"]),
                rule_threshold=optional_float(row["rule_threshold"], None),
                rule_feedback_gain=float(row["rule_feedback_gain"]),
                self_organization_rate=float(row["self_organization_rate"]),
                goal_weight_resilience=float(row["goal_weight_resilience"]),
                implementation_delay=int(row["implementation_delay"]),
            )
        )

    baseline_final_state = [
        float(row["state"])
        for row in all_rows
        if row["scenario"] == "baseline"
    ][-1]

    summary_rows = summarize(all_rows, baseline_final_state)

    ranking_rows = [
        dict(row)
        for row in sorted(
            [
                row
                for row in summary_rows
                if row["scenario"] != "baseline"
            ],
            key=lambda item: float(item["leverage_ratio"]),
            reverse=True,
        )
    ]

    for index, row in enumerate(ranking_rows, start=1):
        row["rank_by_leverage_ratio"] = index

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_state", 0.0, 1000000.0),
            ("maximum_state", 0.0, 1000000.0),
            ("mean_pressure", 0.0, 1000000.0),
            ("final_resilience", 0.0, 100.0),
            ("final_learning_capacity", 0.0, 100.0),
            ("cumulative_intervention", 0.0, 1000000.0),
            ("leverage_ratio", -1000000.0, 1000000.0),
            ("behavior_change_from_baseline", -1000000.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_leverage_point_hierarchy.csv", read_csv(DATA / "leverage_point_hierarchy.csv"))
    write_csv(TABLES / "python_domain_examples.csv", read_csv(DATA / "domain_examples.csv"))
    write_csv(TABLES / "python_intervention_scenarios.csv", scenario_rows)
    write_csv(TABLES / "python_leverage_intervention_trajectories.csv", all_rows)
    write_csv(TABLES / "python_leverage_intervention_summary.csv", summary_rows)
    write_csv(TABLES / "python_leverage_intervention_ranking.csv", ranking_rows)
    write_csv(TABLES / "python_leverage_validation_checks.csv", validation_rows)

    print("Leverage points workflow complete.")
    print(TABLES / "python_leverage_intervention_summary.csv")


if __name__ == "__main__":
    main()
