#!/usr/bin/env python3
"""
Professional systems modeling workflow.

This standard-library Python module implements:

1. Weighted network shock propagation
2. Scenario comparison
3. Node vulnerability diagnostics
4. Coupled stock-flow ensemble simulation
5. One-at-a-time sensitivity analysis
6. Plausibility validation against synthetic targets
7. Reproducible CSV outputs

The data are synthetic. The purpose is workflow demonstration.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import csv
import math
import random
from statistics import mean, median


ARTICLE_ROOT = Path(__file__).resolve().parents[1]
DATA = ARTICLE_ROOT / "data"
TABLES = ARTICLE_ROOT / "outputs" / "tables"


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError(f"No rows to write for {path}")
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def clamp(value: float, low: float = 0.0, high: float = 1.25) -> float:
    return max(low, min(high, value))


@dataclass(frozen=True)
class NetworkScenario:
    name: str
    coupling_strength: float
    recovery_rate: float
    redundancy: float
    shock_size: float
    shock_time: int
    noise_sd: float
    seed: int = 2026
    n_steps: int = 140


def load_network_scenarios() -> list[NetworkScenario]:
    rows = read_csv(DATA / "scenario_parameters.csv")
    return [
        NetworkScenario(
            name=row["scenario"],
            coupling_strength=float(row["coupling_strength"]),
            recovery_rate=float(row["recovery_rate"]),
            redundancy=float(row["redundancy"]),
            shock_size=float(row["shock_size"]),
            shock_time=int(row["shock_time"]),
            noise_sd=float(row["noise_sd"]),
        )
        for row in rows
    ]


def load_dependency_edges() -> tuple[list[str], dict[tuple[str, str], float]]:
    rows = read_csv(DATA / "dependency_edges.csv")
    nodes = sorted(set([row["from_node"] for row in rows] + [row["to_node"] for row in rows]))
    edges = {(row["from_node"], row["to_node"]): float(row["dependency_weight"]) for row in rows}
    return nodes, edges


def normalize_inbound_weights(nodes: list[str], edges: dict[tuple[str, str], float], coupling_strength: float, redundancy: float) -> dict[tuple[str, str], float]:
    inbound_total = {node: 0.0 for node in nodes}
    for (_, target), weight in edges.items():
        inbound_total[target] += weight

    normalized: dict[tuple[str, str], float] = {}
    for (source, target), weight in edges.items():
        denominator = inbound_total[target] if inbound_total[target] else 1.0
        normalized[(source, target)] = (weight / denominator) * coupling_strength * (1.0 - redundancy)

    return normalized


def simulate_network_scenario(scenario: NetworkScenario) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    nodes, raw_edges = load_dependency_edges()
    edges = normalize_inbound_weights(nodes, raw_edges, scenario.coupling_strength, scenario.redundancy)
    rng = random.Random(scenario.seed)

    state = {node: 1.0 for node in nodes}
    rows: list[dict[str, object]] = []
    edge_rows: list[dict[str, object]] = []

    for (source, target), weight in edges.items():
        edge_rows.append({
            "scenario": scenario.name,
            "from_node": source,
            "to_node": target,
            "effective_dependency_weight": round(weight, 6),
        })

    shock_node = nodes[min(3, len(nodes) - 1)]

    for time in range(scenario.n_steps + 1):
        system_performance = mean(state.values())
        worst_node_state = min(state.values())

        for node in nodes:
            rows.append({
                "scenario": scenario.name,
                "time": time,
                "node": node,
                "state": round(state[node], 6),
                "system_performance": round(system_performance, 6),
                "worst_node_state": round(worst_node_state, 6),
                "system_performance_loss": round(1.0 - system_performance, 6),
            })

        previous = dict(state)
        next_state = dict(state)

        for node in nodes:
            dependency_loss = 0.0
            for (source, target), weight in edges.items():
                if target == node:
                    dependency_loss += weight * (previous[source] - 1.0)

            recovery = scenario.recovery_rate * (1.0 - previous[node])
            shock = scenario.shock_size if time == scenario.shock_time and node == shock_node else 0.0
            noise = rng.gauss(0.0, scenario.noise_sd)

            next_state[node] = clamp(previous[node] + dependency_loss + recovery + shock + noise)

        state = next_state

    return rows, edge_rows


def summarize_network(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []

    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        subset = [row for row in rows if row["scenario"] == scenario]
        by_time: dict[int, list[dict[str, object]]] = {}

        for row in subset:
            by_time.setdefault(int(row["time"]), []).append(row)

        performance_by_time = []
        worst_by_time = []

        for time, time_rows in sorted(by_time.items()):
            performance_by_time.append((time, mean(float(row["state"]) for row in time_rows)))
            worst_by_time.append(min(float(row["state"]) for row in time_rows))

        values = [value for _, value in performance_by_time]
        minimum = min(values)
        final = values[-1]
        time_to_min = performance_by_time[values.index(minimum)][0]

        output.append({
            "scenario": scenario,
            "minimum_system_performance": round(minimum, 6),
            "maximum_system_loss": round(1.0 - minimum, 6),
            "final_system_performance": round(final, 6),
            "final_unrecovered_system_loss": round(1.0 - final, 6),
            "worst_node_state_over_run": round(min(worst_by_time), 6),
            "time_to_minimum_system_performance": time_to_min,
        })

    return output


def summarize_node_vulnerability(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    output: list[dict[str, object]] = []
    for scenario in sorted(set(str(row["scenario"]) for row in rows)):
        scenario_rows = [row for row in rows if row["scenario"] == scenario]
        for node in sorted(set(str(row["node"]) for row in scenario_rows)):
            node_rows = [row for row in scenario_rows if row["node"] == node]
            states = [float(row["state"]) for row in node_rows]
            min_state = min(states)
            final_state = states[-1]
            output.append({
                "scenario": scenario,
                "node": node,
                "minimum_state": round(min_state, 6),
                "maximum_node_loss": round(1.0 - min_state, 6),
                "final_state": round(final_state, 6),
                "final_unrecovered_node_loss": round(1.0 - final_state, 6),
                "time_to_minimum": int(node_rows[states.index(min_state)]["time"]),
            })

    return sorted(output, key=lambda row: (str(row["scenario"]), -float(row["maximum_node_loss"])))


def stock_flow_member(seed: int, params: dict[str, float], n_steps: int = 180) -> list[dict[str, object]]:
    rng = random.Random(seed)

    stock_a = 24.0
    stock_b = 18.0
    pressure = 30.0

    rows: list[dict[str, object]] = []

    for time in range(1, n_steps + 1):
        rows.append({
            "run_id": seed,
            "time": time,
            "stock_a": round(stock_a, 6),
            "stock_b": round(stock_b, 6),
            "pressure": round(pressure, 6),
            "total_state": round(stock_a + stock_b, 6),
        })

        shock = params["shock_size"] if time == 75 else 0.0
        reinforcing_a = params["growth_a"] * stock_a
        pressure_from_b = -params["coupling_ab"] * stock_b
        reinforcing_b = params["growth_b"] * stock_b
        support_from_a = params["coupling_ba"] * stock_a
        correction_b = params["balancing_b"] * max(stock_b - params["target_b"], 0.0)
        pressure_feedback = 0.018 * max(stock_b - params["target_b"], 0.0) + 0.012 * max(stock_a - 70.0, 0.0)

        stock_a = max(0.0, stock_a + reinforcing_a + pressure_from_b + shock - 0.018 * pressure + rng.gauss(0.0, params["noise_sd"]))
        stock_b = max(0.0, stock_b + reinforcing_b + support_from_a - correction_b - 0.010 * pressure + rng.gauss(0.0, params["noise_sd"]))
        pressure = max(0.0, pressure + pressure_feedback - 0.045 * pressure + rng.gauss(0.0, params["noise_sd"] * 0.25))

    return rows


def load_stock_parameter_ranges() -> dict[str, tuple[float, float, float]]:
    rows = read_csv(DATA / "stock_flow_parameters.csv")
    return {
        row["parameter"]: (float(row["baseline"]), float(row["low"]), float(row["high"]))
        for row in rows
    }


def run_stock_flow_ensemble(n_runs: int = 300) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    ranges = load_stock_parameter_ranges()
    rng = random.Random(4400)
    all_rows: list[dict[str, object]] = []
    parameter_rows: list[dict[str, object]] = []

    for run_index in range(1, n_runs + 1):
        seed = 5000 + run_index
        params = {
            name: rng.uniform(low, high)
            for name, (_, low, high) in ranges.items()
        }
        params["run_id"] = seed
        parameter_rows.append({key: round(value, 6) if isinstance(value, float) else value for key, value in params.items()})

        rows = stock_flow_member(seed, params)
        all_rows.extend(rows)

    metrics: list[dict[str, object]] = []
    for run_id in sorted(set(int(row["run_id"]) for row in all_rows)):
        run_rows = [row for row in all_rows if int(row["run_id"]) == run_id]
        totals = [float(row["total_state"]) for row in run_rows]
        pre_shock = next(float(row["total_state"]) for row in run_rows if int(row["time"]) == 74)
        post_shock_totals = [float(row["total_state"]) for row in run_rows if int(row["time"]) >= 75]
        minimum_after_shock = min(post_shock_totals)
        final_total = totals[-1]

        params = next(row for row in parameter_rows if int(row["run_id"]) == run_id)

        metrics.append({
            "run_id": run_id,
            "pre_shock_total": round(pre_shock, 6),
            "min_total_after_shock": round(minimum_after_shock, 6),
            "final_total": round(final_total, 6),
            "recovery_ratio": round(final_total / pre_shock, 6),
            "max_drawdown": round(pre_shock - minimum_after_shock, 6),
            "volatility": round((sum((x - mean(totals)) ** 2 for x in totals) / len(totals)) ** 0.5, 6),
            **{key: params[key] for key in params if key != "run_id"},
        })

    return all_rows, parameter_rows, metrics


def pearson(x_values: list[float], y_values: list[float]) -> float:
    x_mean = mean(x_values)
    y_mean = mean(y_values)
    numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_values, y_values))
    x_denominator = math.sqrt(sum((x - x_mean) ** 2 for x in x_values))
    y_denominator = math.sqrt(sum((y - y_mean) ** 2 for y in y_values))
    if x_denominator == 0 or y_denominator == 0:
        return 0.0
    return numerator / (x_denominator * y_denominator)


def sensitivity(metrics: list[dict[str, object]]) -> list[dict[str, object]]:
    parameters = [
        "growth_a",
        "growth_b",
        "coupling_ab",
        "coupling_ba",
        "balancing_b",
        "target_b",
        "shock_size",
        "noise_sd",
    ]

    rows = []
    recovery = [float(row["recovery_ratio"]) for row in metrics]
    drawdown = [float(row["max_drawdown"]) for row in metrics]
    volatility = [float(row["volatility"]) for row in metrics]

    for parameter in parameters:
        values = [float(row[parameter]) for row in metrics]
        corr_recovery = pearson(values, recovery)
        corr_drawdown = pearson(values, drawdown)
        corr_volatility = pearson(values, volatility)

        rows.append({
            "parameter": parameter,
            "correlation_with_recovery": round(corr_recovery, 6),
            "correlation_with_drawdown": round(corr_drawdown, 6),
            "correlation_with_volatility": round(corr_volatility, 6),
            "absolute_recovery_correlation": round(abs(corr_recovery), 6),
        })

    return sorted(rows, key=lambda row: float(row["absolute_recovery_correlation"]), reverse=True)


def validate_network(summary_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {row["metric"]: row for row in read_csv(DATA / "validation_targets.csv")}
    diagnostics: list[dict[str, object]] = []

    for row in summary_rows:
        for metric in [
            "minimum_system_performance",
            "final_system_performance",
            "time_to_minimum_system_performance",
            "maximum_system_loss",
        ]:
            target = targets[metric]
            value = float(row[metric])
            low = float(target["target_low"])
            high = float(target["target_high"])
            diagnostics.append({
                "model": "network_shock_propagation",
                "scenario_or_run": row["scenario"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
                "notes": target["notes"],
            })

    return diagnostics


def validate_stock(metrics: list[dict[str, object]]) -> list[dict[str, object]]:
    targets = {row["metric"]: row for row in read_csv(DATA / "validation_targets.csv")}
    diagnostics: list[dict[str, object]] = []
    sample = metrics[:40]

    for row in sample:
        for metric in ["recovery_ratio", "max_drawdown"]:
            target = targets[metric]
            value = float(row[metric])
            low = float(target["target_low"])
            high = float(target["target_high"])
            diagnostics.append({
                "model": "stock_flow_ensemble",
                "scenario_or_run": row["run_id"],
                "metric": metric,
                "value": round(value, 6),
                "target_low": low,
                "target_high": high,
                "passed": low <= value <= high,
                "notes": target["notes"],
            })

    return diagnostics


def main() -> None:
    TABLES.mkdir(parents=True, exist_ok=True)

    all_network_rows: list[dict[str, object]] = []
    all_edge_rows: list[dict[str, object]] = []

    for scenario in load_network_scenarios():
        network_rows, edge_rows = simulate_network_scenario(scenario)
        all_network_rows.extend(network_rows)
        all_edge_rows.extend(edge_rows)

    network_summary = summarize_network(all_network_rows)
    node_vulnerability = summarize_node_vulnerability(all_network_rows)

    stock_rows, stock_parameters, stock_metrics = run_stock_flow_ensemble()
    sensitivity_rows = sensitivity(stock_metrics)

    validation_rows = validate_network(network_summary) + validate_stock(stock_metrics)

    write_csv(TABLES / "python_network_state_trajectories.csv", all_network_rows)
    write_csv(TABLES / "python_effective_dependency_edges.csv", all_edge_rows)
    write_csv(TABLES / "python_network_scenario_summary.csv", network_summary)
    write_csv(TABLES / "python_node_vulnerability_diagnostics.csv", node_vulnerability)
    write_csv(TABLES / "python_stock_flow_ensemble.csv", stock_rows)
    write_csv(TABLES / "python_stock_flow_parameters.csv", stock_parameters)
    write_csv(TABLES / "python_stock_flow_metrics.csv", stock_metrics)
    write_csv(TABLES / "python_sensitivity_summary.csv", sensitivity_rows)
    write_csv(TABLES / "python_validation_diagnostics.csv", validation_rows)

    print("Professional systems modeling workflow complete.")
    print(TABLES / "python_network_scenario_summary.csv")
    print(TABLES / "python_sensitivity_summary.csv")
    print(TABLES / "python_validation_diagnostics.csv")


if __name__ == "__main__":
    main()
