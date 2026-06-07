#!/usr/bin/env python3
"""
Cascading failure and contagion workflow.

Dependency-light workflow demonstrating:
1. Synthetic directed dependency network
2. Random initiating failure
3. Targeted hub failure
4. Common-mode failure
5. Threshold-based propagation
6. Recovery probability
7. Resilience intervention diagnostics

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import random
from statistics import mean

ARTICLE_ROOT = Path(__file__).resolve().parents[1]
TABLES = ARTICLE_ROOT / "outputs" / "tables"


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError(f"No rows to write: {path}")
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def stable_seed(label: str) -> int:
    return 1000 + sum((index + 1) * ord(char) for index, char in enumerate(label))


def create_network(n_nodes: int = 45, base_probability: float = 0.07) -> list[list[float]]:
    rng = random.Random(42)
    adjacency = [[0.0 for _ in range(n_nodes)] for _ in range(n_nodes)]

    for source in range(n_nodes):
        for target in range(n_nodes):
            if source != target and rng.random() < base_probability:
                adjacency[source][target] = rng.uniform(0.15, 0.65)

    for hub in [4, 13, 28]:
        possible_targets = [node for node in range(n_nodes) if node != hub]
        for target in rng.sample(possible_targets, 12):
            adjacency[hub][target] = rng.uniform(0.35, 0.90)

    return adjacency


def out_degree(adjacency: list[list[float]], node: int) -> int:
    return sum(1 for weight in adjacency[node] if weight > 0)


def in_degree(adjacency: list[list[float]], node: int) -> int:
    return sum(1 for row in adjacency if row[node] > 0)


def simulate_cascade(
    adjacency: list[list[float]],
    scenario: str,
    initial_failed: set[int],
    threshold_multiplier: float,
    recovery_probability: float,
    steps: int = 30,
) -> list[dict[str, object]]:
    rng = random.Random(stable_seed(scenario))
    n_nodes = len(adjacency)
    thresholds = [rng.uniform(0.55, 1.35) * threshold_multiplier for _ in range(n_nodes)]
    failed = set(initial_failed)
    rows: list[dict[str, object]] = []

    for time in range(1, steps + 1):
        stress = [0.0 for _ in range(n_nodes)]

        for source in failed:
            for target in range(n_nodes):
                stress[target] += adjacency[source][target]

        new_failures = {
            node for node in range(n_nodes)
            if node not in failed and stress[node] >= thresholds[node]
        }
        recovered = {node for node in failed if rng.random() < recovery_probability}

        failed.update(new_failures)
        failed.difference_update(recovered)

        rows.append({
            "scenario": scenario,
            "time": time,
            "failed_count": len(failed),
            "failed_fraction": round(len(failed) / n_nodes, 6),
            "new_failures": len(new_failures),
            "recovered": len(recovered),
            "mean_stress": round(mean(stress), 6),
            "max_stress": round(max(stress), 6),
        })

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        failed_fractions = [float(row["failed_fraction"]) for row in subset]
        mean_stresses = [float(row["mean_stress"]) for row in subset]
        max_stresses = [float(row["max_stress"]) for row in subset]

        summary_rows.append({
            "scenario": scenario,
            "peak_failed_fraction": round(max(failed_fractions), 6),
            "final_failed_fraction": round(failed_fractions[-1], 6),
            "total_new_failures": sum(int(row["new_failures"]) for row in subset),
            "total_recovered": sum(int(row["recovered"]) for row in subset),
            "average_mean_stress": round(mean(mean_stresses), 6),
            "max_stress_observed": round(max(max_stresses), 6),
        })

    return summary_rows


def main() -> None:
    adjacency = create_network()
    n_nodes = len(adjacency)

    node_rows: list[dict[str, object]] = []
    for node in range(n_nodes):
        node_rows.append({
            "node": node + 1,
            "in_degree": in_degree(adjacency, node),
            "out_degree": out_degree(adjacency, node),
            "incoming_weight": round(sum(row[node] for row in adjacency), 6),
            "outgoing_weight": round(sum(adjacency[node]), 6),
        })

    hub = max(range(n_nodes), key=lambda node: out_degree(adjacency, node))
    initial_rng = random.Random(222)
    random_initial = set(initial_rng.sample(range(n_nodes), 2))
    common_mode_group = {3, 7, 11, 19, 23}

    scenarios = [
        {"scenario": "random_failure_baseline", "initial_failed": random_initial, "threshold_multiplier": 1.00, "recovery_probability": 0.05},
        {"scenario": "targeted_hub_failure", "initial_failed": {hub}, "threshold_multiplier": 1.00, "recovery_probability": 0.05},
        {"scenario": "common_mode_failure", "initial_failed": common_mode_group, "threshold_multiplier": 1.00, "recovery_probability": 0.05},
        {"scenario": "low_buffer_high_fragility", "initial_failed": random_initial, "threshold_multiplier": 0.70, "recovery_probability": 0.03},
        {"scenario": "resilience_intervention", "initial_failed": {hub}, "threshold_multiplier": 1.35, "recovery_probability": 0.12},
    ]

    all_rows: list[dict[str, object]] = []
    for scenario in scenarios:
        all_rows.extend(simulate_cascade(adjacency=adjacency, **scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []
    for row in summary_rows:
        for metric, low, high in [
            ("peak_failed_fraction", 0.0, 1.0),
            ("final_failed_fraction", 0.0, 1.0),
            ("total_new_failures", 0.0, 100000.0),
            ("total_recovered", 0.0, 100000.0),
            ("average_mean_stress", 0.0, 100000.0),
            ("max_stress_observed", 0.0, 100000.0),
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

    write_csv(TABLES / "python_cascade_trajectories.csv", all_rows)
    write_csv(TABLES / "python_cascade_summary.csv", summary_rows)
    write_csv(TABLES / "python_network_node_diagnostics.csv", node_rows)
    write_csv(TABLES / "python_cascade_validation_checks.csv", validation_rows)

    print("Cascading failure workflow complete.")
    print(TABLES / "python_cascade_summary.csv")


if __name__ == "__main__":
    main()
