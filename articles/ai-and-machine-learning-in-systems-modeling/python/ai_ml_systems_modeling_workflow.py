#!/usr/bin/env python3
"""
AI and machine learning in systems modeling workflow.

Dependency-light workflow demonstrating:

1. Synthetic nonlinear systems data
2. Structural baseline prediction
3. Residual learning with engineered features
4. Hybrid prediction
5. Baseline vs hybrid error comparison
6. Scenario diagnostics and validation checks
7. AI role, architecture, governance, data-risk, and constraint taxonomies

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


def dot(a: list[float], b: list[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


def features(input_a: float, input_b: float, input_c: float, index_share: float) -> list[float]:
    return [
        1.0,
        input_a,
        input_b,
        input_c,
        input_b ** 2,
        input_a * input_b,
        math.sin(input_a),
        index_share,
    ]


def standardize_matrix(x_rows: list[list[float]]) -> tuple[list[list[float]], list[float], list[float]]:
    columns = list(zip(*x_rows))
    means = [mean(col) for col in columns]
    scales = []
    for col, mu in zip(columns, means):
        variance = mean((value - mu) ** 2 for value in col)
        scales.append(math.sqrt(variance) if variance > 1e-12 else 1.0)

    standardized = [
        [(value - means[j]) / scales[j] for j, value in enumerate(row)]
        for row in x_rows
    ]
    return standardized, means, scales


def apply_standardization(x_rows: list[list[float]], means: list[float], scales: list[float]) -> list[list[float]]:
    return [
        [(value - means[j]) / scales[j] for j, value in enumerate(row)]
        for row in x_rows
    ]


def fit_linear_model(
    x_rows: list[list[float]],
    y: list[float],
    learning_rate: float = 0.03,
    epochs: int = 3000,
    ridge: float = 0.001,
) -> list[float]:
    n_features = len(x_rows[0])
    weights = [0.0 for _ in range(n_features)]
    n = float(len(x_rows))

    for _ in range(epochs):
        gradients = [0.0 for _ in range(n_features)]
        for x, target in zip(x_rows, y):
            prediction = dot(weights, x)
            error = prediction - target
            for j in range(n_features):
                gradients[j] += error * x[j] / n
        for j in range(n_features):
            gradients[j] += ridge * weights[j]
            weights[j] -= learning_rate * gradients[j]

    return weights


def rmse(actual: list[float], predicted: list[float]) -> float:
    return math.sqrt(mean((a - p) ** 2 for a, p in zip(actual, predicted)))


def mae(actual: list[float], predicted: list[float]) -> float:
    return mean(abs(a - p) for a, p in zip(actual, predicted))


def simulate_scenario(scenario_row: dict[str, str]) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    scenario = scenario_row["scenario"]
    n = int(float(scenario_row["n"]))
    noise_scale = float(scenario_row["noise_scale"])
    structural_weight = float(scenario_row["structural_weight"])
    residual_strength = float(scenario_row["residual_strength"])
    interaction_strength = float(scenario_row["interaction_strength"])
    drift_strength = float(scenario_row["drift_strength"])

    seed = abs(hash(scenario)) % 100000 + 42
    rng = random.Random(seed)

    rows: list[dict[str, object]] = []

    for index in range(n):
        index_share = index / max(n - 1, 1)
        input_a = rng.uniform(0.0, 10.0)
        input_b = rng.uniform(-3.0, 3.0)
        input_c = rng.uniform(1.0, 8.0)

        structural_baseline = structural_weight * (
            1.8 * math.sin(input_a) + 0.6 * input_b - 0.4 * input_c
        )

        drift_term = drift_strength * index_share * input_b

        true_response = (
            structural_baseline
            + residual_strength * input_b ** 2
            + interaction_strength * input_a * input_b
            + drift_term
            + rng.gauss(0.0, noise_scale)
        )

        rows.append({
            "scenario": scenario,
            "index": index,
            "index_share": round(index_share, 6),
            "input_a": round(input_a, 6),
            "input_b": round(input_b, 6),
            "input_c": round(input_c, 6),
            "structural_baseline": round(structural_baseline, 6),
            "true_response": round(true_response, 6),
            "residual": round(true_response - structural_baseline, 6),
        })

    rng.shuffle(rows)
    split = int(0.75 * len(rows))

    train_rows = rows[:split]
    test_rows = rows[split:]

    x_train_raw = [
        features(
            float(row["input_a"]),
            float(row["input_b"]),
            float(row["input_c"]),
            float(row["index_share"]),
        )
        for row in train_rows
    ]

    x_test_raw = [
        features(
            float(row["input_a"]),
            float(row["input_b"]),
            float(row["input_c"]),
            float(row["index_share"]),
        )
        for row in test_rows
    ]

    x_train, means, scales = standardize_matrix(x_train_raw)
    x_test = apply_standardization(x_test_raw, means, scales)

    y_train = [float(row["residual"]) for row in train_rows]
    weights = fit_linear_model(x_train, y_train)

    prediction_rows: list[dict[str, object]] = []
    actual_values: list[float] = []
    baseline_predictions: list[float] = []
    hybrid_predictions: list[float] = []

    for row, x in zip(test_rows, x_test):
        learned_residual = dot(weights, x)
        baseline = float(row["structural_baseline"])
        actual = float(row["true_response"])
        hybrid_prediction = baseline + learned_residual

        actual_values.append(actual)
        baseline_predictions.append(baseline)
        hybrid_predictions.append(hybrid_prediction)

        prediction_rows.append({
            "scenario": scenario,
            "index": row["index"],
            "input_a": row["input_a"],
            "input_b": row["input_b"],
            "input_c": row["input_c"],
            "true_response": round(actual, 6),
            "structural_baseline": round(baseline, 6),
            "learned_residual": round(learned_residual, 6),
            "hybrid_prediction": round(hybrid_prediction, 6),
            "baseline_error": round(actual - baseline, 6),
            "hybrid_error": round(actual - hybrid_prediction, 6),
        })

    baseline_rmse = rmse(actual_values, baseline_predictions)
    hybrid_rmse = rmse(actual_values, hybrid_predictions)
    baseline_mae = mae(actual_values, baseline_predictions)
    hybrid_mae = mae(actual_values, hybrid_predictions)

    improvement_ratio = (baseline_rmse - hybrid_rmse) / max(baseline_rmse, 1e-12)

    metric_row = {
        "scenario": scenario,
        "baseline_rmse": round(baseline_rmse, 6),
        "hybrid_rmse": round(hybrid_rmse, 6),
        "baseline_mae": round(baseline_mae, 6),
        "hybrid_mae": round(hybrid_mae, 6),
        "hybrid_improvement_ratio": round(improvement_ratio, 6),
        "diagnostic_label": (
            "hybrid improved baseline"
            if hybrid_rmse < baseline_rmse
            else "hybrid did not improve baseline"
        ),
    }

    validation_rows = [
        {
            "scenario": scenario,
            "check": "hybrid_rmse_less_than_baseline_rmse",
            "passed": hybrid_rmse < baseline_rmse,
            "baseline_value": round(baseline_rmse, 6),
            "hybrid_value": round(hybrid_rmse, 6),
        },
        {
            "scenario": scenario,
            "check": "hybrid_mae_less_than_baseline_mae",
            "passed": hybrid_mae < baseline_mae,
            "baseline_value": round(baseline_mae, 6),
            "hybrid_value": round(hybrid_mae, 6),
        },
        {
            "scenario": scenario,
            "check": "hybrid_improvement_ratio_finite",
            "passed": math.isfinite(improvement_ratio),
            "baseline_value": 0,
            "hybrid_value": round(improvement_ratio, 6),
        },
    ]

    return prediction_rows, [metric_row], validation_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_predictions: list[dict[str, object]] = []
    all_metrics: list[dict[str, object]] = []
    all_validations: list[dict[str, object]] = []

    for scenario in scenario_rows:
        predictions, metrics, validations = simulate_scenario(scenario)
        all_predictions.extend(predictions)
        all_metrics.extend(metrics)
        all_validations.extend(validations)

    write_csv(TABLES / "python_ai_roles_in_systems_modeling.csv", read_csv(DATA / "ai_roles_in_systems_modeling.csv"))
    write_csv(TABLES / "python_hybrid_architectures.csv", read_csv(DATA / "hybrid_architectures.csv"))
    write_csv(TABLES / "python_governance_dimensions.csv", read_csv(DATA / "governance_dimensions.csv"))
    write_csv(TABLES / "python_data_risk_register.csv", read_csv(DATA / "data_risk_register.csv"))
    write_csv(TABLES / "python_constraint_types.csv", read_csv(DATA / "constraint_types.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_ai_hybrid_predictions.csv", all_predictions)
    write_csv(TABLES / "python_ai_hybrid_metrics.csv", all_metrics)
    write_csv(TABLES / "python_ai_hybrid_validation_checks.csv", all_validations)

    print("AI and machine learning systems modeling workflow complete.")
    print(TABLES / "python_ai_hybrid_metrics.csv")


if __name__ == "__main__":
    main()
