#!/usr/bin/env python3
"""
Calibration and validation workflow.

Dependency-light workflow demonstrating:

1. Synthetic observed data generation
2. Parameter calibration by grid search
3. Out-of-sample validation
4. Error diagnostics
5. Benchmark comparison
6. Generalization-gap reporting
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


def load_settings() -> dict[str, float]:
    return {row["setting"]: float(row["value"]) for row in read_csv(DATA / "calibration_settings.csv")}


def simulate_model(
    growth_rate: float,
    carrying_capacity: float,
    n_steps: int,
    initial_state: float,
) -> list[float]:
    values = [initial_state]

    for _ in range(1, n_steps):
        previous = values[-1]
        next_value = previous + growth_rate * previous * (1.0 - previous / carrying_capacity)
        values.append(max(0.0, next_value))

    return values


def generate_synthetic_observations(settings: dict[str, float], seed: int = 42) -> list[dict[str, float]]:
    rng = random.Random(seed)
    n_steps = int(settings["n_steps"])

    true_values = simulate_model(
        growth_rate=settings["true_growth_rate"],
        carrying_capacity=settings["true_carrying_capacity"],
        n_steps=n_steps,
        initial_state=settings["initial_state"],
    )

    rows: list[dict[str, float]] = []

    for time, true_value in enumerate(true_values, start=1):
        observed = max(0.0, true_value + rng.gauss(0.0, settings["noise_sd"]))
        rows.append({
            "time": float(time),
            "true_synthetic_state": round(true_value, 6),
            "observed": round(observed, 6),
        })

    return rows


def rmse(actual: list[float], predicted: list[float]) -> float:
    return math.sqrt(mean((a - p) ** 2 for a, p in zip(actual, predicted)))


def mae(actual: list[float], predicted: list[float]) -> float:
    return mean(abs(a - p) for a, p in zip(actual, predicted))


def bias(actual: list[float], predicted: list[float]) -> float:
    return mean(a - p for a, p in zip(actual, predicted))


def calibration_error(
    observed: list[float],
    growth_rate: float,
    carrying_capacity: float,
) -> float:
    predicted = simulate_model(
        growth_rate=growth_rate,
        carrying_capacity=carrying_capacity,
        n_steps=len(observed),
        initial_state=observed[0],
    )

    return sum((actual - pred) ** 2 for actual, pred in zip(observed, predicted))


def calibrate_grid_search(train_observed: list[float], settings: dict[str, float]) -> tuple[dict[str, float], list[dict[str, object]]]:
    best = {
        "growth_rate": 0.0,
        "carrying_capacity": 0.0,
        "sum_squared_error": float("inf"),
    }

    candidate_rows: list[dict[str, object]] = []

    growth_min = settings["grid_growth_min"]
    growth_max = settings["grid_growth_max"]
    capacity_min = settings["grid_capacity_min"]
    capacity_max = settings["grid_capacity_max"]

    growth_values = [growth_min + i * ((growth_max - growth_min) / 64) for i in range(65)]
    capacity_values = [capacity_min + i * ((capacity_max - capacity_min) / 44) for i in range(45)]

    candidate_id = 0

    for growth_rate in growth_values:
        for carrying_capacity in capacity_values:
            candidate_id += 1

            error = calibration_error(
                observed=train_observed,
                growth_rate=growth_rate,
                carrying_capacity=carrying_capacity,
            )

            candidate_rows.append({
                "candidate_id": candidate_id,
                "growth_rate": round(growth_rate, 6),
                "carrying_capacity": round(carrying_capacity, 6),
                "sum_squared_error": round(error, 6),
            })

            if error < best["sum_squared_error"]:
                best = {
                    "growth_rate": growth_rate,
                    "carrying_capacity": carrying_capacity,
                    "sum_squared_error": error,
                }

    return best, candidate_rows


def persistence_benchmark(train_observed: list[float], valid_count: int) -> list[float]:
    return [train_observed[-1]] * valid_count


def linear_trend_benchmark(train_rows: list[dict[str, float]], valid_rows: list[dict[str, float]]) -> list[float]:
    first_time = float(train_rows[0]["time"])
    last_time = float(train_rows[-1]["time"])
    first_value = float(train_rows[0]["observed"])
    last_value = float(train_rows[-1]["observed"])

    slope = 0.0 if last_time == first_time else (last_value - first_value) / (last_time - first_time)

    return [
        max(0.0, last_value + slope * (float(row["time"]) - last_time))
        for row in valid_rows
    ]


def build_model_results(
    train_rows: list[dict[str, float]],
    valid_rows: list[dict[str, float]],
    train_predicted: list[float],
    valid_predicted: list[float],
) -> list[dict[str, object]]:
    result_rows: list[dict[str, object]] = []

    for row, predicted in zip(train_rows, train_predicted):
        observed = float(row["observed"])
        result_rows.append({
            "time": int(row["time"]),
            "dataset": "calibration",
            "observed": round(observed, 6),
            "predicted": round(predicted, 6),
            "residual": round(observed - predicted, 6),
        })

    for row, predicted in zip(valid_rows, valid_predicted):
        observed = float(row["observed"])
        result_rows.append({
            "time": int(row["time"]),
            "dataset": "validation",
            "observed": round(observed, 6),
            "predicted": round(predicted, 6),
            "residual": round(observed - predicted, 6),
        })

    return result_rows


def validation_metrics(
    train_observed: list[float],
    train_predicted: list[float],
    valid_observed: list[float],
    valid_predicted: list[float],
) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    for dataset_name, actual, predicted in [
        ("calibration", train_observed, train_predicted),
        ("validation", valid_observed, valid_predicted),
    ]:
        rows.append({
            "dataset": dataset_name,
            "rmse": round(rmse(actual, predicted), 6),
            "mae": round(mae(actual, predicted), 6),
            "bias": round(bias(actual, predicted), 6),
            "observation_count": len(actual),
        })

    return rows


def benchmark_metrics(
    valid_observed: list[float],
    calibrated_predicted: list[float],
    persistence_predicted: list[float],
    linear_predicted: list[float],
) -> list[dict[str, object]]:
    benchmarks = [
        ("calibrated_logistic", calibrated_predicted),
        ("persistence", persistence_predicted),
        ("linear_trend", linear_predicted),
    ]

    rows: list[dict[str, object]] = []

    for benchmark_name, predicted in benchmarks:
        rows.append({
            "benchmark": benchmark_name,
            "validation_rmse": round(rmse(valid_observed, predicted), 6),
            "validation_mae": round(mae(valid_observed, predicted), 6),
            "validation_bias": round(bias(valid_observed, predicted), 6),
        })

    return sorted(rows, key=lambda row: float(row["validation_rmse"]))


def validation_checks(
    metrics_rows: list[dict[str, object]],
    fitted: dict[str, float],
    settings: dict[str, float],
    benchmark_rows: list[dict[str, object]],
) -> list[dict[str, object]]:
    calibration_rmse = float(next(row["rmse"] for row in metrics_rows if row["dataset"] == "calibration"))
    validation_rmse = float(next(row["rmse"] for row in metrics_rows if row["dataset"] == "validation"))
    best_benchmark = benchmark_rows[0]["benchmark"]

    return [
        {
            "check": "calibration_rmse_nonnegative",
            "value": calibration_rmse,
            "passed": calibration_rmse >= 0,
        },
        {
            "check": "validation_rmse_nonnegative",
            "value": validation_rmse,
            "passed": validation_rmse >= 0,
        },
        {
            "check": "generalization_gap_reported",
            "value": round(validation_rmse - calibration_rmse, 6),
            "passed": True,
        },
        {
            "check": "growth_rate_within_bounds",
            "value": round(fitted["growth_rate"], 6),
            "passed": settings["grid_growth_min"] <= fitted["growth_rate"] <= settings["grid_growth_max"],
        },
        {
            "check": "carrying_capacity_within_bounds",
            "value": round(fitted["carrying_capacity"], 6),
            "passed": settings["grid_capacity_min"] <= fitted["carrying_capacity"] <= settings["grid_capacity_max"],
        },
        {
            "check": "benchmark_comparison_completed",
            "value": str(best_benchmark),
            "passed": True,
        },
    ]


def main() -> None:
    settings = load_settings()
    observations = generate_synthetic_observations(settings)

    train_cutoff = int(settings["train_cutoff"])
    train_rows = [row for row in observations if int(row["time"]) <= train_cutoff]
    valid_rows = [row for row in observations if int(row["time"]) > train_cutoff]

    train_observed = [float(row["observed"]) for row in train_rows]
    valid_observed = [float(row["observed"]) for row in valid_rows]

    fitted, candidate_rows = calibrate_grid_search(train_observed, settings)

    train_predicted = simulate_model(
        growth_rate=fitted["growth_rate"],
        carrying_capacity=fitted["carrying_capacity"],
        n_steps=len(train_observed),
        initial_state=train_observed[0],
    )

    validation_start = train_observed[-1]

    valid_predicted = simulate_model(
        growth_rate=fitted["growth_rate"],
        carrying_capacity=fitted["carrying_capacity"],
        n_steps=len(valid_observed) + 1,
        initial_state=validation_start,
    )[1:]

    result_rows = build_model_results(train_rows, valid_rows, train_predicted, valid_predicted)
    metrics_rows = validation_metrics(train_observed, train_predicted, valid_observed, valid_predicted)

    persistence_predicted = persistence_benchmark(train_observed, len(valid_observed))
    linear_predicted = linear_trend_benchmark(train_rows, valid_rows)
    benchmark_rows = benchmark_metrics(valid_observed, valid_predicted, persistence_predicted, linear_predicted)

    parameter_rows = [
        {
            "parameter": "growth_rate",
            "estimated_value": round(fitted["growth_rate"], 6),
            "true_synthetic_value": settings["true_growth_rate"],
            "lower_bound": settings["grid_growth_min"],
            "upper_bound": settings["grid_growth_max"],
            "calibration_method": "grid_search",
        },
        {
            "parameter": "carrying_capacity",
            "estimated_value": round(fitted["carrying_capacity"], 6),
            "true_synthetic_value": settings["true_carrying_capacity"],
            "lower_bound": settings["grid_capacity_min"],
            "upper_bound": settings["grid_capacity_max"],
            "calibration_method": "grid_search",
        },
    ]

    validation_check_rows = validation_checks(metrics_rows, fitted, settings, benchmark_rows)

    # Keep the candidate surface useful but compact.
    top_candidate_rows = sorted(candidate_rows, key=lambda row: float(row["sum_squared_error"]))[:200]

    write_csv(TABLES / "python_calibration_settings.csv", read_csv(DATA / "calibration_settings.csv"))
    write_csv(TABLES / "python_structural_validation_checks.csv", read_csv(DATA / "structural_validation_checks.csv"))
    write_csv(TABLES / "python_observed_synthetic_data.csv", observations)
    write_csv(TABLES / "python_calibration_candidate_surface_top200.csv", top_candidate_rows)
    write_csv(TABLES / "python_calibration_validation_results.csv", result_rows)
    write_csv(TABLES / "python_calibration_validation_metrics.csv", metrics_rows)
    write_csv(TABLES / "python_parameter_estimates.csv", parameter_rows)
    write_csv(TABLES / "python_benchmark_validation_metrics.csv", benchmark_rows)
    write_csv(TABLES / "python_validation_checks.csv", validation_check_rows)

    print("Calibration and validation workflow complete.")
    print(TABLES / "python_calibration_validation_metrics.csv")


if __name__ == "__main__":
    main()
