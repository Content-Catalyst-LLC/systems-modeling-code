"""
Systems Modeling:
Stock-and-flow simulation with reinforcing and balancing feedback.

Educational example only.
"""

from __future__ import annotations

import pandas as pd


def simulate_interacting_stocks(
    initial_stock_a: float,
    initial_stock_b: float,
    growth_a_rate: float,
    growth_b_rate: float,
    b_to_a_pressure: float,
    a_to_b_support: float,
    b_balancing_rate: float,
    target_b: float,
    steps: int
) -> pd.DataFrame:
    """Simulate two interacting stocks with reinforcing and balancing feedback."""
    stock_a = [initial_stock_a]
    stock_b = [initial_stock_b]

    for _ in range(1, steps):
        reinforcing_a = growth_a_rate * stock_a[-1]
        pressure_from_b = -b_to_a_pressure * stock_b[-1]

        reinforcing_b = growth_b_rate * stock_b[-1]
        support_from_a = a_to_b_support * stock_a[-1]
        balancing_b = b_balancing_rate * max(stock_b[-1] - target_b, 0.0)

        stock_a.append(stock_a[-1] + reinforcing_a + pressure_from_b)
        stock_b.append(stock_b[-1] + reinforcing_b + support_from_a - balancing_b)

    return pd.DataFrame({
        "time": range(steps),
        "stock_a": stock_a,
        "stock_b": stock_b
    })


def main() -> None:
    parameters = pd.read_csv("../data/stock_flow_parameters.csv")

    all_results = []
    summary_rows = []

    for _, row in parameters.iterrows():
        results = simulate_interacting_stocks(
            initial_stock_a=float(row["initial_stock_a"]),
            initial_stock_b=float(row["initial_stock_b"]),
            growth_a_rate=float(row["growth_a_rate"]),
            growth_b_rate=float(row["growth_b_rate"]),
            b_to_a_pressure=float(row["b_to_a_pressure"]),
            a_to_b_support=float(row["a_to_b_support"]),
            b_balancing_rate=float(row["b_balancing_rate"]),
            target_b=float(row["target_b"]),
            steps=int(row["steps"])
        )

        results["scenario_id"] = row["scenario_id"]
        all_results.append(results)

        summary_rows.append({
            "scenario_id": row["scenario_id"],
            "final_stock_a": float(results["stock_a"].iloc[-1]),
            "final_stock_b": float(results["stock_b"].iloc[-1]),
            "max_stock_a": float(results["stock_a"].max()),
            "max_stock_b": float(results["stock_b"].max()),
            "time_of_max_stock_b": int(results.loc[results["stock_b"].idxmax(), "time"])
        })

    combined = pd.concat(all_results, ignore_index=True)
    summary = pd.DataFrame(summary_rows)

    print(summary)

    combined.to_csv("../outputs/python_stock_flow_feedback_results.csv", index=False)
    summary.to_csv("../outputs/python_stock_flow_feedback_summary.csv", index=False)


if __name__ == "__main__":
    main()
