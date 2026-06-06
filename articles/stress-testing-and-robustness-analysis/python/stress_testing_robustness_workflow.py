#!/usr/bin/env python3
"""
Stress testing and robustness analysis workflow.

Dependency-light workflow demonstrating:

1. Stress scenario ensembles
2. Policy comparison under adverse conditions
3. Failure thresholds
4. Regret analysis
5. Lower-tail robustness
6. Recovery and residual-loss diagnostics

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
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


def percentile(values: list[float], q: float) -> float:
    ordered = sorted(values)
    index = int(round((len(ordered) - 1) * q))
    return ordered[index]


def load_strategies() -> list[dict[str, object]]:
    strategies: list[dict[str, object]] = []
    for row in read_csv(DATA / "strategy_options.csv"):
        strategies.append({
            "strategy": row["strategy"],
            "redundancy": float(row["redundancy"]),
            "adaptive_response": float(row["adaptive_response"]),
            "description": row["description"],
        })
    return strategies


def simulate_strategy(
    demand_growth: float,
    capacity_loss: float,
    shock_duration: int,
    recovery_drag: float,
    redundancy: float,
    adaptive_response: float,
    n_steps: int = 72,
) -> dict[str, float]:
    baseline_capacity = 100.0
    demand = 55.0
    capacity = baseline_capacity * (1.0 + redundancy)
    service_threshold = 0.85

    minimum_service = 1.0
    cumulative_unmet = 0.0
    failure_count = 0
    recovery_time = float(n_steps)
    failed_once = False

    shock_start = 28

    for time in range(1, n_steps + 1):
        demand *= 1.0 + demand_growth

        shock_active = shock_start <= time < shock_start + shock_duration
        if time == shock_start:
            capacity = max(0.0, capacity - capacity_loss)

        if shock_active:
            demand *= 1.0 + 0.010
        else:
            recovery_rate = max(0.0, 0.12 + adaptive_response - recovery_drag)
            target_capacity = baseline_capacity * (1.0 + redundancy)
            capacity += recovery_rate * (target_capacity - capacity)

        capacity = max(0.0, capacity)
        service_ratio = 1.0 if demand <= 0 else min(capacity / demand, 1.0)
        unmet = max(demand - capacity, 0.0)

        minimum_service = min(minimum_service, service_ratio)
        cumulative_unmet += unmet

        if service_ratio < service_threshold:
            failure_count += 1
            failed_once = True

        if failed_once and service_ratio >= 0.95:
            recovery_time = min(recovery_time, float(time))

    resilience_score = max(
        0.0,
        100.0
        - 70.0 * (1.0 - minimum_service)
        - 0.05 * cumulative_unmet
        - 0.40 * failure_count,
    )

    return {
        "minimum_service_ratio": minimum_service,
        "cumulative_unmet_demand": cumulative_unmet,
        "failure_frequency": failure_count / n_steps,
        "recovery_time": recovery_time,
        "resilience_score": min(100.0, resilience_score),
    }


def stress_class(capacity_loss: float, demand_growth: float, shock_duration: int, recovery_drag: float) -> str:
    if capacity_loss > 32 and demand_growth > 0.026 and shock_duration > 12:
        return "compound_extreme"
    if capacity_loss > 28 or shock_duration > 14 or recovery_drag > 0.07:
        return "severe"
    if capacity_loss > 12:
        return "moderate"
    return "low"


def robustness_status(p10_score: float, failure_share: float, mean_regret: float) -> str:
    if p10_score >= 55 and failure_share <= 0.15 and mean_regret <= 10:
        return "robust across tested stress futures"
    if failure_share > 0.35:
        return "high failure share under tested stress futures"
    if mean_regret > 20:
        return "high regret under modelled stress futures"
    return "fragile under stress futures"


def main() -> None:
    rng = random.Random(42)
    strategies = load_strategies()

    scenario_rows: list[dict[str, object]] = []
    result_rows: list[dict[str, object]] = []

    for scenario_id in range(1, 701):
        demand_growth = rng.uniform(0.008, 0.035)
        capacity_loss = rng.uniform(0.0, 45.0)
        shock_duration = rng.randint(1, 20)
        recovery_drag = rng.uniform(0.0, 0.09)
        stress_label = stress_class(capacity_loss, demand_growth, shock_duration, recovery_drag)

        scenario_rows.append({
            "scenario_id": scenario_id,
            "demand_growth": round(demand_growth, 6),
            "capacity_loss": round(capacity_loss, 6),
            "shock_duration": shock_duration,
            "recovery_drag": round(recovery_drag, 6),
            "stress_class": stress_label,
        })

        scenario_results: list[dict[str, object]] = []

        for strategy in strategies:
            output = simulate_strategy(
                demand_growth=demand_growth,
                capacity_loss=capacity_loss,
                shock_duration=shock_duration,
                recovery_drag=recovery_drag,
                redundancy=float(strategy["redundancy"]),
                adaptive_response=float(strategy["adaptive_response"]),
            )

            row = {
                "scenario_id": scenario_id,
                "stress_class": stress_label,
                "strategy": strategy["strategy"],
                "redundancy": strategy["redundancy"],
                "adaptive_response": strategy["adaptive_response"],
                "minimum_service_ratio": round(output["minimum_service_ratio"], 6),
                "cumulative_unmet_demand": round(output["cumulative_unmet_demand"], 6),
                "failure_frequency": round(output["failure_frequency"], 6),
                "recovery_time": round(output["recovery_time"], 6),
                "resilience_score": round(output["resilience_score"], 6),
                "failed_threshold": output["minimum_service_ratio"] < 0.85,
            }

            scenario_results.append(row)

        best_score = max(float(row["resilience_score"]) for row in scenario_results)

        for row in scenario_results:
            row["regret"] = round(best_score - float(row["resilience_score"]), 6)
            result_rows.append(row)

    summary_rows: list[dict[str, object]] = []

    for strategy_name in sorted(set(str(row["strategy"]) for row in result_rows)):
        subset = [row for row in result_rows if row["strategy"] == strategy_name]
        scores = [float(row["resilience_score"]) for row in subset]
        regrets = [float(row["regret"]) for row in subset]
        minimum_services = [float(row["minimum_service_ratio"]) for row in subset]
        failures = [bool(row["failed_threshold"]) for row in subset]

        p10_score = percentile(scores, 0.10)
        p05_service = percentile(minimum_services, 0.05)
        worst_score = min(scores)
        failure_share = sum(1 for value in failures if value) / len(failures)
        mean_regret = mean(regrets)

        summary_rows.append({
            "strategy": strategy_name,
            "mean_resilience_score": round(mean(scores), 6),
            "p10_resilience_score": round(p10_score, 6),
            "worst_resilience_score": round(worst_score, 6),
            "p05_minimum_service_ratio": round(p05_service, 6),
            "failure_share": round(failure_share, 6),
            "mean_regret": round(mean_regret, 6),
            "maximum_regret": round(max(regrets), 6),
            "robustness_status": robustness_status(p10_score, failure_share, mean_regret),
        })

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("mean_resilience_score", 0.0, 100.0),
            ("p10_resilience_score", 0.0, 100.0),
            ("worst_resilience_score", 0.0, 100.0),
            ("p05_minimum_service_ratio", 0.0, 1.0),
            ("failure_share", 0.0, 1.0),
            ("mean_regret", 0.0, 100.0),
            ("maximum_regret", 0.0, 100.0),
        ]:
            value = float(row[metric])
            validation_rows.append({
                "strategy": row["strategy"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_stress_test_taxonomy.csv", read_csv(DATA / "stress_test_taxonomy.csv"))
    write_csv(TABLES / "python_failure_thresholds.csv", read_csv(DATA / "failure_thresholds.csv"))
    write_csv(TABLES / "python_strategy_options.csv", read_csv(DATA / "strategy_options.csv"))
    write_csv(TABLES / "python_stress_scenario_inventory.csv", scenario_rows)
    write_csv(TABLES / "python_strategy_stress_test_runs.csv", result_rows)
    write_csv(TABLES / "python_robustness_summary.csv", summary_rows)
    write_csv(TABLES / "python_stress_test_validation_checks.csv", validation_rows)

    print("Stress testing and robustness workflow complete.")
    print(TABLES / "python_robustness_summary.csv")


if __name__ == "__main__":
    main()
