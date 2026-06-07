#!/usr/bin/env python3
"""
Critical transitions and tipping points workflow.

Dependency-light workflow demonstrating:

1. Nonlinear tipping dynamics
2. Gradual forcing
3. Hysteresis
4. Approximate transition detection
5. Rolling variance
6. Lag-1 autocorrelation
7. Scenario comparison
8. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
from statistics import mean, variance


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


def update_state(x: float, r: float, dt: float) -> float:
    return x + dt * (r + x - x**3)


def lag1_autocorrelation(values: list[float]) -> float | str:
    if len(values) < 3:
        return ""

    left = values[:-1]
    right = values[1:]
    left_mean = mean(left)
    right_mean = mean(right)

    numerator = sum((a - left_mean) * (b - right_mean) for a, b in zip(left, right))
    left_denominator = sum((a - left_mean) ** 2 for a in left)
    right_denominator = sum((b - right_mean) ** 2 for b in right)

    if left_denominator == 0 or right_denominator == 0:
        return ""

    return numerator / (left_denominator * right_denominator) ** 0.5


def rolling_diagnostics(values: list[float], window: int) -> tuple[float | str, float | str]:
    if len(values) < window:
        return "", ""

    recent = values[-window:]
    return variance(recent), lag1_autocorrelation(recent)


def linear_space(start: float, stop: float, count: int) -> list[float]:
    if count < 2:
        return [start]

    step = (stop - start) / (count - 1)
    return [start + i * step for i in range(count)]


def simulate_path(
    scenario: str,
    path_name: str,
    r_values: list[float],
    initial_x: float,
    dt: float,
    transition_jump_threshold: float,
) -> list[dict[str, object]]:
    x = initial_x
    state_history: list[float] = []
    rows: list[dict[str, object]] = []

    for step, r_value in enumerate(r_values, start=1):
        previous_x = x

        if step > 1:
            x = update_state(x, r_value, dt=dt)

        jump_size = abs(x - previous_x) if step > 1 else 0.0
        state_history.append(x)
        rolling_variance, rolling_autocorr = rolling_diagnostics(state_history, 20)

        rows.append({
            "scenario": scenario,
            "path": path_name,
            "step": step,
            "control_parameter": round(r_value, 6),
            "system_state": round(x, 6),
            "jump_size": round(jump_size, 6),
            "transition_flag": int(jump_size > transition_jump_threshold),
            "rolling_variance_20": round(rolling_variance, 6) if rolling_variance != "" else "",
            "rolling_autocorrelation_20": round(rolling_autocorr, 6) if rolling_autocorr != "" else "",
            "dt": dt,
            "transition_jump_threshold": transition_jump_threshold,
        })

    return rows


def simulate_scenario(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    forward_start = float(row["forward_start"])
    forward_end = float(row["forward_end"])
    steps = int(float(row["steps"]))
    initial_state = float(row["initial_state"])
    dt = float(row["dt"])
    transition_jump_threshold = float(row["transition_jump_threshold"])

    forward_r = linear_space(forward_start, forward_end, steps)
    forward_rows = simulate_path(
        scenario,
        "forward_forcing",
        forward_r,
        initial_state,
        dt,
        transition_jump_threshold,
    )

    backward_r = linear_space(forward_end, forward_start, steps)
    backward_rows = simulate_path(
        scenario,
        "backward_forcing",
        backward_r,
        float(forward_rows[-1]["system_state"]),
        dt,
        transition_jump_threshold,
    )

    return forward_rows + backward_rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    scenarios = sorted(set(str(row["scenario"]) for row in rows))

    for scenario in scenarios:
        scenario_subset = [row for row in rows if row["scenario"] == scenario]
        paths = sorted(set(str(row["path"]) for row in scenario_subset))

        transition_parameters: dict[str, float | str] = {}

        for path_name in paths:
            subset = [row for row in scenario_subset if row["path"] == path_name]
            states = [float(row["system_state"]) for row in subset]
            controls = [float(row["control_parameter"]) for row in subset]

            transition_rows = [row for row in subset if int(row["transition_flag"]) == 1]
            transition_step: int | str = int(transition_rows[0]["step"]) if transition_rows else ""
            transition_parameter: float | str = (
                float(transition_rows[0]["control_parameter"]) if transition_rows else ""
            )
            transition_parameters[path_name] = transition_parameter

            rolling_variances = [
                float(row["rolling_variance_20"])
                for row in subset
                if row["rolling_variance_20"] != ""
            ]
            rolling_autocorrs = [
                float(row["rolling_autocorrelation_20"])
                for row in subset
                if row["rolling_autocorrelation_20"] != ""
            ]

            summary_rows.append({
                "scenario": scenario,
                "path": path_name,
                "initial_state": round(states[0], 6),
                "final_state": round(states[-1], 6),
                "minimum_state": round(min(states), 6),
                "maximum_state": round(max(states), 6),
                "minimum_control_parameter": round(min(controls), 6),
                "maximum_control_parameter": round(max(controls), 6),
                "approximate_transition_step": transition_step,
                "approximate_transition_parameter": round(transition_parameter, 6) if transition_parameter != "" else "",
                "maximum_jump_size": round(max(float(row["jump_size"]) for row in subset), 6),
                "maximum_rolling_variance_20": round(max(rolling_variances), 6) if rolling_variances else "",
                "maximum_rolling_autocorrelation_20": round(max(rolling_autocorrs), 6) if rolling_autocorrs else "",
                "diagnostic_label": "path-dependent transition" if transition_step != "" else "smooth response",
            })

        forward_transition = transition_parameters.get("forward_forcing", "")
        backward_transition = transition_parameters.get("backward_forcing", "")
        if forward_transition != "" and backward_transition != "":
            summary_rows.append({
                "scenario": scenario,
                "path": "hysteresis_gap",
                "initial_state": "",
                "final_state": "",
                "minimum_state": "",
                "maximum_state": "",
                "minimum_control_parameter": "",
                "maximum_control_parameter": "",
                "approximate_transition_step": "",
                "approximate_transition_parameter": round(abs(float(forward_transition) - float(backward_transition)), 6),
                "maximum_jump_size": "",
                "maximum_rolling_variance_20": "",
                "maximum_rolling_autocorrelation_20": "",
                "diagnostic_label": "estimated hysteresis gap",
            })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_scenario(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        if row["path"] == "hysteresis_gap":
            if row["approximate_transition_parameter"] != "":
                value = float(row["approximate_transition_parameter"])
                validation_rows.append({
                    "scenario": row["scenario"],
                    "path": row["path"],
                    "metric": "hysteresis_gap",
                    "value": round(value, 6),
                    "target_low": 0.0,
                    "target_high": 1000000.0,
                    "passed": value >= 0.0,
                })
            continue

        for metric, low, high in [
            ("minimum_state", -1000000.0, 1000000.0),
            ("maximum_state", -1000000.0, 1000000.0),
            ("final_state", -1000000.0, 1000000.0),
            ("maximum_jump_size", 0.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "path": row["path"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

        if row["maximum_rolling_autocorrelation_20"] != "":
            value = float(row["maximum_rolling_autocorrelation_20"])
            validation_rows.append({
                "scenario": row["scenario"],
                "path": row["path"],
                "metric": "maximum_rolling_autocorrelation_20",
                "value": round(value, 6),
                "target_low": -1.0,
                "target_high": 1.0,
                "passed": -1.0 <= value <= 1.0,
            })

    write_csv(TABLES / "python_tipping_mechanisms.csv", read_csv(DATA / "tipping_mechanisms.csv"))
    write_csv(TABLES / "python_domain_tipping_examples.csv", read_csv(DATA / "domain_tipping_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_critical_transition_hysteresis_trajectories.csv", all_rows)
    write_csv(TABLES / "python_critical_transition_hysteresis_summary.csv", summary_rows)
    write_csv(TABLES / "python_critical_transition_validation_checks.csv", validation_rows)

    print("Critical transitions and tipping points workflow complete.")
    print(TABLES / "python_critical_transition_hysteresis_summary.csv")


if __name__ == "__main__":
    main()
