#!/usr/bin/env python3
"""
Nonlinearity, thresholds, and regime change workflow.

Dependency-light workflow demonstrating:

1. Nonlinear damage functions
2. Threshold crossing
3. Regime-specific dynamics
4. Hysteresis through separate collapse and recovery thresholds
5. Early-warning diagnostics
6. Scenario comparison
7. Validation checks

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


def simulate_regime_system(row: dict[str, str], steps: int = 140) -> list[dict[str, object]]:
    scenario = row["scenario"]
    collapse_threshold = float(row["collapse_threshold"])
    recovery_threshold = float(row["recovery_threshold"])
    intervention_time = int(float(row["intervention_time"]))
    pressure_growth = float(row["pressure_growth"])
    recovery_effort = float(row["recovery_effort"])
    system_state = float(row["initial_state"])
    pressure = float(row["initial_pressure"])

    regime = "stable"
    state_history = [system_state]
    rows: list[dict[str, object]] = []

    for time in range(1, steps + 1):
        if time > 1:
            pressure += pressure_growth

            if time >= intervention_time:
                pressure = max(0.0, pressure - recovery_effort)

            if regime == "stable" and pressure >= collapse_threshold:
                regime = "degraded"
            elif regime == "degraded" and pressure <= recovery_threshold:
                regime = "stable"

            if regime == "stable":
                damage_flow = 0.05 * pressure + 0.002 * pressure**2
                recovery_flow = 2.6
            else:
                damage_flow = 0.09 * pressure + 0.006 * pressure**2 + 1.8
                recovery_flow = 0.8 + 0.03 * system_state

            net_flow = recovery_flow - damage_flow
            system_state = min(100.0, max(0.0, system_state + net_flow))
            state_history.append(system_state)
        else:
            damage_flow = 0.0
            recovery_flow = 0.0
            net_flow = 0.0

        rolling_variance, rolling_autocorr = rolling_diagnostics(state_history, 12)

        rows.append({
            "scenario": scenario,
            "time": time,
            "system_state": round(system_state, 6),
            "pressure": round(pressure, 6),
            "regime": regime,
            "collapse_threshold": collapse_threshold,
            "recovery_threshold": recovery_threshold,
            "hysteresis_gap": round(collapse_threshold - recovery_threshold, 6),
            "damage_flow": round(damage_flow, 6),
            "recovery_flow": round(recovery_flow, 6),
            "net_flow": round(net_flow, 6),
            "rolling_variance_12": round(rolling_variance, 6) if rolling_variance != "" else "",
            "rolling_autocorrelation_12": round(rolling_autocorr, 6) if rolling_autocorr != "" else "",
        })

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        states = [float(row["system_state"]) for row in subset]
        pressures = [float(row["pressure"]) for row in subset]
        net_flows = [float(row["net_flow"]) for row in subset]
        degraded_times = [int(row["time"]) for row in subset if row["regime"] == "degraded"]
        rolling_variances = [
            float(row["rolling_variance_12"])
            for row in subset
            if row["rolling_variance_12"] != ""
        ]
        rolling_autocorrs = [
            float(row["rolling_autocorrelation_12"])
            for row in subset
            if row["rolling_autocorrelation_12"] != ""
        ]

        collapse_threshold = float(subset[0]["collapse_threshold"])
        recovery_threshold = float(subset[0]["recovery_threshold"])
        hysteresis_gap = collapse_threshold - recovery_threshold

        summary_rows.append({
            "scenario": scenario,
            "initial_state": round(states[0], 6),
            "final_state": round(states[-1], 6),
            "minimum_state": round(min(states), 6),
            "maximum_pressure": round(max(pressures), 6),
            "collapse_threshold": collapse_threshold,
            "recovery_threshold": recovery_threshold,
            "hysteresis_gap": round(hysteresis_gap, 6),
            "first_degraded_time": min(degraded_times) if degraded_times else "",
            "degraded_periods": len(degraded_times),
            "final_regime": subset[-1]["regime"],
            "mean_net_flow": round(mean(net_flows), 6),
            "maximum_rolling_variance_12": round(max(rolling_variances), 6) if rolling_variances else "",
            "maximum_rolling_autocorrelation_12": round(max(rolling_autocorrs), 6) if rolling_autocorrs else "",
            "diagnostic_label": (
                "persistent degraded regime"
                if subset[-1]["regime"] == "degraded"
                else "threshold avoided"
                if not degraded_times
                else "regime recovery after degradation"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_regime_system(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []
    for row in summary_rows:
        for metric, low, high in [
            ("final_state", 0.0, 100.0),
            ("minimum_state", 0.0, 100.0),
            ("maximum_pressure", 0.0, 1000000.0),
            ("hysteresis_gap", 0.0, 1000000.0),
            ("degraded_periods", 0.0, 1000000.0),
            ("mean_net_flow", -1000000.0, 1000000.0),
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

        if row["maximum_rolling_autocorrelation_12"] != "":
            value = float(row["maximum_rolling_autocorrelation_12"])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": "maximum_rolling_autocorrelation_12",
                "value": round(value, 6),
                "target_low": -1.0,
                "target_high": 1.0,
                "passed": -1.0 <= value <= 1.0,
            })

    write_csv(TABLES / "python_nonlinearity_taxonomy.csv", read_csv(DATA / "nonlinearity_taxonomy.csv"))
    write_csv(TABLES / "python_domain_threshold_examples.csv", read_csv(DATA / "domain_threshold_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_nonlinear_regime_trajectories.csv", all_rows)
    write_csv(TABLES / "python_nonlinear_regime_summary.csv", summary_rows)
    write_csv(TABLES / "python_nonlinear_regime_validation_checks.csv", validation_rows)

    print("Nonlinearity, threshold, and regime-change workflow complete.")
    print(TABLES / "python_nonlinear_regime_summary.csv")


if __name__ == "__main__":
    main()
