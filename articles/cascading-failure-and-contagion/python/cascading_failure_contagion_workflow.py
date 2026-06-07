#!/usr/bin/env python3
"""
Cascading failure and contagion workflow.

Dependency-light workflow demonstrating:

1. Random network generation
2. Threshold contagion
3. Targeted initial shocks
4. Cascade size measurement
5. Scenario comparison
6. Validation checks
7. Mechanism and containment taxonomies

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


def build_random_network(node_count: int, link_probability: float, seed: int) -> dict[int, set[int]]:
    rng = random.Random(seed)
    graph: dict[int, set[int]] = {node: set() for node in range(node_count)}

    for source in range(node_count):
        for target in range(source + 1, node_count):
            if rng.random() < link_probability:
                graph[source].add(target)
                graph[target].add(source)

    return graph


def degree_map(graph: dict[int, set[int]]) -> dict[int, int]:
    return {node: len(neighbors) for node, neighbors in graph.items()}


def simulate_threshold_cascade(row: dict[str, str]) -> list[dict[str, object]]:
    scenario = row["scenario"]
    node_count = int(float(row["node_count"]))
    link_probability = float(row["link_probability"])
    threshold = float(row["threshold"])
    seed_count = int(float(row["seed_count"]))
    max_steps = int(float(row["max_steps"]))
    seed = int(float(row["seed"]))

    graph = build_random_network(node_count, link_probability, seed)
    degrees = degree_map(graph)

    seed_nodes = sorted(degrees, key=lambda node: degrees[node], reverse=True)[:seed_count]
    affected: set[int] = set(seed_nodes)

    rows: list[dict[str, object]] = []

    for step in range(max_steps + 1):
        rows.append({
            "scenario": scenario,
            "step": step,
            "node_count": node_count,
            "link_probability": round(link_probability, 6),
            "threshold": threshold,
            "seed_count": seed_count,
            "affected_count": len(affected),
            "affected_share": round(len(affected) / node_count, 6),
            "mean_degree": round(mean(degrees.values()), 6),
            "maximum_degree": max(degrees.values()) if degrees else 0,
        })

        newly_affected: set[int] = set()

        for node in graph:
            if node in affected or degrees[node] == 0:
                continue

            affected_neighbors = len(graph[node].intersection(affected))
            exposure_share = affected_neighbors / degrees[node]

            if exposure_share >= threshold:
                newly_affected.add(node)

        if not newly_affected:
            break

        affected.update(newly_affected)

    for index, cascade_row in enumerate(rows):
        if index == 0:
            cascade_row["new_failures"] = seed_count
        else:
            cascade_row["new_failures"] = (
                int(rows[index]["affected_count"]) - int(rows[index - 1]["affected_count"])
            )

    return rows


def summarize(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    summary_rows: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        final = subset[-1]
        maximum_new_failures = max(int(row["new_failures"]) for row in subset)

        summary_rows.append({
            "scenario": scenario,
            "final_affected_count": final["affected_count"],
            "final_affected_share": final["affected_share"],
            "cascade_duration": final["step"],
            "maximum_new_failures": maximum_new_failures,
            "mean_degree": final["mean_degree"],
            "maximum_degree": final["maximum_degree"],
            "diagnostic_label": (
                "systemic cascade"
                if float(final["affected_share"]) >= 0.5
                else "contained cascade"
            ),
        })

    return summary_rows


def main() -> None:
    scenario_rows = read_csv(DATA / "scenario_definitions.csv")

    all_rows: list[dict[str, object]] = []
    for scenario in scenario_rows:
        all_rows.extend(simulate_threshold_cascade(scenario))

    summary_rows = summarize(all_rows)

    validation_rows: list[dict[str, object]] = []

    for row in summary_rows:
        for metric, low, high in [
            ("final_affected_share", 0.0, 1.0),
            ("final_affected_count", 0.0, 1000000.0),
            ("cascade_duration", 0.0, 1000000.0),
            ("maximum_new_failures", 0.0, 1000000.0),
            ("mean_degree", 0.0, 1000000.0),
            ("maximum_degree", 0.0, 1000000.0),
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

    write_csv(TABLES / "python_cascade_mechanisms.csv", read_csv(DATA / "cascade_mechanisms.csv"))
    write_csv(TABLES / "python_domain_cascade_examples.csv", read_csv(DATA / "domain_cascade_examples.csv"))
    write_csv(TABLES / "python_containment_strategies.csv", read_csv(DATA / "containment_strategies.csv"))
    write_csv(TABLES / "python_scenario_definitions.csv", scenario_rows)
    write_csv(TABLES / "python_threshold_cascade_trajectories.csv", all_rows)
    write_csv(TABLES / "python_threshold_cascade_summary.csv", summary_rows)
    write_csv(TABLES / "python_threshold_cascade_validation_checks.csv", validation_rows)

    print("Cascading failure and contagion workflow complete.")
    print(TABLES / "python_threshold_cascade_summary.csv")


if __name__ == "__main__":
    main()
