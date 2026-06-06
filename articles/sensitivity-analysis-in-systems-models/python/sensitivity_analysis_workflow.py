#!/usr/bin/env python3
"""
Sensitivity analysis workflow.

Dependency-light workflow demonstrating:

1. Nonlinear systems simulation
2. One-at-a-time local sensitivity
3. Monte Carlo sampling
4. Latin-hypercube-style stratified sampling
5. Rank-based sensitivity diagnostics
6. Local elasticity approximation
7. Validation checks

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

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def load_parameter_ranges() -> dict[str, dict[str, float]]:
    ranges: dict[str, dict[str, float]] = {}

    for row in read_csv(DATA / "parameter_ranges.csv"):
        ranges[row["parameter"]] = {
            "minimum": float(row["minimum"]),
            "baseline": float(row["baseline"]),
            "maximum": float(row["maximum"]),
        }

    return ranges


def simulate_system(
    growth_rate: float,
    carrying_capacity: float,
    extraction_pressure: float,
    recovery_delay: int,
    feedback_strength: float,
    shock_intensity: float,
    initial_state: float = 10.0,
    steps: int = 80,
) -> dict[str, float]:
    state_values = [initial_state]

    shock_time = steps // 2

    for time in range(1, steps):
        delayed_index = max(0, time - recovery_delay)
        delayed_recovery = feedback_strength * state_values[delayed_index]

        previous = state_values[-1]
        shock_effect = shock_intensity if time == shock_time else 0.0

        next_state = (
            previous
            + growth_rate * previous * (1 - previous / carrying_capacity)
            - extraction_pressure * previous
            + delayed_recovery
            - shock_effect
        )

        state_values.append(max(0.0, next_state))

    return {
        "final_state": state_values[-1],
        "maximum_state": max(state_values),
        "minimum_state": min(state_values),
        "mean_state": mean(state_values),
    }


def baseline_settings(ranges: dict[str, dict[str, float]]) -> dict[str, float | int]:
    settings: dict[str, float | int] = {
        parameter: values["baseline"]
        for parameter, values in ranges.items()
    }
    settings["recovery_delay"] = int(settings["recovery_delay"])
    return settings


def rank(values: list[float]) -> list[float]:
    sorted_pairs = sorted((value, index) for index, value in enumerate(values))
    ranks = [0.0] * len(values)

    for rank_position, (_value, index) in enumerate(sorted_pairs, start=1):
        ranks[index] = float(rank_position)

    return ranks


def pearson(x_values: list[float], y_values: list[float]) -> float:
    x_mean = mean(x_values)
    y_mean = mean(y_values)

    numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_values, y_values))
    x_denom = math.sqrt(sum((x - x_mean) ** 2 for x in x_values))
    y_denom = math.sqrt(sum((y - y_mean) ** 2 for y in y_values))

    if x_denom == 0 or y_denom == 0:
        return 0.0

    return numerator / (x_denom * y_denom)


def spearman(x_values: list[float], y_values: list[float]) -> float:
    return pearson(rank(x_values), rank(y_values))


def local_sensitivity(ranges: dict[str, dict[str, float]]) -> list[dict[str, object]]:
    base = baseline_settings(ranges)
    rows: list[dict[str, object]] = []

    for parameter, values in ranges.items():
        count = 12 if parameter == "recovery_delay" else 41

        if parameter == "recovery_delay":
            sampled_values = list(range(int(values["minimum"]), int(values["maximum"]) + 1))
        else:
            sampled_values = [
                values["minimum"] + i * ((values["maximum"] - values["minimum"]) / (count - 1))
                for i in range(count)
            ]

        for value in sampled_values:
            settings = dict(base)
            settings[parameter] = int(value) if parameter == "recovery_delay" else value
            result = simulate_system(**settings)  # type: ignore[arg-type]

            rows.append({
                "analysis_type": "local_one_at_a_time",
                "parameter": parameter,
                "value": round(float(value), 6),
                "final_state": round(result["final_state"], 6),
                "maximum_state": round(result["maximum_state"], 6),
                "minimum_state": round(result["minimum_state"], 6),
                "mean_state": round(result["mean_state"], 6),
            })

    return rows


def local_elasticity(ranges: dict[str, dict[str, float]]) -> list[dict[str, object]]:
    base = baseline_settings(ranges)
    base_output = simulate_system(**base)["final_state"]  # type: ignore[arg-type]
    rows: list[dict[str, object]] = []

    for parameter, values in ranges.items():
        baseline = values["baseline"]
        if baseline == 0:
            perturbation = 0.01 * max(1.0, values["maximum"] - values["minimum"])
        else:
            perturbation = 0.05 * abs(baseline)

        high_value = min(values["maximum"], baseline + perturbation)
        low_value = max(values["minimum"], baseline - perturbation)

        high_settings = dict(base)
        low_settings = dict(base)

        if parameter == "recovery_delay":
            high_settings[parameter] = int(round(high_value))
            low_settings[parameter] = int(round(low_value))
        else:
            high_settings[parameter] = high_value
            low_settings[parameter] = low_value

        high_output = simulate_system(**high_settings)["final_state"]  # type: ignore[arg-type]
        low_output = simulate_system(**low_settings)["final_state"]  # type: ignore[arg-type]

        denominator = float(high_settings[parameter]) - float(low_settings[parameter])
        finite_difference = 0.0 if denominator == 0 else (high_output - low_output) / denominator

        elasticity = 0.0
        if base_output != 0:
            elasticity = finite_difference * baseline / base_output

        rows.append({
            "parameter": parameter,
            "baseline_value": round(baseline, 6),
            "low_value": round(float(low_settings[parameter]), 6),
            "high_value": round(float(high_settings[parameter]), 6),
            "baseline_final_state": round(base_output, 6),
            "finite_difference": round(finite_difference, 6),
            "elasticity": round(elasticity, 6),
        })

    return rows


def monte_carlo_sample(ranges: dict[str, dict[str, float]], n_runs: int, seed: int) -> list[dict[str, object]]:
    rng = random.Random(seed)
    rows: list[dict[str, object]] = []

    for run_id in range(1, n_runs + 1):
        row: dict[str, object] = {
            "sample_type": "monte_carlo",
            "run_id": run_id,
        }

        for parameter, values in ranges.items():
            if parameter == "recovery_delay":
                row[parameter] = rng.randint(int(values["minimum"]), int(values["maximum"]))
            else:
                row[parameter] = rng.uniform(values["minimum"], values["maximum"])

        rows.append(row)

    return rows


def latin_hypercube_style_sample(ranges: dict[str, dict[str, float]], n_runs: int, seed: int) -> list[dict[str, object]]:
    rng = random.Random(seed)
    sampled_columns: dict[str, list[float | int]] = {}

    for parameter, values in ranges.items():
        strata = [(i + rng.random()) / n_runs for i in range(n_runs)]

        if parameter == "recovery_delay":
            sampled_values = [
                max(
                    int(values["minimum"]),
                    min(int(values["maximum"]), int(round(values["minimum"] + value * (values["maximum"] - values["minimum"]))))
                )
                for value in strata
            ]
        else:
            sampled_values = [
                values["minimum"] + value * (values["maximum"] - values["minimum"])
                for value in strata
            ]

        rng.shuffle(sampled_values)
        sampled_columns[parameter] = sampled_values

    rows: list[dict[str, object]] = []

    for index in range(n_runs):
        row: dict[str, object] = {
            "sample_type": "latin_hypercube_style",
            "run_id": index + 1,
        }

        for parameter in ranges:
            row[parameter] = sampled_columns[parameter][index]

        rows.append(row)

    return rows


def evaluate_samples(samples: list[dict[str, object]]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    for row in samples:
        result = simulate_system(
            growth_rate=float(row["growth_rate"]),
            carrying_capacity=float(row["carrying_capacity"]),
            extraction_pressure=float(row["extraction_pressure"]),
            recovery_delay=int(row["recovery_delay"]),
            feedback_strength=float(row["feedback_strength"]),
            shock_intensity=float(row["shock_intensity"]),
        )

        rows.append({
            "sample_type": row["sample_type"],
            "run_id": row["run_id"],
            "growth_rate": round(float(row["growth_rate"]), 6),
            "carrying_capacity": round(float(row["carrying_capacity"]), 6),
            "extraction_pressure": round(float(row["extraction_pressure"]), 6),
            "recovery_delay": int(row["recovery_delay"]),
            "feedback_strength": round(float(row["feedback_strength"]), 6),
            "shock_intensity": round(float(row["shock_intensity"]), 6),
            "final_state": round(result["final_state"], 6),
            "maximum_state": round(result["maximum_state"], 6),
            "minimum_state": round(result["minimum_state"], 6),
            "mean_state": round(result["mean_state"], 6),
        })

    return rows


def sensitivity_ranking(rows: list[dict[str, object]], parameters: list[str]) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []

    for sample_type in sorted(set(str(row["sample_type"]) for row in rows)):
        subset = [row for row in rows if row["sample_type"] == sample_type]
        final_states = [float(row["final_state"]) for row in subset]

        preliminary: list[dict[str, object]] = []

        for parameter in parameters:
            values = [float(row[parameter]) for row in subset]
            coefficient = spearman(values, final_states)

            preliminary.append({
                "sample_type": sample_type,
                "parameter": parameter,
                "spearman_correlation": round(coefficient, 6),
                "absolute_correlation": round(abs(coefficient), 6),
                "direction": "positive" if coefficient >= 0 else "negative",
            })

        preliminary = sorted(preliminary, key=lambda item: -float(item["absolute_correlation"]))

        for index, item in enumerate(preliminary, start=1):
            item["sensitivity_rank"] = index
            results.append(item)

    return results


def validate(global_rows: list[dict[str, object]], ranking_rows: list[dict[str, object]], elasticity_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    validation_rows: list[dict[str, object]] = []

    metric_checks = {
        "final_state": (0.0, 10000.0),
        "maximum_state": (0.0, 10000.0),
        "minimum_state": (0.0, 10000.0),
        "mean_state": (0.0, 10000.0),
    }

    for sample_type in sorted(set(str(row["sample_type"]) for row in global_rows)):
        subset = [row for row in global_rows if row["sample_type"] == sample_type]

        for metric, (low, high) in metric_checks.items():
            values = [float(row[metric]) for row in subset]
            validation_rows.append({
                "scope": sample_type,
                "metric": metric,
                "minimum_value": round(min(values), 6),
                "maximum_value": round(max(values), 6),
                "target_low": low,
                "target_high": high,
                "passed": min(values) >= low and max(values) <= high,
            })

    for row in ranking_rows:
        value = float(row["absolute_correlation"])
        validation_rows.append({
            "scope": str(row["sample_type"]),
            "metric": f"absolute_correlation_{row['parameter']}",
            "minimum_value": round(value, 6),
            "maximum_value": round(value, 6),
            "target_low": 0.0,
            "target_high": 1.0,
            "passed": 0.0 <= value <= 1.0,
        })

    for row in elasticity_rows:
        value = float(row["elasticity"])
        validation_rows.append({
            "scope": "local_elasticity",
            "metric": f"elasticity_{row['parameter']}",
            "minimum_value": round(value, 6),
            "maximum_value": round(value, 6),
            "target_low": -1000.0,
            "target_high": 1000.0,
            "passed": -1000.0 <= value <= 1000.0,
        })

    return validation_rows


def main() -> None:
    ranges = load_parameter_ranges()
    parameters = list(ranges.keys())

    local_rows = local_sensitivity(ranges)
    elasticity_rows = local_elasticity(ranges)

    samples: list[dict[str, object]] = []
    samples.extend(monte_carlo_sample(ranges, n_runs=600, seed=42))
    samples.extend(latin_hypercube_style_sample(ranges, n_runs=300, seed=43))

    global_rows = evaluate_samples(samples)
    ranking_rows = sensitivity_ranking(global_rows, parameters)
    validation_rows = validate(global_rows, ranking_rows, elasticity_rows)

    write_csv(TABLES / "python_parameter_ranges.csv", read_csv(DATA / "parameter_ranges.csv"))
    write_csv(TABLES / "python_structural_variants.csv", read_csv(DATA / "structural_variants.csv"))
    write_csv(TABLES / "python_local_sensitivity.csv", local_rows)
    write_csv(TABLES / "python_local_elasticity.csv", elasticity_rows)
    write_csv(TABLES / "python_global_sensitivity_runs.csv", global_rows)
    write_csv(TABLES / "python_sensitivity_rank_summary.csv", ranking_rows)
    write_csv(TABLES / "python_sensitivity_validation.csv", validation_rows)

    print("Sensitivity analysis workflow complete.")
    print(TABLES / "python_sensitivity_rank_summary.csv")


if __name__ == "__main__":
    main()
