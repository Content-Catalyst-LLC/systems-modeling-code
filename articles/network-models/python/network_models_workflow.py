#!/usr/bin/env python3
"""
Network models workflow.

Dependency-light workflow demonstrating:

1. Graph construction from edge lists
2. Degree and component diagnostics
3. Reachable path-length analysis
4. Random versus targeted removal
5. Simple contagion
6. Threshold cascade
7. Synthetic validation checks

All data are synthetic.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path
import csv
import random


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


Graph = dict[int, set[int]]


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


def load_graph() -> Graph:
    nodes = [int(row["node_id"]) for row in read_csv(DATA / "node_attributes.csv")]
    graph: Graph = {node: set() for node in nodes}

    for row in read_csv(DATA / "synthetic_network_edges.csv"):
        source = int(row["source"])
        target = int(row["target"])
        graph[source].add(target)
        graph[target].add(source)

    return graph


def edge_count(graph: Graph) -> int:
    return sum(len(neighbors) for neighbors in graph.values()) // 2


def degree_rows(graph: Graph) -> list[dict[str, object]]:
    return [
        {
            "node": node,
            "degree": len(neighbors),
            "degree_centrality": round(len(neighbors) / max(1, len(graph) - 1), 6),
        }
        for node, neighbors in sorted(graph.items())
    ]


def shortest_paths_from(graph: Graph, source: int) -> dict[int, int]:
    distances = {source: 0}
    queue = deque([source])

    while queue:
        current = queue.popleft()
        for neighbor in graph.get(current, set()):
            if neighbor not in distances:
                distances[neighbor] = distances[current] + 1
                queue.append(neighbor)

    return distances


def connected_components(graph: Graph) -> list[set[int]]:
    seen: set[int] = set()
    components: list[set[int]] = []

    for node in graph:
        if node in seen:
            continue

        component = set()
        queue = deque([node])
        seen.add(node)

        while queue:
            current = queue.popleft()
            component.add(current)

            for neighbor in graph.get(current, set()):
                if neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)

        components.append(component)

    return components


def graph_summary(graph: Graph, scenario: str) -> dict[str, object]:
    n = len(graph)
    m = edge_count(graph)
    possible_edges = n * (n - 1) / 2
    degrees = [len(neighbors) for neighbors in graph.values()]
    components = connected_components(graph)

    path_lengths = []
    for node in graph:
        distances = shortest_paths_from(graph, node)
        path_lengths.extend(distance for target, distance in distances.items() if target != node)

    largest_component_size = max((len(component) for component in components), default=0)

    return {
        "scenario": scenario,
        "nodes": n,
        "edges": m,
        "density": round(m / possible_edges, 6) if possible_edges else 0,
        "average_degree": round(sum(degrees) / n, 6) if n else 0,
        "maximum_degree": max(degrees) if degrees else 0,
        "component_count": len(components),
        "largest_component_size": largest_component_size,
        "largest_component_share": round(largest_component_size / max(1, n), 6),
        "average_path_length_reachable": round(sum(path_lengths) / len(path_lengths), 6) if path_lengths else 0,
    }


def remove_nodes(graph: Graph, nodes_to_remove: set[int]) -> Graph:
    return {
        node: {neighbor for neighbor in neighbors if neighbor not in nodes_to_remove}
        for node, neighbors in graph.items()
        if node not in nodes_to_remove
    }


def robustness_experiment(graph: Graph, seed: int = 70707) -> list[dict[str, object]]:
    rng = random.Random(seed)
    nodes = list(graph.keys())
    degree_ranked = sorted(nodes, key=lambda node: len(graph[node]), reverse=True)

    rows: list[dict[str, object]] = []

    for fraction in [0.0, 0.05, 0.10, 0.15, 0.20, 0.25]:
        k = int(round(len(nodes) * fraction))

        random_removed = set(rng.sample(nodes, k)) if k > 0 else set()
        targeted_removed = set(degree_ranked[:k])

        for strategy, removed in [
            ("random_removal", random_removed),
            ("targeted_high_degree_removal", targeted_removed),
        ]:
            revised = remove_nodes(graph, removed)
            summary = graph_summary(revised, strategy)

            rows.append({
                "strategy": strategy,
                "removal_fraction": fraction,
                "nodes_removed": k,
                "remaining_nodes": len(revised),
                "component_count": summary["component_count"],
                "largest_component_size": summary["largest_component_size"],
                "largest_component_share": summary["largest_component_share"],
            })

    return rows


def contagion_simulation(graph: Graph, seed_node: int = 2, probability: float = 0.18, steps: int = 24, seed: int = 80808) -> list[dict[str, object]]:
    rng = random.Random(seed)
    infected = {seed_node}
    rows: list[dict[str, object]] = []

    for step in range(steps + 1):
        rows.append({
            "step": step,
            "infected_count": len(infected),
            "infected_share": round(len(infected) / max(1, len(graph)), 6),
            "probability": probability,
        })

        newly_infected = set(infected)

        for node in infected:
            for neighbor in graph.get(node, set()):
                if neighbor not in infected and rng.random() < probability:
                    newly_infected.add(neighbor)

        infected = newly_infected

    return rows


def threshold_cascade(graph: Graph, seed_nodes: set[int] | None = None, threshold: float = 0.30, steps: int = 24) -> list[dict[str, object]]:
    active = set(seed_nodes or {2, 18, 34})
    rows: list[dict[str, object]] = []

    for step in range(steps + 1):
        rows.append({
            "step": step,
            "active_count": len(active),
            "cascade_share": round(len(active) / max(1, len(graph)), 6),
            "threshold": threshold,
        })

        next_active = set(active)

        for node, neighbors in graph.items():
            if node in active or not neighbors:
                continue

            active_neighbors = sum(1 for neighbor in neighbors if neighbor in active)
            active_share = active_neighbors / len(neighbors)

            if active_share >= threshold:
                next_active.add(node)

        if next_active == active:
            active = next_active
            break

        active = next_active

    return rows


def validate_summary(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    validation_rows: list[dict[str, object]] = []

    checks = {
        "density": (0.0, 1.0),
        "average_degree": (0.0, 47.0),
        "maximum_degree": (0.0, 47.0),
        "component_count": (1.0, 48.0),
        "largest_component_share": (0.0, 1.0),
    }

    for row in summary_rows:
        for metric, (low, high) in checks.items():
            value = float(row[metric])
            validation_rows.append({
                "scenario": row["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
            })

    return validation_rows


def main() -> None:
    graph = load_graph()
    summary = [graph_summary(graph, "baseline_network")]

    write_csv(TABLES / "python_network_concept_inventory.csv", read_csv(DATA / "network_concept_inventory.csv"))
    write_csv(TABLES / "python_network_node_degree.csv", degree_rows(graph))
    write_csv(TABLES / "python_network_summary.csv", summary)
    write_csv(TABLES / "python_network_robustness.csv", robustness_experiment(graph))
    write_csv(TABLES / "python_network_contagion.csv", contagion_simulation(graph))
    write_csv(TABLES / "python_network_threshold_cascade.csv", threshold_cascade(graph))
    write_csv(TABLES / "python_network_validation.csv", validate_summary(summary))

    print("Network modeling workflow complete.")
    print(TABLES / "python_network_summary.csv")


if __name__ == "__main__":
    main()
