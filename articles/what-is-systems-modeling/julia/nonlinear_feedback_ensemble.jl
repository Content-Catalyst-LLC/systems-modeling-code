# nonlinear_feedback_ensemble.jl
# Nonlinear feedback ensemble for systems modeling.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_member(seed; n_steps=160)
    Random.seed!(seed)
    growth = rand() * 0.045 + 0.025
    loss = rand() * 0.025 + 0.010
    capacity = rand() * 40.0 + 95.0
    shock_size = -(rand() * 14.0 + 6.0)

    state = zeros(Float64, n_steps)
    pressure = zeros(Float64, n_steps)
    state[1] = 32.0
    pressure[1] = 12.0

    for t in 2:n_steps
        shock = t == 70 ? shock_size : 0.0
        nonlinear_growth = growth * state[t-1] * (1.0 - state[t-1] / capacity)
        balancing = loss * max(state[t-1] - 75.0, 0.0)
        pressure_feedback = 0.018 * max(state[t-1] - 80.0, 0.0) - 0.035 * pressure[t-1]

        state[t] = max(0.0, state[t-1] + nonlinear_growth - balancing - 0.012 * pressure[t-1] + shock + randn() * 0.20)
        pressure[t] = max(0.0, pressure[t-1] + pressure_feedback + randn() * 0.05)
    end

    return (
        seed=seed,
        growth=growth,
        loss=loss,
        capacity=capacity,
        shock_size=shock_size,
        minimum_state=minimum(state),
        final_state=state[end],
        maximum_pressure=maximum(pressure),
        volatility=std(state)
    )
end

rows = [simulate_member(9000 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_nonlinear_feedback_ensemble.csv")
header = ["seed" "growth" "loss" "capacity" "shock_size" "minimum_state" "final_state" "maximum_pressure" "volatility"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.growth for row in rows],
    [row.loss for row in rows],
    [row.capacity for row in rows],
    [row.shock_size for row in rows],
    [row.minimum_state for row in rows],
    [row.final_state for row in rows],
    [row.maximum_pressure for row in rows],
    [row.volatility for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia nonlinear feedback ensemble complete.")
println("Median final state: ", median([row.final_state for row in rows]))
println(path)
