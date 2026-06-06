#!/usr/bin/env python3
"""
Agent-based modeling workflow.

Dependency-light Schelling-style ABM demonstrating:

1. Heterogeneous agent types
2. Local neighborhood evaluation
3. Movement to empty cells
4. Emergent clustering
5. Scenario comparison
6. Validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import csv
import random
from statistics import mean


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


@dataclass(frozen=True)
class Scenario:
    name: str
    grid_size: int
    empty_share: float
    type_a_share: float
    satisfaction_threshold: float
    max_steps: int
    seed: int


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


def load_scenarios() -> list[Scenario]:
    rows = read_csv(DATA / "abm_schelling_scenarios.csv")
    return [
        Scenario(
            name=row["scenario"],
            grid_size=int(row["grid_size"]),
            empty_share=float(row["empty_share"]),
            type_a_share=float(row["type_a_share"]),
            satisfaction_threshold=float(row["satisfaction_threshold"]),
            max_steps=int(row["max_steps"]),
            seed=int(row["seed"]),
        )
        for row in rows
    ]


def initialize_grid(scenario: Scenario) -> list[list[int]]:
    rng = random.Random(scenario.seed)
    grid: list[list[int]] = []

    for _ in range(scenario.grid_size):
        row = []
        for _ in range(scenario.grid_size):
            draw = rng.random()
            if draw < scenario.empty_share:
                row.append(-1)
            elif draw < scenario.empty_share + scenario.type_a_share:
                row.append(0)
            else:
                row.append(1)
        grid.append(row)

    return grid


def neighbors(grid: list[list[int]], row: int, col: int) -> list[int]:
    n = len(grid)
    values: list[int] = []

    for dr in [-1, 0, 1]:
        for dc in [-1, 0, 1]:
            if dr == 0 and dc == 0:
                continue
            rr = row + dr
            cc = col + dc
            if 0 <= rr < n and 0 <= cc < n and grid[rr][cc] != -1:
                values.append(grid[rr][cc])

    return values


def same_share(grid: list[list[int]], row: int, col: int) -> float:
    agent_type = grid[row][col]
    if agent_type == -1:
        return 1.0

    local = neighbors(grid, row, col)
    if not local:
        return 1.0

    return sum(1 for value in local if value == agent_type) / len(local)


def empty_cells(grid: list[list[int]]) -> list[tuple[int, int]]:
    return [
        (row, col)
        for row in range(len(grid))
        for col in range(len(grid[row]))
        if grid[row][col] == -1
    ]


def occupied_cells(grid: list[list[int]]) -> list[tuple[int, int]]:
    return [
        (row, col)
        for row in range(len(grid))
        for col in range(len(grid[row]))
        if grid[row][col] != -1
    ]


def clustering_index(grid: list[list[int]]) -> float:
    shares = [same_share(grid, row, col) for row, col in occupied_cells(grid)]
    return mean(shares) if shares else 0.0


def simulate(scenario: Scenario) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    rng = random.Random(scenario.seed + 1000)
    grid = initialize_grid(scenario)

    trajectory: list[dict[str, object]] = []

    for step in range(scenario.max_steps + 1):
        occupied = occupied_cells(grid)
        unhappy = [
            (row, col)
            for row, col in occupied
            if same_share(grid, row, col) < scenario.satisfaction_threshold
        ]

        satisfied_share = 1.0 - (len(unhappy) / len(occupied) if occupied else 0.0)
        trajectory.append({
            "scenario": scenario.name,
            "step": step,
            "occupied_agents": len(occupied),
            "unhappy_agents": len(unhappy),
            "satisfied_share": round(satisfied_share, 6),
            "clustering_index": round(clustering_index(grid), 6),
            "empty_cells": len(empty_cells(grid)),
        })

        if not unhappy:
            break

        vacancies = empty_cells(grid)
        rng.shuffle(unhappy)
        rng.shuffle(vacancies)

        for row, col in unhappy:
            if not vacancies:
                break
            new_row, new_col = vacancies.pop()
            grid[new_row][new_col] = grid[row][col]
            grid[row][col] = -1
            vacancies.append((row, col))

    final_grid_rows: list[dict[str, object]] = []
    for row in range(len(grid)):
        for col in range(len(grid[row])):
            final_grid_rows.append({
                "scenario": scenario.name,
                "row": row,
                "col": col,
                "agent_type": grid[row][col],
            })

    return trajectory, final_grid_rows


def summarize(trajectory: list[dict[str, object]]) -> dict[str, object]:
    first = trajectory[0]
    last = trajectory[-1]

    return {
        "scenario": last["scenario"],
        "steps_completed": last["step"],
        "initial_satisfied_share": first["satisfied_share"],
        "final_satisfied_share": last["satisfied_share"],
        "initial_clustering_index": first["clustering_index"],
        "final_clustering_index": last["clustering_index"],
        "final_unhappy_agents": last["unhappy_agents"],
        "diagnostic": (
            "local preferences generated stronger clustering"
            if float(last["clustering_index"]) > float(first["clustering_index"])
            else "limited clustering change under current assumptions"
        ),
    }


def validate(trajectory: list[dict[str, object]]) -> list[dict[str, object]]:
    diagnostics: list[dict[str, object]] = []

    for row in trajectory:
        for metric in ["satisfied_share", "clustering_index"]:
            value = float(row[metric])
            diagnostics.append({
                "scenario": row["scenario"],
                "step": row["step"],
                "metric": metric,
                "value": value,
                "target_low": 0.0,
                "target_high": 1.0,
                "passed": 0.0 <= value <= 1.0,
            })

    return diagnostics


def main() -> None:
    scenarios = load_scenarios()

    all_trajectories: list[dict[str, object]] = []
    all_grids: list[dict[str, object]] = []
    summaries: list[dict[str, object]] = []
    validations: list[dict[str, object]] = []

    for scenario in scenarios:
        trajectory, grid_rows = simulate(scenario)
        all_trajectories.extend(trajectory)
        all_grids.extend(grid_rows)
        summaries.append(summarize(trajectory))
        validations.extend(validate(trajectory))

    write_csv(TABLES / "python_agent_rule_inventory.csv", read_csv(DATA / "agent_rule_inventory.csv"))
    write_csv(TABLES / "python_abm_schelling_trajectory.csv", all_trajectories)
    write_csv(TABLES / "python_abm_schelling_final_grid.csv", all_grids)
    write_csv(TABLES / "python_abm_schelling_summary.csv", summaries)
    write_csv(TABLES / "python_abm_schelling_validation.csv", validations)

    print("Agent-based modeling workflow complete.")
    print(TABLES / "python_abm_schelling_summary.csv")


if __name__ == "__main__":
    main()
