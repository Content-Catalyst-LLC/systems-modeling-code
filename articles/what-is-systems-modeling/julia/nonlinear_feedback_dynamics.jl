# nonlinear_feedback_dynamics.jl
# Nonlinear feedback dynamics example for systems modeling.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_feedback(; n_steps=160, seed=2026, r=0.055, k=0.021, capacity=120.0, shock_time=70, shock_size=-16.0)
    Random.seed!(seed)
    state = zeros(Float64, n_steps)
    pressure = zeros(Float64, n_steps)
    state[1] = 32.0
    pressure[1] = 12.0

    for t in 2:n_steps
        nonlinear_growth = r * state[t-1] * (1.0 - state[t-1] / capacity)
        balancing = k * max(state[t-1] - 75.0, 0.0)
        shock = t == shock_time ? shock_size : 0.0
        pressure_feedback = 0.018 * max(state[t-1] - 80.0, 0.0) - 0.035 * pressure[t-1]

        state[t] = max(0.0, state[t-1] + nonlinear_growth - balancing - 0.012 * pressure[t-1] + shock + randn() * 0.25)
        pressure[t] = max(0.0, pressure[t-1] + pressure_feedback + randn() * 0.05)
    end

    return state, pressure
end

state, pressure = simulate_feedback()

output = hcat(collect(1:length(state)), state, pressure)
writedlm(joinpath(tables_dir, "julia_nonlinear_feedback_dynamics.csv"), ["time" "state" "pressure"], ',')
open(joinpath(tables_dir, "julia_nonlinear_feedback_dynamics.csv"), "a") do io
    writedlm(io, output, ',')
end

println("Julia nonlinear feedback dynamics complete.")
println(joinpath(tables_dir, "julia_nonlinear_feedback_dynamics.csv"))
