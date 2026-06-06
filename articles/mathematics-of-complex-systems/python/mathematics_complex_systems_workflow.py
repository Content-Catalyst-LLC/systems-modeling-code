#!/usr/bin/env python3
"""
Mathematics of complex systems workflow.

Dependency-light workflow demonstrating:

1. Nonlinear logistic-map trajectories
2. Sensitivity to initial conditions
3. Bifurcation sampling
4. Synthetic network construction
5. Adjacency and degree structure
6. Network diffusion with stochastic shocks
7. Entropy and dispersion diagnostics

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import math
import random
from statistics import mean, pstdev


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


def logistic_map(r: float, initial_state: float, steps: int) -> list[float]:
    values = [initial_state]
    for _ in range(1, steps):
        values.append(r * values[-1] * (1.0 - values[-1]))
    return values


def entropy(values: list[float], bins: int = 10) -> float:
    if not values:
        return 0.0

    low = min(values)
    high = max(values)

    if high == low:
        return 0.0

    counts = [0 for _ in range(bins)]
    for value in values:
        index = int((value - low) / (high - low) * bins)
        if index == bins:
            index = bins - 1
        counts[index] += 1

    total = sum(counts)
    result = 0.0
    for count in counts:
        if count > 0:
            p = count / total
            result -= p * math.log(p)
    return result


def build_network() -> tuple[list[str], list[tuple[str, str, str, float]]]:
    nodes = [f"N{i:02d}" for i in range(1, 16)]
    edges: list[tuple[str, str, str, float]] = []

    for row in read_csv(DATA / "network_edges.csv"):
        edges.append((row["source"], row["target"], row["edge_type"], float(row["weight"])))

    return nodes, edges


def adjacency(nodes: list[str], edges: list[tuple[str, str, str, float]]) -> dict[str, set[str]]:
    graph = {node: set() for node in nodes}
    for left, right, _edge_type, _weight in edges:
        graph[left].add(right)
        graph[right].add(left)
    return graph


def simulate_diffusion(
    graph: dict[str, set[str]],
    steps: int = 80,
    alpha: float = 0.18,
    shock_sigma: float = 0.035,
    seed: int = 42,
) -> list[dict[str, object]]:
    rng = random.Random(seed)
    nodes = sorted(graph.keys())

    state = {node: 0.0 for node in nodes}
    state["N01"] = 1.0
    state["N08"] = 0.5

    rows: list[dict[str, object]] = []

    for time in range(steps):
        values = list(state.values())

        for node in nodes:
            rows.append({
                "time": time,
                "node": node,
                "state": round(state[node], 6),
                "network_mean_state": round(mean(values), 6),
                "network_state_sd": round(pstdev(values), 6),
                "network_entropy": round(entropy(values), 6),
            })

        new_state: dict[str, float] = {}

        for node in nodes:
            neighbors = graph[node]
            if not neighbors:
                neighbor_average = state[node]
            else:
                neighbor_average = mean(state[neighbor] for neighbor in neighbors)

            diffusion_term = alpha * (neighbor_average - state[node])
            shock = rng.gauss(0.0, shock_sigma)

            new_state[node] = state[node] + diffusion_term + shock

        state = new_state

    return rows


def main() -> None:
    logistic_steps = 120
    r_value = 3.9
    initial_1 = 0.4000
    initial_2 = 0.4001
    divergence_threshold = 0.10

    trajectory_1 = logistic_map(r_value, initial_1, logistic_steps)
    trajectory_2 = logistic_map(r_value, initial_2, logistic_steps)

    logistic_rows: list[dict[str, object]] = []
    for time, (x1, x2) in enumerate(zip(trajectory_1, trajectory_2), start=1):
        logistic_rows.append({
            "time": time,
            "r": r_value,
            "trajectory_1": round(x1, 8),
            "trajectory_2": round(x2, 8),
            "absolute_difference": round(abs(x1 - x2), 8),
        })

    divergence_times = [
        row["time"]
        for row in logistic_rows
        if float(row["absolute_difference"]) >= divergence_threshold
    ]

    first_divergence_time = divergence_times[0] if divergence_times else ""

    bifurcation_rows: list[dict[str, object]] = []
    for index in range(80):
        r = 2.8 + index * (4.0 - 2.8) / 79
        trajectory = logistic_map(r, 0.41, 300)
        for state_value in trajectory[200:300]:
            bifurcation_rows.append({
                "r": round(r, 6),
                "state_value": round(state_value, 8),
            })

    nodes, edges = build_network()
    graph = adjacency(nodes, edges)

    node_rows = []
    for node in nodes:
        node_rows.append({
            "node": node,
            "degree": len(graph[node]),
            "neighbor_list": ";".join(sorted(graph[node])),
        })

    edge_rows = [
        {
            "source": left,
            "target": right,
            "edge_type": edge_type,
            "weight": weight,
        }
        for left, right, edge_type, weight in edges
    ]

    trajectory_rows = simulate_diffusion(graph)
    final_time = max(int(row["time"]) for row in trajectory_rows)
    final_rows = [row for row in trajectory_rows if int(row["time"]) == final_time]
    initial_rows = [row for row in trajectory_rows if int(row["time"]) == 0]

    summary_rows = [
        {
            "metric": "node_count",
            "value": len(nodes),
            "interpretation": "number of system components",
        },
        {
            "metric": "edge_count",
            "value": len(edges),
            "interpretation": "number of undirected dependencies",
        },
        {
            "metric": "mean_degree",
            "value": round(mean(row["degree"] for row in node_rows), 6),
            "interpretation": "average local connectivity",
        },
        {
            "metric": "logistic_maximum_absolute_difference",
            "value": round(max(float(row["absolute_difference"]) for row in logistic_rows), 6),
            "interpretation": "maximum divergence between similar initial conditions",
        },
        {
            "metric": "first_divergence_time",
            "value": first_divergence_time,
            "interpretation": "first time absolute difference exceeds configured threshold",
        },
        {
            "metric": "logistic_trajectory_entropy",
            "value": round(entropy(trajectory_1), 6),
            "interpretation": "simple binned entropy of nonlinear trajectory",
        },
        {
            "metric": "initial_state_dispersion",
            "value": round(pstdev(float(row["state"]) for row in initial_rows), 6),
            "interpretation": "initial variation across node states",
        },
        {
            "metric": "final_state_dispersion",
            "value": round(pstdev(float(row["state"]) for row in final_rows), 6),
            "interpretation": "final variation after diffusion and stochastic shocks",
        },
        {
            "metric": "final_mean_state",
            "value": round(mean(float(row["state"]) for row in final_rows), 6),
            "interpretation": "network-level state after diffusion process",
        },
    ]

    validation_rows: list[dict[str, object]] = []
    for row in logistic_rows:
        for metric, value, low, high in [
            ("trajectory_1", float(row["trajectory_1"]), 0.0, 1.0),
            ("trajectory_2", float(row["trajectory_2"]), 0.0, 1.0),
            ("absolute_difference", float(row["absolute_difference"]), 0.0, 1.0),
        ]:
            validation_rows.append({
                "scope": f"time_{row['time']}",
                "metric": metric,
                "value": round(value, 8),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    write_csv(TABLES / "python_mathematical_frameworks.csv", read_csv(DATA / "mathematical_frameworks.csv"))
    write_csv(TABLES / "python_nonlinear_parameters.csv", read_csv(DATA / "nonlinear_parameters.csv"))
    write_csv(TABLES / "python_logistic_map_trajectories.csv", logistic_rows)
    write_csv(TABLES / "python_bifurcation_sample.csv", bifurcation_rows)
    write_csv(TABLES / "python_network_nodes.csv", node_rows)
    write_csv(TABLES / "python_network_edges.csv", edge_rows)
    write_csv(TABLES / "python_network_diffusion_trajectories.csv", trajectory_rows)
    write_csv(TABLES / "python_complex_systems_math_summary.csv", summary_rows)
    write_csv(TABLES / "python_complex_systems_validation_checks.csv", validation_rows)

    print("Mathematics of complex systems workflow complete.")
    print(TABLES / "python_complex_systems_math_summary.csv")


if __name__ == "__main__":
    main()
