using Statistics
using DelimitedFiles
article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function shock_at(time, multiplier)
    values = Dict(25 => 1.5, 55 => 1.7, 90 => 2.0, 125 => 2.2, 155 => 2.5)
    return get(values, time, 0.0) * multiplier
end

function simulate(name, initial_capacity, erosion, learning_gain, shock_multiplier, capacity_floor; steps=180)
    state = 0.0
    capacity = initial_capacity
    rows = []
    for time in 1:steps
        shock = shock_at(time, shock_multiplier)
        if time > 1
            capacity = max(capacity_floor, capacity - erosion + learning_gain * max(0.0, 1.0 - abs(state)))
            state = state - capacity * state + shock
        end
        performance = max(0.0, 1.0 - abs(state) / 4.0)
        push!(rows, (name, time, state, abs(state), capacity, shock, performance, 1.0 - performance))
    end
    return rows
end

scenarios = [
    ("baseline_adaptation", 0.22, 0.0009, 0.0007, 1.00, 0.03),
    ("weakened_capacity", 0.16, 0.0014, 0.0003, 1.00, 0.03),
    ("compound_stress", 0.18, 0.0012, 0.0004, 1.35, 0.03),
    ("learning_investment", 0.24, 0.0006, 0.0012, 1.00, 0.03),
    ("high_redundancy", 0.27, 0.0008, 0.0008, 0.85, 0.05),
    ("fragile_efficiency", 0.14, 0.0018, 0.0002, 1.20, 0.02)
]

summary_rows = []
for s in scenarios
    rows = simulate(s...)
    states = [row[3] for row in rows]
    capacities = [row[5] for row in rows]
    performances = [row[7] for row in rows]
    losses = [row[8] for row in rows]
    push!(summary_rows, (s[1], states[end], maximum(abs.(states)), minimum(performances), mean(performances), capacities[1], capacities[end], capacities[end] - capacities[1], sum(losses)))
end

path = joinpath(tables_dir, "julia_resilience_adaptive_system_summary.csv")
header = ["scenario" "final_state" "maximum_abs_state" "minimum_performance" "mean_performance" "initial_adaptive_capacity" "final_adaptive_capacity" "adaptive_capacity_change" "cumulative_performance_loss"]
writedlm(path, header, ',')
matrix = hcat([row[1] for row in summary_rows], [row[2] for row in summary_rows], [row[3] for row in summary_rows], [row[4] for row in summary_rows], [row[5] for row in summary_rows], [row[6] for row in summary_rows], [row[7] for row in summary_rows], [row[8] for row in summary_rows], [row[9] for row in summary_rows])
open(path, "a") do io
    writedlm(io, matrix, ',')
end
println("Julia resilience adaptive capacity ensemble complete.")
println(path)
