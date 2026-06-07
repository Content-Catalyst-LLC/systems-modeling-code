#!/usr/bin/env python3
"""
Phase transitions in complex systems workflow.

Dependency-light workflow demonstrating:

1. Random network generation
2. Connectivity phase transition
3. Largest connected component detection
4. Giant component threshold diagnostics
5. Order-parameter branch diagnostics
6. Scenario comparison
7. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from pathlib import Path
import csv
import math
import random
from collections import deque
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


def linear_space(start: float, stop: float, count: int) -> list[float]:
    if count < 2:
        return [start]

    step = (stop - start) / (count - 1)
    return [start + i * step for i in range(count)]


def generate_random_graph(node_count: int, link_probability: float, seed: int) -> dict[int, set[int]]:
    rng = random.Random(seed)
    graph: dict[int, set[int]] = {node: set() for node in range(node_count)}

    for source in range(node_count):
        for target in range(source + 1, node_count):
            if rng.random() < link_probability:
                graph[source].add(target)
                graph[target].add(source)

    return graph


def connected_components(graph: dict[int, set[int]]) -> list[set[int]]:
    visited: set[int] = set()
    components: list[set[int]] = []

    for node in graph:
        if node in visited:
            continue

        component: set[int] = set()
        queue: deque[int] = deque([node])
        visited.add(node)

        while queue:
            current = queue.popleft()
            component.add(current)

            for neighbor in graph[current]:
                if neighbor not in visited:
                    visited.add(neighbor)
                    queue.append(neighbor)

        components.append(component)

    return components


def simulate_connectivity_transition(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    node_count = int(float(row["node_count"]))
    probability_start = float(row["probability_start"])
    probability_end = float(row["probability_end"])
    probability_steps = int(float(row["probability_steps"]))
    seed = int(float(row["seed"]))
    giant_component_threshold = float(row["giant_component_threshold"])

    rows: list[dict[str, object]] = []

    for index, probability in enumerate(linear_space(probability_start, probability_end, probability_steps), start=1):
        graph = generate_random_graph(node_count, probability, seed + index)
        components = connected_components(graph)

        edge_count = sum(len(neighbors) for neighbors in graph.values()) // 2
        largest_component_size = max(len(component) for component in components)
        largest_component_fraction = largest_component_size / node_count
        average_degree = (2 * edge_count) / node_count

        rows.append({
            "scenario": scenario,
            "step": index,
            "node_count": node_count,
            "link_probability": round(probability, 6),
            "edge_count": edge_count,
            "average_degree": round(average_degree, 6),
            "component_count": len(components),
            "largest_component_size": largest_component_size,
            "largest_component_fraction": round(largest_component_fraction, 6),
            "giant_component_threshold": giant_component_threshold,
            "giant_component_flag": int(largest_component_fraction >= giant_component_threshold),
        })

    return rows


def summarize_network(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        giant_rows = [row for row in subset if int(row["giant_component_flag"]) == 1]

        threshold_probability = giant_rows[0]["link_probability"] if giant_rows else ""
        threshold_average_degree = giant_rows[0]["average_degree"] if giant_rows else ""

        summary_rows.append({
            "scenario": scenario,
            "node_count": subset[0]["node_count"],
            "minimum_link_probability": subset[0]["link_probability"],
            "maximum_link_probability": subset[-1]["link_probability"],
            "maximum_largest_component_fraction": round(max(float(row["largest_component_fraction"]) for row in subset), 6),
            "mean_component_count": round(mean(float(row["component_count"]) for row in subset), 6),
            "minimum_average_degree": round(min(float(row["average_degree"]) for row in subset), 6),
            "maximum_average_degree": round(max(float(row["average_degree"]) for row in subset), 6),
            "approximate_giant_component_probability": threshold_probability,
            "approximate_giant_component_average_degree": threshold_average_degree,
            "diagnostic_label": "giant component emerged" if giant_rows else "no giant component detected",
        })

    return summary_rows


def bifurcation_branches(start: float = -1.5, stop: float = 1.5, count: int = 301) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    for index, control_parameter in enumerate(linear_space(start, stop, count), start=1):
        if control_parameter > 0:
            stable_positive = math.sqrt(control_parameter)
            stable_negative = -math.sqrt(control_parameter)
            phase_label = "two ordered phases"
            order_parameter_magnitude = stable_positive
        else:
            stable_positive = 0.0
            stable_negative = 0.0
            phase_label = "single neutral phase"
            order_parameter_magnitude = 0.0

        rows.append({
            "step": index,
            "control_parameter": round(control_parameter, 6),
            "stable_state_positive": round(stable_positive, 6),
            "stable_state_negative": round(stable_negative, 6),
            "neutral_state": 0.0,
            "order_parameter_magnitude": round(order_parameter_magnitude, 6),
            "phase_label": phase_label,
        })

    return rows


def summarize_bifurcation(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    return [
        {
            "metric": "minimum_control_parameter",
            "value": min(float(row["control_parameter"]) for row in rows),
            "interpretation": "lowest scanned control parameter",
        },
        {
            "metric": "maximum_control_parameter",
            "value": max(float(row["control_parameter"]) for row in rows),
            "interpretation": "highest scanned control parameter",
        },
        {
            "metric": "critical_threshold",
            "value": 0.0,
            "interpretation": "stylized threshold where ordered branches emerge",
        },
        {
            "metric": "maximum_order_parameter_magnitude",
            "value": round(max(float(row["order_parameter_magnitude"]) for row in rows), 6),
            "interpretation": "largest order-parameter magnitude in scan",
        },
        {
            "metric": "ordered_phase_count",
            "value": sum(1 for row in rows if row["phase_label"] == "two ordered phases"),
            "interpretation": "number of scanned points with nonzero ordered branches",
        },
    ]


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    network_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        network_rows.extend(simulate_connectivity_transition(scenario))

    network_summary_rows = summarize_network(network_rows)
    bifurcation_rows = bifurcation_branches()
    bifurcation_summary_rows = summarize_bifurcation(bifurcation_rows)

    validation_rows: list[dict[str, object]] = []

    for row in network_summary_rows:
        for metric, low, high in [
            ("maximum_largest_component_fraction", 0.0, 1.0),
            ("mean_component_count", 0.0, 1000000.0),
            ("minimum_average_degree", 0.0, 1000000.0),
            ("maximum_average_degree", 0.0, 1000000.0),
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

        if row["approximate_giant_component_probability"] != "":
            value = float(row["approximate_giant_component_probability"])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": "approximate_giant_component_probability",
                "value": round(value, 6),
                "target_low": 0.0,
                "target_high": 1.0,
                "passed": 0.0 <= value <= 1.0,
            })

    for row in bifurcation_summary_rows:
        value = float(row["value"])
        validation_rows.append({
            "scenario": "bifurcation_order_parameter",
            "metric": row["metric"],
            "value": round(value, 6),
            "target_low": -1000000.0,
            "target_high": 1000000.0,
            "passed": -1000000.0 <= value <= 1000000.0,
        })

    write_csv(TABLES / "python_phase_transition_concepts.csv", read_csv(DATA / "phase_transition_concepts.csv"))
    write_csv(TABLES / "python_domain_phase_transition_examples.csv", read_csv(DATA / "domain_phase_transition_examples.csv"))
    write_csv(TABLES / "python_modeling_strategies.csv", read_csv(DATA / "modeling_strategies.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_network_phase_transition_trajectories.csv", network_rows)
    write_csv(TABLES / "python_network_phase_transition_summary.csv", network_summary_rows)
    write_csv(TABLES / "python_bifurcation_order_parameter_branches.csv", bifurcation_rows)
    write_csv(TABLES / "python_bifurcation_order_parameter_summary.csv", bifurcation_summary_rows)
    write_csv(TABLES / "python_phase_transition_validation_checks.csv", validation_rows)

    print("Phase transitions workflow complete.")
    print(TABLES / "python_network_phase_transition_summary.csv")


if __name__ == "__main__":
    main()
