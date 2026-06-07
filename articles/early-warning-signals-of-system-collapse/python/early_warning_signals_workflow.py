#!/usr/bin/env python3
"""
Early warning signals of system collapse workflow.

Dependency-light workflow demonstrating:

1. Simulated weakening recovery
2. Rolling variance
3. Rolling lag-1 autocorrelation
4. Trend diagnostics
5. Scenario comparison
6. Validation checks
7. Indicator, spatial, and network taxonomies

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import random
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


def linear_space(start: float, stop: float, count: int) -> list[float]:
    if count < 2:
        return [start]

    step = (stop - start) / (count - 1)
    return [start + i * step for i in range(count)]


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


def rolling_metrics(values: list[float], window: int) -> tuple[float | str, float | str]:
    if len(values) < window:
        return "", ""

    recent = values[-window:]
    return variance(recent), lag1_autocorrelation(recent)


def estimate_slope(x_values: list[float], y_values: list[float]) -> float:
    if len(x_values) < 2 or len(y_values) < 2:
        return 0.0

    x_mean = mean(x_values)
    y_mean = mean(y_values)

    numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_values, y_values))
    denominator = sum((x - x_mean) ** 2 for x in x_values)

    if denominator == 0:
        return 0.0

    return numerator / denominator


def simulate_series(row: dict[str, str], seed: int = 42) -> list[dict[str, object]]:
    scenario = row["scenario"]
    steps = int(float(row["steps"]))
    stability_start = float(row["stability_start"])
    stability_end = float(row["stability_end"])
    noise_sd = float(row["noise_sd"])
    window = int(float(row["window"]))

    rng = random.Random(seed)
    state = 0.0
    state_history: list[float] = []
    rows: list[dict[str, object]] = []

    stability_values = linear_space(stability_start, stability_end, steps)

    for time, stability in enumerate(stability_values, start=1):
        if time > 1:
            state = stability * state + rng.gauss(0.0, noise_sd)

        state_history.append(state)
        rolling_variance, rolling_ac1 = rolling_metrics(state_history, window)

        rows.append({
            "scenario": scenario,
            "time": time,
            "state": round(state, 6),
            "absolute_state": round(abs(state), 6),
            "stability": round(stability, 6),
            "noise_sd": noise_sd,
            "window": window,
            "rolling_variance": round(rolling_variance, 6) if rolling_variance != "" else "",
            "rolling_autocorrelation": round(rolling_ac1, 6) if rolling_ac1 != "" else "",
        })

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]

        variance_points = [
            (float(row["time"]), float(row["rolling_variance"]))
            for row in subset
            if row["rolling_variance"] != ""
        ]

        ac1_points = [
            (float(row["time"]), float(row["rolling_autocorrelation"]))
            for row in subset
            if row["rolling_autocorrelation"] != ""
        ]

        variance_slope = estimate_slope(
            [point[0] for point in variance_points],
            [point[1] for point in variance_points],
        )

        ac1_slope = estimate_slope(
            [point[0] for point in ac1_points],
            [point[1] for point in ac1_points],
        )

        final = subset[-1]

        final_variance = variance_points[-1][1] if variance_points else ""
        final_ac1 = ac1_points[-1][1] if ac1_points else ""

        if variance_slope > 0 and ac1_slope > 0:
            warning_label = "strengthening warning pattern"
        elif variance_slope > 0 or ac1_slope > 0:
            warning_label = "partial warning pattern"
        else:
            warning_label = "mixed or weak warning pattern"

        summary_rows.append({
            "scenario": scenario,
            "final_stability": final["stability"],
            "final_state": final["state"],
            "maximum_abs_state": round(max(float(row["absolute_state"]) for row in subset), 6),
            "final_rolling_variance": final_variance,
            "final_rolling_autocorrelation": final_ac1,
            "variance_slope": round(variance_slope, 8),
            "autocorrelation_slope": round(ac1_slope, 8),
            "warning_label": warning_label,
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_series(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("maximum_abs_state", 0.0, 1000000.0),
            ("final_stability", -1.0, 1.0),
            ("variance_slope", -1000000.0, 1000000.0),
            ("autocorrelation_slope", -1000000.0, 1000000.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": metric,
                "value": round(value, 8),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

        if row["final_rolling_variance"] != "":
            value = float(row["final_rolling_variance"])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": "final_rolling_variance",
                "value": round(value, 6),
                "target_low": 0.0,
                "target_high": 1000000.0,
                "passed": value >= 0.0,
            })

        if row["final_rolling_autocorrelation"] != "":
            value = float(row["final_rolling_autocorrelation"])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": "final_rolling_autocorrelation",
                "value": round(value, 6),
                "target_low": -1.0,
                "target_high": 1.0,
                "passed": -1.0 <= value <= 1.0,
            })

    write_csv(TABLES / "python_early_warning_indicators.csv", read_csv(DATA / "early_warning_indicators.csv"))
    write_csv(TABLES / "python_domain_warning_examples.csv", read_csv(DATA / "domain_warning_examples.csv"))
    write_csv(TABLES / "python_network_warning_examples.csv", read_csv(DATA / "network_warning_examples.csv"))
    write_csv(TABLES / "python_spatial_warning_examples.csv", read_csv(DATA / "spatial_warning_examples.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_early_warning_indicator_trajectories.csv", all_rows)
    write_csv(TABLES / "python_early_warning_indicator_summary.csv", summary_rows)
    write_csv(TABLES / "python_early_warning_validation_checks.csv", validation_rows)

    print("Early warning signals workflow complete.")
    print(TABLES / "python_early_warning_indicator_summary.csv")


if __name__ == "__main__":
    main()
