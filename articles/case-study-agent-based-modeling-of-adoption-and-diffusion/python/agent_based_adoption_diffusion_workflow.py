#!/usr/bin/env python3
"""
Case study: agent-based modeling of adoption and diffusion.

Dependency-light workflow demonstrating:

1. Synthetic heterogeneous agents
2. Social network generation
3. Threshold-based adoption rules
4. Peer influence and trust
5. Scenario comparison
6. Adoption diagnostics and validation checks

All data are synthetic.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from pathlib import Path
import csv
import random
from typing import Any


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


@dataclass
class Agent:
    agent_id: int
    group: str
    threshold: float
    perceived_benefit: float
    cost_sensitivity: float
    trust: float
    resistance: float
    adopted: int = 0


@dataclass(frozen=True)
class Scenario:
    name: str
    social_weight: float
    benefit_weight: float
    intervention_weight: float
    cost_weight: float
    resistance_weight: float
    seed_strategy: str
    seed_count: int
    cost_modifier: float
    trust_modifier: float
    connection_probability: float
    bridge_probability: float
    steps: int
    description: str


@dataclass(frozen=True)
class GroupAssumption:
    group: str
    threshold_low: float
    threshold_high: float
    benefit_low: float
    benefit_high: float
    cost_low: float
    cost_high: float
    trust_low: float
    trust_high: float
    resistance_low: float
    resistance_high: float
    description: str


def read_scenarios(path: Path) -> list[Scenario]:
    scenarios: list[Scenario] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            scenarios.append(
                Scenario(
                    name=row["scenario"],
                    social_weight=float(row["social_weight"]),
                    benefit_weight=float(row["benefit_weight"]),
                    intervention_weight=float(row["intervention_weight"]),
                    cost_weight=float(row["cost_weight"]),
                    resistance_weight=float(row["resistance_weight"]),
                    seed_strategy=row["seed_strategy"],
                    seed_count=int(row["seed_count"]),
                    cost_modifier=float(row["cost_modifier"]),
                    trust_modifier=float(row["trust_modifier"]),
                    connection_probability=float(row["connection_probability"]),
                    bridge_probability=float(row["bridge_probability"]),
                    steps=int(row["steps"]),
                    description=row["description"],
                )
            )
    return scenarios


def read_group_assumptions(path: Path) -> list[GroupAssumption]:
    groups: list[GroupAssumption] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            groups.append(
                GroupAssumption(
                    group=row["group"],
                    threshold_low=float(row["threshold_low"]),
                    threshold_high=float(row["threshold_high"]),
                    benefit_low=float(row["benefit_low"]),
                    benefit_high=float(row["benefit_high"]),
                    cost_low=float(row["cost_low"]),
                    cost_high=float(row["cost_high"]),
                    trust_low=float(row["trust_low"]),
                    trust_high=float(row["trust_high"]),
                    resistance_low=float(row["resistance_low"]),
                    resistance_high=float(row["resistance_high"]),
                    description=row["description"],
                )
            )
    return groups


def read_csv_dicts(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
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


def create_agents(group_assumptions: list[GroupAssumption], n: int = 120, seed: int = 42) -> list[Agent]:
    random.seed(seed)
    group_lookup = {item.group: item for item in group_assumptions}
    group_order = [item.group for item in group_assumptions]
    agents: list[Agent] = []

    for agent_id in range(1, n + 1):
        group_name = group_order[(agent_id - 1) % len(group_order)]
        group = group_lookup[group_name]

        agents.append(
            Agent(
                agent_id=agent_id,
                group=group_name,
                threshold=round(random.uniform(group.threshold_low, group.threshold_high), 6),
                perceived_benefit=round(random.uniform(group.benefit_low, group.benefit_high), 6),
                cost_sensitivity=round(random.uniform(group.cost_low, group.cost_high), 6),
                trust=round(random.uniform(group.trust_low, group.trust_high), 6),
                resistance=round(random.uniform(group.resistance_low, group.resistance_high), 6),
            )
        )

    return agents


def create_network(
    agents: list[Agent],
    connection_probability: float,
    bridge_probability: float,
    seed: int = 1042,
) -> list[tuple[int, int]]:
    random.seed(seed)
    edges: list[tuple[int, int]] = []

    for i, source in enumerate(agents):
        for target in agents[i + 1:]:
            same_group = source.group == target.group
            probability = connection_probability if same_group else bridge_probability

            if random.random() < probability:
                edges.append((source.agent_id, target.agent_id))
                edges.append((target.agent_id, source.agent_id))

    return edges


def degree_map(edges: list[tuple[int, int]]) -> dict[int, int]:
    degrees: dict[int, int] = {}
    for source, _target in edges:
        degrees[source] = degrees.get(source, 0) + 1
    return degrees


def choose_seed_agents(agents: list[Agent], edges: list[tuple[int, int]], scenario: Scenario) -> list[int]:
    count = min(scenario.seed_count, len(agents))

    if scenario.seed_strategy == "high_degree":
        degrees = degree_map(edges)
        ranked = sorted(agents, key=lambda agent: degrees.get(agent.agent_id, 0), reverse=True)
        return [agent.agent_id for agent in ranked[:count]]

    if scenario.seed_strategy == "bridge_and_equity":
        high_barrier = [agent.agent_id for agent in agents if agent.group == "high_barrier"]
        degrees = degree_map(edges)
        ranked = sorted(agents, key=lambda agent: degrees.get(agent.agent_id, 0), reverse=True)
        seed_ids = high_barrier[: min(3, len(high_barrier))]

        for agent in ranked:
            if agent.agent_id not in seed_ids:
                seed_ids.append(agent.agent_id)
            if len(seed_ids) >= count:
                break

        return seed_ids[:count]

    random.seed(7)
    return random.sample([agent.agent_id for agent in agents], count)


def neighbor_ids(agent_id: int, edges: list[tuple[int, int]]) -> list[int]:
    return [target for source, target in edges if source == agent_id]


def neighbor_adoption_share(agent_id: int, agents_by_id: dict[int, Agent], edges: list[tuple[int, int]]) -> float:
    neighbors = neighbor_ids(agent_id, edges)
    if not neighbors:
        return 0.0
    return sum(agents_by_id[neighbor].adopted for neighbor in neighbors) / len(neighbors)


def group_adoption_summary(agents: list[Agent]) -> dict[str, float]:
    groups = sorted(set(agent.group for agent in agents))
    summary: dict[str, float] = {}

    for group in groups:
        group_agents = [agent for agent in agents if agent.group == group]
        summary[group] = sum(agent.adopted for agent in group_agents) / len(group_agents)

    return summary


def simulate(scenario: Scenario, group_assumptions: list[GroupAssumption]) -> tuple[list[dict[str, Any]], list[Agent], list[tuple[int, int]]]:
    agents = create_agents(group_assumptions)

    for agent in agents:
        agent.trust = round(min(1.0, agent.trust * scenario.trust_modifier), 6)
        agent.cost_sensitivity = round(min(1.0, agent.cost_sensitivity * scenario.cost_modifier), 6)

    edges = create_network(
        agents=agents,
        connection_probability=scenario.connection_probability,
        bridge_probability=scenario.bridge_probability,
    )

    seed_ids = choose_seed_agents(agents, edges, scenario)
    agents_by_id = {agent.agent_id: agent for agent in agents}

    for seed_id in seed_ids:
        agents_by_id[seed_id].adopted = 1

    rows: list[dict[str, Any]] = []

    for step in range(scenario.steps + 1):
        group_summary = group_adoption_summary(agents)
        adoption_values = list(group_summary.values())
        adoption_gap = max(adoption_values) - min(adoption_values)

        rows.append(
            {
                "scenario": scenario.name,
                "step": step,
                "adoption_share": round(sum(agent.adopted for agent in agents) / len(agents), 6),
                "adopter_count": sum(agent.adopted for agent in agents),
                "adoption_gap": round(adoption_gap, 6),
                "early_access_adoption": round(group_summary.get("early_access", 0.0), 6),
                "mainstream_adoption": round(group_summary.get("mainstream", 0.0), 6),
                "high_barrier_adoption": round(group_summary.get("high_barrier", 0.0), 6),
                "seed_count": len(seed_ids),
            }
        )

        if step == scenario.steps:
            break

        new_adopters: list[int] = []

        for agent in agents:
            if agent.adopted == 1:
                continue

            peer_share = neighbor_adoption_share(agent.agent_id, agents_by_id, edges)

            adoption_pressure = (
                scenario.benefit_weight * agent.perceived_benefit
                + scenario.social_weight * agent.trust * peer_share
                + scenario.intervention_weight
                - scenario.cost_weight * agent.cost_sensitivity
                - scenario.resistance_weight * agent.resistance
            )

            if adoption_pressure >= agent.threshold:
                new_adopters.append(agent.agent_id)

        for agent_id in new_adopters:
            agents_by_id[agent_id].adopted = 1

    return rows, agents, edges


def summarize(rows: list[dict[str, Any]]) -> dict[str, Any]:
    final = rows[-1]
    time_to_25 = [int(row["step"]) for row in rows if float(row["adoption_share"]) >= 0.25]
    time_to_50 = [int(row["step"]) for row in rows if float(row["adoption_share"]) >= 0.50]

    growth = [
        float(rows[index]["adoption_share"]) - float(rows[index - 1]["adoption_share"])
        for index in range(1, len(rows))
    ]
    peak_growth = max(growth) if growth else 0.0
    seed_count = max(1, int(final["seed_count"]))
    seed_efficiency = float(final["adoption_share"]) / seed_count

    return {
        "scenario": final["scenario"],
        "final_adoption_share": final["adoption_share"],
        "final_adopter_count": final["adopter_count"],
        "maximum_adoption_gap": round(max(float(row["adoption_gap"]) for row in rows), 6),
        "final_adoption_gap": final["adoption_gap"],
        "time_to_25_percent": min(time_to_25) if time_to_25 else "not_reached",
        "time_to_50_percent": min(time_to_50) if time_to_50 else "not_reached",
        "peak_growth": round(peak_growth, 6),
        "seed_efficiency": round(seed_efficiency, 6),
    }


def main() -> None:
    scenarios = read_scenarios(DATA / "diffusion_scenarios.csv")
    group_assumptions = read_group_assumptions(DATA / "agent_group_assumptions.csv")
    assumptions = read_csv_dicts(DATA / "model_assumptions.csv")
    diagnostics = read_csv_dicts(DATA / "diagnostic_definitions.csv")

    all_rows: list[dict[str, Any]] = []
    summary_rows: list[dict[str, Any]] = []
    scenario_rows: list[dict[str, Any]] = []
    group_rows: list[dict[str, Any]] = []
    final_agent_rows: list[dict[str, Any]] = []
    network_summary_rows: list[dict[str, Any]] = []

    for scenario in scenarios:
        rows, agents, edges = simulate(scenario, group_assumptions)
        all_rows.extend(rows)
        summary_rows.append(summarize(rows))
        scenario_rows.append(asdict(scenario))

        degrees = degree_map(edges)
        network_summary_rows.append(
            {
                "scenario": scenario.name,
                "agent_count": len(agents),
                "directed_edge_count": len(edges),
                "undirected_edge_count": len(edges) // 2,
                "mean_degree": round(sum(degrees.values()) / max(1, len(agents)), 6),
                "max_degree": max(degrees.values()) if degrees else 0,
            }
        )

        for agent in agents:
            agent_row = asdict(agent)
            agent_row["scenario"] = scenario.name
            agent_row["degree"] = degrees.get(agent.agent_id, 0)
            final_agent_rows.append(agent_row)

    for group in group_assumptions:
        group_rows.append(asdict(group))

    validation_rows = [
        {"check": "scenario_runs_created", "passed": len(all_rows) > 0, "value": len(all_rows)},
        {
            "check": "adoption_share_normalized",
            "passed": all(0 <= float(row["adoption_share"]) <= 1 for row in all_rows),
            "value": "all_adoption_shares_checked",
        },
        {
            "check": "adopter_count_nonnegative",
            "passed": all(int(row["adopter_count"]) >= 0 for row in all_rows),
            "value": "all_adopter_counts_checked",
        },
        {
            "check": "adoption_gap_normalized",
            "passed": all(0 <= float(row["adoption_gap"]) <= 1 for row in all_rows),
            "value": "all_adoption_gaps_checked",
        },
        {"check": "summary_created", "passed": len(summary_rows) == len(scenarios), "value": len(summary_rows)},
        {
            "check": "agent_attributes_normalized",
            "passed": all(0 <= float(row["threshold"]) <= 1 for row in final_agent_rows),
            "value": "all_thresholds_checked",
        },
    ]

    write_csv(TABLES / "python_adoption_diffusion_timeseries.csv", all_rows)
    write_csv(TABLES / "python_adoption_diffusion_summary.csv", summary_rows)
    write_csv(TABLES / "python_diffusion_scenarios.csv", scenario_rows)
    write_csv(TABLES / "python_agent_group_assumptions.csv", group_rows)
    write_csv(TABLES / "python_final_agent_states.csv", final_agent_rows)
    write_csv(TABLES / "python_network_summary.csv", network_summary_rows)
    write_csv(TABLES / "python_model_assumptions.csv", assumptions)
    write_csv(TABLES / "python_diagnostic_definitions.csv", diagnostics)
    write_csv(TABLES / "python_adoption_diffusion_validation_checks.csv", validation_rows)

    print("Agent-based adoption and diffusion workflow complete.")
    print(TABLES / "python_adoption_diffusion_summary.csv")


if __name__ == "__main__":
    main()
