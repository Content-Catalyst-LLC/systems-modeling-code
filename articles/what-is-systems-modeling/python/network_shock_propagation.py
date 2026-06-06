#!/usr/bin/env python3
"""
Network shock propagation workflow for systems modeling.

This dependency-light script uses only the Python standard library. It simulates
shock propagation through a weighted dependency network and writes reproducible
CSV outputs for scenario comparison and vulnerability diagnostics.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from pathlib import Path
import csv
import random
from statistics import mean


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
TABLES = ARTICLE_ROOT / "outputs" / "tables"


@dataclass(frozen=True)
class ShockScenario:
    name: str
    n_nodes: int = 12
    n_steps: int = 140
    seed: int = 42
    coupling_strength: float = 0.18
    recovery_rate: float = 0.075
    redundancy: float = 0.20
    shock_node: int = 3
    shock_time: int = 42
    shock_size: float = -0.55
    noise_sd: float = 0.006


def clamp(value: float, low: float = 0.0, high: float = 1.25) -> float:
    return max(low, min(high, value))


def build_dependency_matrix(scenario: ShockScenario) -> list[list[float]]:
    rng = random.Random(scenario.seed)
    matrix: list[list[float]] = []

    for i in range(scenario.n_nodes):
        row = []
        for j in range(scenario.n_nodes):
            if i == j:
                row.append(0.0)
            else:
                connected = rng.random() < 0.36
                weight = rng.uniform(0.05, 1.0) if connected else 0.0
                row.append(weight)

        row_sum = sum(row)
        if row_sum == 0:
            row[(i + 1) % scenario.n_nodes] = 1.0
            row_sum = 1.0

        matrix.append([
            (value / row_sum) * scenario.coupling_strength * (1.0 - scenario.redundancy)
            for value in row
        ])

    return matrix


def simulate_network(scenario: ShockScenario) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    rng = random.Random(scenario.seed)
    dependency = build_dependency_matrix(scenario)

    state = [[1.0 for _ in range(scenario.n_nodes)] for _ in range(scenario.n_steps)]
    rows: list[dict[str, object]] = []

    for t in range(1, scenario.n_steps):
        previous = state[t - 1]

        for node in range(scenario.n_nodes):
            dependency_loss = 0.0
            for source in range(scenario.n_nodes):
                dependency_loss += dependency[node][source] * (previous[source] - 1.0)

            recovery = scenario.recovery_rate * (1.0 - previous[node])
            noise = rng.gauss(0.0, scenario.noise_sd)
            value = previous[node] + dependency_loss + recovery + noise

            if t == scenario.shock_time and node == scenario.shock_node:
                value += scenario.shock_size

            state[t][node] = clamp(value)

    for t in range(scenario.n_steps):
        system_performance = mean(state[t])
        worst_node = min(state[t])
        performance_loss = 1.0 - system_performance

        for node in range(scenario.n_nodes):
            rows.append({
                "scenario": scenario.name,
                "time": t,
                "node": f"node_{node}",
                "state": round(state[t][node], 6),
                "system_performance": round(system_performance, 6),
                "worst_node_state": round(worst_node, 6),
                "system_performance_loss": round(performance_loss, 6),
            })

    edge_rows: list[dict[str, object]] = []
    for target, row in enumerate(dependency):
        for source, weight in enumerate(row):
            if weight > 0:
                edge_rows.append({
                    "scenario": scenario.name,
                    "from_node": f"node_{source}",
                    "to_node": f"node_{target}",
                    "dependency_weight": round(weight, 6),
                })

    return rows, edge_rows


def summarize_vulnerability(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        scenario_rows = [row for row in rows if row["scenario"] == scenario]
        nodes = sorted(set(str(row["node"]) for row in scenario_rows))

        for node in nodes:
            node_rows = [row for row in scenario_rows if row["node"] == node]
            states = [float(row["state"]) for row in node_rows]
            system_losses = [float(row["system_performance_loss"]) for row in node_rows]

            min_state = min(states)
            final_state = states[-1]
            time_to_min = int(node_rows[states.index(min_state)]["time"])

            output.append({
                "scenario": scenario,
                "node": node,
                "minimum_state": round(min_state, 6),
                "max_node_loss": round(1.0 - min_state, 6),
                "final_state": round(final_state, 6),
                "final_unrecovered_loss": round(1.0 - final_state, 6),
                "time_to_minimum": time_to_min,
                "average_system_loss": round(mean(system_losses), 6),
            })

    return sorted(output, key=lambda row: (str(row["scenario"]), -float(row["max_node_loss"])))


def summarize_scenarios(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        scenario_rows = [row for row in rows if row["scenario"] == scenario]
        by_time: dict[int, list[dict[str, object]]] = {}

        for row in scenario_rows:
            by_time.setdefault(int(row["time"]), []).append(row)

        time_summary = []
        for t, t_rows in sorted(by_time.items()):
            performance = mean(float(row["state"]) for row in t_rows)
            time_summary.append({
                "time": t,
                "system_performance": performance,
                "worst_node_state": min(float(row["state"]) for row in t_rows),
            })

        performances = [row["system_performance"] for row in time_summary]
        worst_nodes = [row["worst_node_state"] for row in time_summary]
        min_performance = min(performances)
        final_performance = performances[-1]
        time_to_min = time_summary[performances.index(min_performance)]["time"]

        output.append({
            "scenario": scenario,
            "minimum_system_performance": round(min_performance, 6),
            "maximum_system_loss": round(1.0 - min_performance, 6),
            "final_system_performance": round(final_performance, 6),
            "final_unrecovered_system_loss": round(1.0 - final_performance, 6),
            "worst_node_state_over_run": round(min(worst_nodes), 6),
            "time_to_minimum_system_performance": time_to_min,
        })

    return output


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError(f"No rows to write: {path}")

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    baseline = ShockScenario(name="baseline")
    scenarios = [
        baseline,
        replace(baseline, name="high_coupling", coupling_strength=0.28, redundancy=0.12),
        replace(baseline, name="higher_redundancy", coupling_strength=0.16, redundancy=0.42, recovery_rate=0.105),
        replace(baseline, name="severe_shock", shock_size=-0.72, recovery_rate=0.065),
    ]

    all_state_rows: list[dict[str, object]] = []
    all_edge_rows: list[dict[str, object]] = []

    for scenario in scenarios:
        state_rows, edge_rows = simulate_network(scenario)
        all_state_rows.extend(state_rows)
        all_edge_rows.extend(edge_rows)

    write_csv(TABLES / "python_network_state_trajectories.csv", all_state_rows)
    write_csv(TABLES / "python_dependency_edges.csv", all_edge_rows)
    write_csv(TABLES / "python_node_vulnerability_diagnostics.csv", summarize_vulnerability(all_state_rows))
    write_csv(TABLES / "python_scenario_summary.csv", summarize_scenarios(all_state_rows))

    print("Network shock propagation workflow complete.")
    print(TABLES / "python_scenario_summary.csv")


if __name__ == "__main__":
    main()
