"""
Systems Modeling:
Shock propagation in an interconnected network.

Educational example only.
"""

from __future__ import annotations

import numpy as np
import pandas as pd


COMPONENTS = ["infrastructure", "energy", "water", "health", "governance"]


def load_influence_matrix(path: str) -> np.ndarray:
    """Load influence matrix from edge list."""
    edges = pd.read_csv(path)
    index = {component: i for i, component in enumerate(COMPONENTS)}
    matrix = np.zeros((len(COMPONENTS), len(COMPONENTS)))

    for _, row in edges.iterrows():
        from_idx = index[row["from_component"]]
        to_idx = index[row["to_component"]]
        matrix[to_idx, from_idx] = row["weight"]

    return matrix


def simulate_network_shock(
    influence_matrix: np.ndarray,
    shock_time: int,
    shock_vector: np.ndarray,
    recovery_rate: float,
    steps: int
) -> pd.DataFrame:
    """Simulate propagation and recovery after a one-time shock."""
    baseline = np.full(len(COMPONENTS), 100.0)
    state = baseline.copy()

    rows = []

    for t in range(steps):
        shock = shock_vector if t == shock_time else np.zeros_like(state)

        interaction_effect = influence_matrix @ (state - baseline)
        recovery_effect = -recovery_rate * (state - baseline)

        state = state + interaction_effect + recovery_effect + shock

        row = {"time": t}
        row.update({component: state[i] for i, component in enumerate(COMPONENTS)})
        rows.append(row)

    return pd.DataFrame(rows)


def main() -> None:
    influence_matrix = load_influence_matrix("../data/network_influence_matrix.csv")
    scenarios = pd.read_csv("../data/scenario_shocks.csv")

    all_results = []
    summary_rows = []

    for _, scenario in scenarios.iterrows():
        shock_vector = np.array([
            scenario["infrastructure_shock"],
            scenario["energy_shock"],
            scenario["water_shock"],
            scenario["health_shock"],
            scenario["governance_shock"]
        ], dtype=float)

        results = simulate_network_shock(
            influence_matrix=influence_matrix,
            shock_time=int(scenario["shock_time"]),
            shock_vector=shock_vector,
            recovery_rate=float(scenario["recovery_rate"]),
            steps=int(scenario["steps"])
        )

        results["scenario_id"] = scenario["scenario_id"]
        all_results.append(results)

        for component in COMPONENTS:
            summary_rows.append({
                "scenario_id": scenario["scenario_id"],
                "component": component,
                "minimum_state": float(results[component].min()),
                "final_state": float(results[component].iloc[-1])
            })

    combined = pd.concat(all_results, ignore_index=True)
    summary = pd.DataFrame(summary_rows)

    print(summary)

    combined.to_csv("../outputs/python_network_shock_results.csv", index=False)
    summary.to_csv("../outputs/python_network_shock_summary.csv", index=False)


if __name__ == "__main__":
    main()
