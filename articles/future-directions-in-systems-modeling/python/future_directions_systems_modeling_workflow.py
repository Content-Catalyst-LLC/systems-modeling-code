#!/usr/bin/env python3
"""
Future directions in systems modeling.

Dependency-light workflow demonstrating:

1. Hidden system simulation
2. Noisy observations
3. Rolling state estimation
4. Anomaly detection
5. Adaptive intervention flags
6. Drift indicators
7. Governance and trigger registers
8. Validation checks

All data are synthetic.
"""

from __future__ import annotations

import csv
import math
import random
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


def mean(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


def simulate_monitoring_loop(n_steps: int = 120) -> list[dict[str, object]]:
    random.seed(42)

    true_state = [0.0] * n_steps
    observed_state = [0.0] * n_steps
    estimated_state = [0.0] * n_steps
    intervention_flag = [0] * n_steps
    drift_indicator = [0.0] * n_steps
    capacity = [18.0] * n_steps

    true_state[0] = 12.0
    observed_state[0] = true_state[0] + random.gauss(0, 1.0)
    estimated_state[0] = observed_state[0]

    for t in range(1, n_steps):
        shock = 4.5 if t in (35, 70, 95) else 0.0

        true_state[t] = (
            0.93 * true_state[t - 1]
            + 0.3 * math.sin(t / 10)
            + shock
            + random.gauss(0, 0.5)
        )

        observed_state[t] = true_state[t] + random.gauss(0, 1.0)

        prediction = 0.93 * estimated_state[t - 1] + 0.3 * math.sin(t / 10)
        residual = observed_state[t] - prediction

        if abs(residual) > 3.0:
            intervention_flag[t] = 1
            prediction = prediction + 0.25 * residual

        estimated_state[t] = 0.70 * prediction + 0.30 * observed_state[t]

        start = max(0, t - 9)
        recent_residuals = [
            abs(observed_state[i] - estimated_state[i])
            for i in range(start, t + 1)
        ]
        drift_indicator[t] = mean(recent_residuals)

    rows: list[dict[str, object]] = []
    for t in range(n_steps):
        rows.append(
            {
                "time": t,
                "true_state": round(true_state[t], 6),
                "observed_state": round(observed_state[t], 6),
                "estimated_state": round(estimated_state[t], 6),
                "absolute_error_observed": round(abs(observed_state[t] - true_state[t]), 6),
                "absolute_error_estimated": round(abs(estimated_state[t] - true_state[t]), 6),
                "drift_indicator": round(drift_indicator[t], 6),
                "capacity_margin": round(capacity[t] - estimated_state[t], 6),
                "intervention_flag": intervention_flag[t],
            }
        )

    return rows


def main() -> None:
    monitoring_rows = simulate_monitoring_loop()
    governance_controls = read_csv(DATA / "model_governance_controls.csv")
    capability_register = read_csv(DATA / "future_capability_register.csv")
    adaptive_triggers = read_csv(DATA / "adaptive_triggers.csv")

    observed_errors = [float(row["absolute_error_observed"]) for row in monitoring_rows]
    estimated_errors = [float(row["absolute_error_estimated"]) for row in monitoring_rows]
    drift_values = [float(row["drift_indicator"]) for row in monitoring_rows]
    interventions = [int(row["intervention_flag"]) for row in monitoring_rows]

    summary_rows = [
        {"metric": "MAE_observed", "value": round(mean(observed_errors), 6)},
        {"metric": "MAE_estimated", "value": round(mean(estimated_errors), 6)},
        {"metric": "Max_drift_indicator", "value": round(max(drift_values), 6)},
        {"metric": "Intervention_count", "value": sum(interventions)},
        {"metric": "Minimum_capacity_margin", "value": round(min(float(row["capacity_margin"]) for row in monitoring_rows), 6)},
    ]

    validation_rows = [
        {"check": "time_steps_created", "passed": len(monitoring_rows) > 0, "value": len(monitoring_rows)},
        {"check": "estimated_state_created", "passed": all(row["estimated_state"] is not None for row in monitoring_rows), "value": "all_estimates_checked"},
        {"check": "observed_errors_nonnegative", "passed": all(float(row["absolute_error_observed"]) >= 0 for row in monitoring_rows), "value": "all_observed_errors_checked"},
        {"check": "estimated_errors_nonnegative", "passed": all(float(row["absolute_error_estimated"]) >= 0 for row in monitoring_rows), "value": "all_estimated_errors_checked"},
        {"check": "drift_indicator_nonnegative", "passed": all(float(row["drift_indicator"]) >= 0 for row in monitoring_rows), "value": "all_drift_indicators_checked"},
        {"check": "intervention_flags_binary", "passed": all(row["intervention_flag"] in (0, 1) for row in monitoring_rows), "value": "all_intervention_flags_checked"},
        {"check": "governance_controls_created", "passed": len(governance_controls) > 0, "value": len(governance_controls)},
        {"check": "adaptive_triggers_created", "passed": len(adaptive_triggers) > 0, "value": len(adaptive_triggers)},
    ]

    write_csv(TABLES / "python_future_systems_modeling_hybrid_monitoring.csv", monitoring_rows)
    write_csv(TABLES / "python_future_systems_modeling_hybrid_summary.csv", summary_rows)
    write_csv(TABLES / "python_model_governance_controls.csv", governance_controls)
    write_csv(TABLES / "python_future_capability_register.csv", capability_register)
    write_csv(TABLES / "python_adaptive_triggers.csv", adaptive_triggers)
    write_csv(TABLES / "python_future_systems_modeling_validation_checks.csv", validation_rows)

    print("Future systems modeling hybrid monitoring workflow complete.")
    print(TABLES / "python_future_systems_modeling_hybrid_monitoring.csv")


if __name__ == "__main__":
    main()
