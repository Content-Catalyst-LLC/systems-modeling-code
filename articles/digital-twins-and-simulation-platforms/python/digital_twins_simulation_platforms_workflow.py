#!/usr/bin/env python3
"""
Digital twins and simulation platforms workflow.

Dependency-light workflow demonstrating:

1. Hidden physical state simulation
2. Noisy observations
3. Twin state tracking and synchronization
4. Residual-based anomaly detection
5. Simple intervention triggers
6. Scenario comparison and validation checks
7. Component, operating-loop, platform, governance, and validation taxonomies

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import math
import random
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

    all_fieldnames: list[str] = []
    for row in rows:
        for key in row.keys():
            if key not in all_fieldnames:
                all_fieldnames.append(key)

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=all_fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def parse_shock_times(value: str) -> set[int]:
    return {int(item.strip()) for item in value.split("|") if item.strip()}


def mae(actual: list[float], predicted: list[float]) -> float:
    return mean(abs(a - p) for a, p in zip(actual, predicted))


def rmse(actual: list[float], predicted: list[float]) -> float:
    return math.sqrt(mean((a - p) ** 2 for a, p in zip(actual, predicted)))


def simulate_scenario(row: dict[str, str]) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    scenario = row["scenario"]
    n_steps = int(float(row["n_steps"]))
    initial_state = float(row["initial_state"])
    state_persistence = float(row["state_persistence"])
    drift_amplitude = float(row["drift_amplitude"])
    process_noise = float(row["process_noise"])
    observation_noise = float(row["observation_noise"])
    update_gain = float(row["update_gain"])
    anomaly_threshold = float(row["anomaly_threshold"])
    intervention_effect = float(row["intervention_effect"])
    shock_times = parse_shock_times(row["shock_times"])
    shock_magnitude = float(row["shock_magnitude"])
    seed = int(float(row["seed"]))

    rng = random.Random(seed)

    true_state = [0.0 for _ in range(n_steps)]
    observed_state = [0.0 for _ in range(n_steps)]
    twin_state = [0.0 for _ in range(n_steps)]
    predictions = [0.0 for _ in range(n_steps)]
    residuals = [0.0 for _ in range(n_steps)]
    anomaly_flags = [0 for _ in range(n_steps)]
    intervention_flags = [0 for _ in range(n_steps)]

    true_state[0] = initial_state
    observed_state[0] = true_state[0] + rng.gauss(0.0, observation_noise)
    twin_state[0] = observed_state[0]
    predictions[0] = twin_state[0]

    sensor_drift = 0.0

    for time in range(1, n_steps):
        drift = drift_amplitude * math.sin(time / 12.0)
        shock = shock_magnitude if time in shock_times else 0.0

        true_state[time] = (
            state_persistence * true_state[time - 1]
            + drift
            + shock
            + rng.gauss(0.0, process_noise)
        )

        if scenario == "sensor_drift_twin":
            sensor_drift += 0.018

        observed_state[time] = true_state[time] + sensor_drift + rng.gauss(0.0, observation_noise)

        prediction = state_persistence * twin_state[time - 1] + drift
        residual = observed_state[time] - prediction

        if abs(residual) > anomaly_threshold:
            anomaly_flags[time] = 1

        if residual > anomaly_threshold:
            intervention_flags[time] = 1
            prediction -= intervention_effect

        predictions[time] = prediction
        residuals[time] = residual
        twin_state[time] = prediction + update_gain * residual

    trajectory_rows = []

    for time in range(n_steps):
        trajectory_rows.append({
            "scenario": scenario,
            "time": time,
            "true_state": round(true_state[time], 6),
            "observed_state": round(observed_state[time], 6),
            "prediction_before_update": round(predictions[time], 6),
            "twin_state": round(twin_state[time], 6),
            "residual": round(residuals[time], 6),
            "anomaly_flag": anomaly_flags[time],
            "intervention_flag": intervention_flags[time],
        })

    observed_mae = mae(true_state, observed_state)
    twin_mae = mae(true_state, twin_state)
    observed_rmse = rmse(true_state, observed_state)
    twin_rmse = rmse(true_state, twin_state)
    improvement_ratio = (observed_rmse - twin_rmse) / max(observed_rmse, 1e-12)

    summary_rows = [
        {
            "scenario": scenario,
            "metric": "MAE_observed",
            "value": round(observed_mae, 6),
        },
        {
            "scenario": scenario,
            "metric": "MAE_twin",
            "value": round(twin_mae, 6),
        },
        {
            "scenario": scenario,
            "metric": "RMSE_observed",
            "value": round(observed_rmse, 6),
        },
        {
            "scenario": scenario,
            "metric": "RMSE_twin",
            "value": round(twin_rmse, 6),
        },
        {
            "scenario": scenario,
            "metric": "anomaly_count",
            "value": sum(anomaly_flags),
        },
        {
            "scenario": scenario,
            "metric": "intervention_count",
            "value": sum(intervention_flags),
        },
        {
            "scenario": scenario,
            "metric": "tracking_improvement_ratio",
            "value": round(improvement_ratio, 6),
        },
    ]

    validation_rows = [
        {
            "scenario": scenario,
            "check": "twin_mae_less_than_observed_mae",
            "passed": twin_mae < observed_mae,
            "observed_value": round(observed_mae, 6),
            "twin_value": round(twin_mae, 6),
        },
        {
            "scenario": scenario,
            "check": "twin_rmse_less_than_observed_rmse",
            "passed": twin_rmse < observed_rmse,
            "observed_value": round(observed_rmse, 6),
            "twin_value": round(twin_rmse, 6),
        },
        {
            "scenario": scenario,
            "check": "anomaly_count_nonnegative",
            "passed": sum(anomaly_flags) >= 0,
            "observed_value": 0,
            "twin_value": sum(anomaly_flags),
        },
        {
            "scenario": scenario,
            "check": "intervention_count_nonnegative",
            "passed": sum(intervention_flags) >= 0,
            "observed_value": 0,
            "twin_value": sum(intervention_flags),
        },
    ]

    return trajectory_rows, summary_rows, validation_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_trajectories: list[dict[str, object]] = []
    all_summary: list[dict[str, object]] = []
    all_validations: list[dict[str, object]] = []

    for scenario in scenario_rows:
        trajectories, summary, validations = simulate_scenario(scenario)
        all_trajectories.extend(trajectories)
        all_summary.extend(summary)
        all_validations.extend(validations)

    write_csv(TABLES / "python_digital_twin_components.csv", read_csv(DATA / "digital_twin_components.csv"))
    write_csv(TABLES / "python_operating_loop.csv", read_csv(DATA / "operating_loop.csv"))
    write_csv(TABLES / "python_platform_layers.csv", read_csv(DATA / "platform_layers.csv"))
    write_csv(TABLES / "python_governance_register.csv", read_csv(DATA / "governance_register.csv"))
    write_csv(TABLES / "python_validation_dimensions.csv", read_csv(DATA / "validation_dimensions.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_digital_twin_trajectories.csv", all_trajectories)
    write_csv(TABLES / "python_digital_twin_monitoring_summary.csv", all_summary)
    write_csv(TABLES / "python_digital_twin_validation_checks.csv", all_validations)

    print("Digital twins and simulation platforms workflow complete.")
    print(TABLES / "python_digital_twin_monitoring_summary.csv")


if __name__ == "__main__":
    main()
