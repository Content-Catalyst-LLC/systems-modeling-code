#!/usr/bin/env python3
"""
Case study: shock propagation in infrastructure networks.

Dependency-light workflow demonstrating:

1. Synthetic infrastructure network data
2. Initial shock scenarios
3. Dependency-based cascading failure
4. Load redistribution and overload failure
5. Weighted service loss
6. Scenario diagnostics and validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import csv


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


@dataclass(frozen=True)
class Node:
    name: str
    sector: str
    load: float
    capacity: float
    criticality: float
    repair_time: int
    description: str


@dataclass(frozen=True)
class Edge:
    source: str
    target: str
    edge_type: str
    description: str


@dataclass(frozen=True)
class Scenario:
    name: str
    initial_failures: set[str]
    description: str


def read_nodes(path: Path) -> list[Node]:
    nodes: list[Node] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            nodes.append(
                Node(
                    name=row["node"],
                    sector=row["sector"],
                    load=float(row["load"]),
                    capacity=float(row["capacity"]),
                    criticality=float(row["criticality"]),
                    repair_time=int(row["repair_time"]),
                    description=row["description"],
                )
            )
    return nodes


def read_edges(path: Path) -> list[Edge]:
    edges: list[Edge] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            edges.append(
                Edge(
                    source=row["source"],
                    target=row["target"],
                    edge_type=row["edge_type"],
                    description=row["description"],
                )
            )
    return edges


def read_scenarios(path: Path) -> list[Scenario]:
    scenarios: list[Scenario] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            scenarios.append(
                Scenario(
                    name=row["scenario"],
                    initial_failures=set(row["initial_failures"].split("|")),
                    description=row["description"],
                )
            )
    return scenarios


def read_csv_dicts(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError(f"No rows to write: {path}")

    fieldnames: list[str] = []
    for row in rows:
        for key in row:
            if key not in fieldnames:
                fieldnames.append(key)

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def node_rows(nodes: list[Node]) -> list[dict[str, object]]:
    return [node.__dict__ for node in nodes]


def edge_rows(edges: list[Edge]) -> list[dict[str, object]]:
    return [edge.__dict__ for edge in edges]


def scenario_rows(scenarios: list[Scenario]) -> list[dict[str, object]]:
    return [
        {
            "scenario": scenario.name,
            "initial_failures": "|".join(sorted(scenario.initial_failures)),
            "description": scenario.description,
        }
        for scenario in scenarios
    ]


def simulate_cascade(
    scenario: Scenario,
    nodes: list[Node],
    edges: list[Edge],
    max_steps: int = 8,
    overload_threshold: float = 1.05,
    dependency_tolerance: float = 0.50,
) -> list[dict[str, object]]:
    node_by_name = {node.name: node for node in nodes}
    status = {node.name: 1 for node in nodes}
    load = {node.name: node.load for node in nodes}

    for failed in scenario.initial_failures:
        if failed in status:
            status[failed] = 0

    rows: list[dict[str, object]] = []

    for step in range(max_steps + 1):
        failed_nodes = [name for name, value in status.items() if value == 0]
        weighted_service_loss = sum(node_by_name[name].criticality for name in failed_nodes)

        dependency_failures: set[str] = set()
        overload_failures: set[str] = set()

        rows.append(
            {
                "scenario": scenario.name,
                "step": step,
                "failed_count": len(failed_nodes),
                "failed_nodes": "|".join(failed_nodes),
                "weighted_service_loss": round(weighted_service_loss, 6),
                "functional_count": sum(1 for value in status.values() if value == 1),
                "new_dependency_failures": "",
                "new_overload_failures": "",
            }
        )

        if step == max_steps:
            break

        for node in nodes:
            if status[node.name] == 0:
                continue

            dependencies = [
                edge.source
                for edge in edges
                if edge.target == node.name and edge.edge_type == "dependency"
            ]

            if dependencies:
                failed_dependencies = sum(1 for dep in dependencies if status.get(dep, 0) == 0)
                failed_fraction = failed_dependencies / len(dependencies)

                if failed_fraction > dependency_tolerance:
                    dependency_failures.add(node.name)

        for failed in failed_nodes:
            neighbors = [
                edge.target
                for edge in edges
                if edge.source == failed and status.get(edge.target, 0) == 1
            ]

            if neighbors:
                redistributed_load = load[failed] / len(neighbors)
                for neighbor in neighbors:
                    load[neighbor] += redistributed_load

        for node in nodes:
            if status[node.name] == 0:
                continue

            load_ratio = load[node.name] / max(node.capacity, 1e-9)
            if load_ratio > overload_threshold:
                overload_failures.add(node.name)

        new_failures = dependency_failures | overload_failures

        rows[-1]["new_dependency_failures"] = "|".join(sorted(dependency_failures))
        rows[-1]["new_overload_failures"] = "|".join(sorted(overload_failures))

        if not new_failures:
            continue

        for failed in new_failures:
            status[failed] = 0

    return rows


def summarize(rows: list[dict[str, object]]) -> dict[str, object]:
    final = rows[-1]
    max_failed_count = max(int(row["failed_count"]) for row in rows)
    max_weighted_service_loss = max(float(row["weighted_service_loss"]) for row in rows)
    cascade_depth = max(
        int(row["step"])
        for row in rows
        if int(row["failed_count"]) == max_failed_count
    )

    dependency_failure_events = sum(
        1 for row in rows if str(row.get("new_dependency_failures", "")) != ""
    )
    overload_failure_events = sum(
        1 for row in rows if str(row.get("new_overload_failures", "")) != ""
    )

    return {
        "scenario": final["scenario"],
        "final_failed_count": final["failed_count"],
        "max_failed_count": max_failed_count,
        "final_weighted_service_loss": final["weighted_service_loss"],
        "max_weighted_service_loss": round(max_weighted_service_loss, 6),
        "cascade_depth": cascade_depth,
        "dependency_failure_events": dependency_failure_events,
        "overload_failure_events": overload_failure_events,
    }


def main() -> None:
    nodes = read_nodes(DATA / "infrastructure_nodes.csv")
    edges = read_edges(DATA / "infrastructure_edges.csv")
    scenarios = read_scenarios(DATA / "shock_scenarios.csv")
    assumptions = read_csv_dicts(DATA / "model_assumptions.csv")
    diagnostics = read_csv_dicts(DATA / "diagnostic_definitions.csv")

    all_runs: list[dict[str, object]] = []
    summary_rows: list[dict[str, object]] = []

    for scenario in scenarios:
        rows = simulate_cascade(scenario=scenario, nodes=nodes, edges=edges)
        all_runs.extend(rows)
        summary_rows.append(summarize(rows))

    validation_rows = [
        {"check": "nodes_created", "passed": len(nodes) > 0, "value": len(nodes)},
        {"check": "edges_created", "passed": len(edges) > 0, "value": len(edges)},
        {"check": "scenarios_created", "passed": len(scenarios) > 0, "value": len(scenarios)},
        {"check": "scenario_runs_created", "passed": len(all_runs) > 0, "value": len(all_runs)},
        {
            "check": "weighted_service_loss_nonnegative",
            "passed": all(float(row["weighted_service_loss"]) >= 0 for row in all_runs),
            "value": "all_weighted_service_loss_values_checked",
        },
        {
            "check": "failed_counts_nonnegative",
            "passed": all(int(row["failed_count"]) >= 0 for row in all_runs),
            "value": "all_failed_counts_checked",
        },
        {"check": "summary_created", "passed": len(summary_rows) == len(scenarios), "value": len(summary_rows)},
    ]

    write_csv(TABLES / "python_infrastructure_nodes.csv", node_rows(nodes))
    write_csv(TABLES / "python_infrastructure_edges.csv", edge_rows(edges))
    write_csv(TABLES / "python_shock_scenarios.csv", scenario_rows(scenarios))
    write_csv(TABLES / "python_shock_propagation_timeseries.csv", all_runs)
    write_csv(TABLES / "python_shock_propagation_summary.csv", summary_rows)
    write_csv(TABLES / "python_model_assumptions.csv", assumptions)
    write_csv(TABLES / "python_diagnostic_definitions.csv", diagnostics)
    write_csv(TABLES / "python_shock_propagation_validation_checks.csv", validation_rows)

    print("Infrastructure shock propagation workflow complete.")
    print(TABLES / "python_shock_propagation_summary.csv")


if __name__ == "__main__":
    main()
