#!/usr/bin/env python3
"""
Model comparison and ensemble reasoning workflow.

Dependency-light workflow demonstrating:

1. Synthetic observed data generation
2. Structural model comparison
3. Validation metrics
4. Equal-weight ensemble prediction
5. Performance-weighted ensemble prediction
6. Model-dependence notes
7. Policy robustness and regret across model uncertainty

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


def simulate_exponential(growth: float, steps: int, initial: float) -> list[float]:
    values = [initial]
    for _ in range(1, steps):
        values.append(max(0.0, values[-1] + growth * values[-1]))
    return values


def simulate_logistic(growth: float, capacity: float, steps: int, initial: float) -> list[float]:
    values = [initial]
    for _ in range(1, steps):
        previous = values[-1]
        values.append(max(0.0, previous + growth * previous * (1.0 - previous / capacity)))
    return values


def simulate_managed(growth: float, capacity: float, extraction: float, steps: int, initial: float) -> list[float]:
    values = [initial]
    for _ in range(1, steps):
        previous = values[-1]
        values.append(
            max(
                0.0,
                previous
                + growth * previous * (1.0 - previous / capacity)
                - extraction * previous,
            )
        )
    return values


def generate_observations(seed: int = 42, steps: int = 90) -> list[dict[str, object]]:
    rng = random.Random(seed)
    true_values = simulate_managed(
        growth=0.085,
        capacity=130.0,
        extraction=0.012,
        steps=steps,
        initial=12.0,
    )

    rows: list[dict[str, object]] = []
    for time, true_value in enumerate(true_values, start=1):
        observed = max(0.0, true_value + rng.gauss(0.0, 1.1))
        rows.append({
            "time": time,
            "true_synthetic_state": round(true_value, 6),
            "observed": round(observed, 6),
            "dataset": "calibration" if time <= 60 else "validation",
        })
    return rows


def rmse(actual: list[float], predicted: list[float]) -> float:
    return math.sqrt(mean((a - p) ** 2 for a, p in zip(actual, predicted)))


def mae(actual: list[float], predicted: list[float]) -> float:
    return mean(abs(a - p) for a, p in zip(actual, predicted))


def calibrate_models(train_observed: list[float]) -> list[dict[str, object]]:
    candidates: list[dict[str, object]] = []

    best_exponential: dict[str, object] = {
        "model": "exponential",
        "growth": 0.0,
        "capacity": None,
        "extraction": None,
        "sse": float("inf"),
    }

    for i in range(80):
        growth = 0.005 + i * (0.080 - 0.005) / 79
        prediction = simulate_exponential(growth, len(train_observed), train_observed[0])
        sse = sum((a - p) ** 2 for a, p in zip(train_observed, prediction))
        if sse < float(best_exponential["sse"]):
            best_exponential = {
                "model": "exponential",
                "growth": growth,
                "capacity": None,
                "extraction": None,
                "sse": sse,
            }

    candidates.append(best_exponential)

    best_logistic: dict[str, object] = {
        "model": "logistic",
        "growth": 0.0,
        "capacity": 0.0,
        "extraction": None,
        "sse": float("inf"),
    }

    for gi in range(60):
        growth = 0.025 + gi * (0.140 - 0.025) / 59
        for ci in range(60):
            capacity = 80.0 + ci * (180.0 - 80.0) / 59
            prediction = simulate_logistic(growth, capacity, len(train_observed), train_observed[0])
            sse = sum((a - p) ** 2 for a, p in zip(train_observed, prediction))
            if sse < float(best_logistic["sse"]):
                best_logistic = {
                    "model": "logistic",
                    "growth": growth,
                    "capacity": capacity,
                    "extraction": None,
                    "sse": sse,
                }

    candidates.append(best_logistic)

    best_managed: dict[str, object] = {
        "model": "managed_logistic",
        "growth": 0.0,
        "capacity": 0.0,
        "extraction": 0.0,
        "sse": float("inf"),
    }

    for gi in range(45):
        growth = 0.025 + gi * (0.150 - 0.025) / 44
        for ci in range(45):
            capacity = 80.0 + ci * (190.0 - 80.0) / 44
            for ei in range(20):
                extraction = ei * 0.035 / 19
                prediction = simulate_managed(growth, capacity, extraction, len(train_observed), train_observed[0])
                sse = sum((a - p) ** 2 for a, p in zip(train_observed, prediction))
                if sse < float(best_managed["sse"]):
                    best_managed = {
                        "model": "managed_logistic",
                        "growth": growth,
                        "capacity": capacity,
                        "extraction": extraction,
                        "sse": sse,
                    }

    candidates.append(best_managed)
    return candidates


def predict_model(model: dict[str, object], steps: int, initial: float) -> list[float]:
    model_name = str(model["model"])
    growth = float(model["growth"])

    if model_name == "exponential":
        return simulate_exponential(growth, steps, initial)

    if model_name == "logistic":
        return simulate_logistic(growth, float(model["capacity"]), steps, initial)

    return simulate_managed(
        growth,
        float(model["capacity"]),
        float(model["extraction"]),
        steps,
        initial,
    )


def evaluate_predictions(
    observed_rows: list[dict[str, object]],
    predictions_by_model: dict[str, list[float]],
) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    prediction_rows: list[dict[str, object]] = []
    metric_rows: list[dict[str, object]] = []

    for model_name, predictions in predictions_by_model.items():
        for row, predicted in zip(observed_rows, predictions):
            observed = float(row["observed"])
            prediction_rows.append({
                "time": int(row["time"]),
                "dataset": row["dataset"],
                "model": model_name,
                "observed": round(observed, 6),
                "predicted": round(predicted, 6),
                "residual": round(observed - predicted, 6),
            })

        for dataset_name in ["calibration", "validation"]:
            subset = [
                (float(row["observed"]), pred)
                for row, pred in zip(observed_rows, predictions)
                if row["dataset"] == dataset_name
            ]

            actual = [item[0] for item in subset]
            predicted_values = [item[1] for item in subset]

            metric_rows.append({
                "model": model_name,
                "dataset": dataset_name,
                "rmse": round(rmse(actual, predicted_values), 6),
                "mae": round(mae(actual, predicted_values), 6),
                "bias": round(mean(a - p for a, p in zip(actual, predicted_values)), 6),
                "observation_count": len(actual),
            })

    return prediction_rows, metric_rows


def performance_weights(metric_rows: list[dict[str, object]]) -> dict[str, float]:
    validation_rows = [
        row
        for row in metric_rows
        if row["dataset"] == "validation" and not str(row["model"]).endswith("ensemble")
    ]

    inverse_errors = {
        str(row["model"]): 1.0 / max(float(row["rmse"]), 1e-9)
        for row in validation_rows
    }

    total = sum(inverse_errors.values())
    return {model: value / total for model, value in inverse_errors.items()}


def ensemble_prediction(predictions_by_model: dict[str, list[float]], weights: dict[str, float]) -> list[float]:
    model_names = list(weights.keys())
    steps = len(predictions_by_model[model_names[0]])
    result = []

    for index in range(steps):
        result.append(sum(weights[model] * predictions_by_model[model][index] for model in model_names))

    return result


def load_policies() -> list[dict[str, object]]:
    policies: list[dict[str, object]] = []
    for row in read_csv(DATA / "policy_options.csv"):
        policies.append({
            "policy": row["policy"],
            "policy_strength": float(row["policy_strength"]),
            "adaptation": float(row["adaptation"]),
            "description": row["description"],
        })
    return policies


def policy_score(policy_strength: float, adaptation: float, model_family: str, scenario_pressure: float) -> float:
    family_modifier = {
        "exponential": 1.10,
        "logistic": 0.95,
        "managed_logistic": 0.85,
    }[model_family]

    residual_risk = 100.0 * scenario_pressure * family_modifier
    intervention_benefit = 90.0 * policy_strength + 70.0 * adaptation
    implementation_burden = 25.0 * policy_strength ** 2 + 18.0 * adaptation ** 2

    return max(0.0, min(100.0, 100.0 - residual_risk + intervention_benefit - implementation_burden))


def policy_robustness(models: list[dict[str, object]], seed: int = 7) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    rng = random.Random(seed)
    policies = load_policies()

    run_rows: list[dict[str, object]] = []

    for scenario_id in range(1, 401):
        pressure = rng.uniform(0.25, 1.05)

        for model in models:
            model_family = str(model["model"])
            scenario_results: list[dict[str, object]] = []

            for policy in policies:
                score = policy_score(
                    policy_strength=float(policy["policy_strength"]),
                    adaptation=float(policy["adaptation"]),
                    model_family=model_family,
                    scenario_pressure=pressure,
                )

                scenario_results.append({
                    "scenario_id": scenario_id,
                    "model": model_family,
                    "policy": policy["policy"],
                    "scenario_pressure": round(pressure, 6),
                    "performance_score": round(score, 6),
                })

            best_score = max(float(row["performance_score"]) for row in scenario_results)

            for row in scenario_results:
                row["regret"] = round(best_score - float(row["performance_score"]), 6)
                run_rows.append(row)

    summary_rows: list[dict[str, object]] = []

    for policy in sorted(set(str(row["policy"]) for row in run_rows)):
        subset = [row for row in run_rows if row["policy"] == policy]
        scores = [float(row["performance_score"]) for row in subset]
        regrets = [float(row["regret"]) for row in subset]

        summary_rows.append({
            "policy": policy,
            "mean_score": round(mean(scores), 6),
            "worst_score": round(min(scores), 6),
            "mean_regret": round(mean(regrets), 6),
            "maximum_regret": round(max(regrets), 6),
            "robustness_interpretation": (
                "robust across model families"
                if min(scores) >= 40 and mean(regrets) <= 10
                else "sensitive to model family and scenario pressure"
            ),
        })

    return run_rows, summary_rows


def validation_checks(
    metric_rows: list[dict[str, object]],
    weight_rows: list[dict[str, object]],
    policy_summary_rows: list[dict[str, object]],
) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    for row in metric_rows:
        for metric, low, high in [
            ("rmse", 0.0, 10000.0),
            ("mae", 0.0, 10000.0),
            ("bias", -10000.0, 10000.0),
        ]:
            value = float(row[metric])
            rows.append({
                "scope": f"{row['model']}:{row['dataset']}",
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    weight_total = sum(float(row["weight"]) for row in weight_rows)
    rows.append({
        "scope": "performance_weighted_ensemble",
        "metric": "weight_sum",
        "value": round(weight_total, 6),
        "target_low": 0.999,
        "target_high": 1.001,
        "passed": 0.999 <= weight_total <= 1.001,
    })

    for row in policy_summary_rows:
        for metric, low, high in [
            ("mean_score", 0.0, 100.0),
            ("worst_score", 0.0, 100.0),
            ("mean_regret", 0.0, 100.0),
            ("maximum_regret", 0.0, 100.0),
        ]:
            value = float(row[metric])
            rows.append({
                "scope": row["policy"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    return rows


def main() -> None:
    observations = generate_observations()
    train_observed = [float(row["observed"]) for row in observations if row["dataset"] == "calibration"]

    models = calibrate_models(train_observed)

    base_predictions = {
        str(model["model"]): predict_model(model, len(observations), float(observations[0]["observed"]))
        for model in models
    }

    predictions_by_model = dict(base_predictions)
    equal_weights = {str(model["model"]): 1.0 / len(models) for model in models}
    predictions_by_model["equal_weight_ensemble"] = ensemble_prediction(base_predictions, equal_weights)

    _prediction_rows, interim_metric_rows = evaluate_predictions(observations, predictions_by_model)
    weights = performance_weights(interim_metric_rows)
    predictions_by_model["performance_weighted_ensemble"] = ensemble_prediction(base_predictions, weights)

    prediction_rows, metric_rows = evaluate_predictions(observations, predictions_by_model)

    weight_rows = [
        {"model": model, "weight_type": "validation_inverse_rmse", "weight": round(weight, 6)}
        for model, weight in sorted(weights.items())
    ]

    validation_rank_rows = sorted(
        [dict(row) for row in metric_rows if row["dataset"] == "validation"],
        key=lambda row: float(row["rmse"]),
    )

    for index, row in enumerate(validation_rank_rows, start=1):
        row["validation_rank"] = index

    policy_rows, policy_summary_rows = policy_robustness(models)

    model_metadata_rows = [
        {
            "model": model["model"],
            "model_family": model["model"],
            "growth": round(float(model["growth"]), 6),
            "capacity": "" if model["capacity"] is None else round(float(model["capacity"]), 6),
            "extraction": "" if model["extraction"] is None else round(float(model["extraction"]), 6),
            "calibration_sse": round(float(model["sse"]), 6),
            "dependence_note": "synthetic comparison; models share data and calibration target",
        }
        for model in models
    ]

    check_rows = validation_checks(metric_rows, weight_rows, policy_summary_rows)

    write_csv(TABLES / "python_model_families.csv", read_csv(DATA / "model_families.csv"))
    write_csv(TABLES / "python_comparison_criteria.csv", read_csv(DATA / "comparison_criteria.csv"))
    write_csv(TABLES / "python_observed_model_comparison_data.csv", observations)
    write_csv(TABLES / "python_model_metadata.csv", model_metadata_rows)
    write_csv(TABLES / "python_model_predictions.csv", prediction_rows)
    write_csv(TABLES / "python_model_comparison_metrics.csv", metric_rows)
    write_csv(TABLES / "python_validation_model_ranking.csv", validation_rank_rows)
    write_csv(TABLES / "python_model_weights.csv", weight_rows)
    write_csv(TABLES / "python_policy_model_ensemble_runs.csv", policy_rows)
    write_csv(TABLES / "python_policy_robustness_summary.csv", policy_summary_rows)
    write_csv(TABLES / "python_model_comparison_validation_checks.csv", check_rows)

    print("Model comparison and ensemble reasoning workflow complete.")
    print(TABLES / "python_validation_model_ranking.csv")


if __name__ == "__main__":
    main()
