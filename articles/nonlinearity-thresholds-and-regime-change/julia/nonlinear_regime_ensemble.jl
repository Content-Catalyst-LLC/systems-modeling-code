# nonlinear_regime_ensemble.jl
# Julia nonlinearity, threshold, and regime-change ensemble workflow.

using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_regime_system(name, collapse_threshold, recovery_threshold, intervention_time, pressure_growth, recovery_effort; steps=140)
    system_state = 82.0
    pressure = 20.0
    regime = "stable"
    rows = []

    for time in 1:steps
        if time > 1
            pressure += pressure_growth
            if time >= intervention_time
                pressure = max(0.0, pressure - recovery_effort)
            end

            if regime == "stable" && pressure >= collapse_threshold
                regime = "degraded"
            elseif regime == "degraded" && pressure <= recovery_threshold
                regime = "stable"
            end

            if regime == "stable"
                damage_flow = 0.05 * pressure + 0.002 * pressure^2
                recovery_flow = 2.6
            else
                damage_flow = 0.09 * pressure + 0.006 * pressure^2 + 1.8
                recovery_flow = 0.8 + 0.03 * system_state
            end

            net_flow = recovery_flow - damage_flow
            system_state = min(100.0, max(0.0, system_state + net_flow))
        else
            damage_flow = 0.0
            recovery_flow = 0.0
            net_flow = 0.0
        end

        push!(rows, (name, time, system_state, pressure, regime, collapse_threshold, recovery_threshold, collapse_threshold - recovery_threshold, damage_flow, recovery_flow, net_flow))
    end

    return rows
end

scenarios = [
    ("early_intervention", 70.0, 45.0, 55, 0.85, 1.20),
    ("late_intervention", 70.0, 45.0, 85, 0.85, 1.20),
    ("strong_recovery", 70.0, 45.0, 85, 0.85, 2.00),
    ("lower_threshold_stress", 58.0, 38.0, 70, 0.95, 1.20),
    ("hysteresis_trap", 66.0, 30.0, 88, 0.90, 1.30),
    ("rapid_prevention", 70.0, 45.0, 40, 0.85, 1.80)
]

all_rows = []
for scenario in scenarios
    append!(all_rows, simulate_regime_system(scenario...))
end

trajectory_path = joinpath(tables_dir, "julia_nonlinear_regime_trajectories.csv")
header = ["scenario" "time" "system_state" "pressure" "regime" "collapse_threshold" "recovery_threshold" "hysteresis_gap" "damage_flow" "recovery_flow" "net_flow"]
writedlm(trajectory_path, header, ',')

matrix = hcat(
    [row[1] for row in all_rows],
    [row[2] for row in all_rows],
    [row[3] for row in all_rows],
    [row[4] for row in all_rows],
    [row[5] for row in all_rows],
    [row[6] for row in all_rows],
    [row[7] for row in all_rows],
    [row[8] for row in all_rows],
    [row[9] for row in all_rows],
    [row[10] for row in all_rows],
    [row[11] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in scenarios
    name = scenario[1]
    subset = [row for row in all_rows if row[1] == name]
    states = [row[3] for row in subset]
    pressures = [row[4] for row in subset]
    regimes = [row[5] for row in subset]
    net_flows = [row[11] for row in subset]
    degraded_count = count(x -> x == "degraded", regimes)

    push!(summary_rows, (
        name,
        states[1],
        states[end],
        minimum(states),
        maximum(pressures),
        degraded_count,
        regimes[end],
        mean(net_flows)
    ))
end

summary_path = joinpath(tables_dir, "julia_nonlinear_regime_summary.csv")
summary_header = ["scenario" "initial_state" "final_state" "minimum_state" "maximum_pressure" "degraded_periods" "final_regime" "mean_net_flow"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows],
    [row[8] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia nonlinear regime ensemble complete.")
println(summary_path)
