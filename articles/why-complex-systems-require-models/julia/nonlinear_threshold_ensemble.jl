# nonlinear_threshold_ensemble.jl
# Julia ensemble for nonlinear threshold and delayed-feedback dynamics.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function clamp(value, low, high)
    return max(low, min(high, value))
end

function simulate_member(seed; periods=160)
    Random.seed!(seed)

    growth_rate = rand() * 0.055 + 0.055
    balancing_strength = rand() * 0.055 + 0.025
    target = rand() * 25.0 + 42.0
    delay = rand(2:16)
    threshold = rand() * 35.0 + 70.0
    threshold_correction = rand() * 0.075 + 0.020

    state = [12.0]

    for time in 0:periods
        current = state[end]
        delayed_index = max(1, length(state) - delay)
        delayed_state = state[delayed_index]

        inflow = growth_rate * current
        balancing_outflow = balancing_strength * max(delayed_state - target, 0.0)
        threshold_penalty = current >= threshold ? threshold_correction * (current - threshold) : 0.0
        shock = time == 70 ? -10.0 : 0.0

        next_state = clamp(current + inflow - balancing_outflow - threshold_penalty + shock, 0.0, 250.0)
        push!(state, next_state)
    end

    return (
        seed=seed,
        growth_rate=growth_rate,
        balancing_strength=balancing_strength,
        target=target,
        delay=delay,
        threshold=threshold,
        threshold_correction=threshold_correction,
        minimum_state=minimum(state),
        maximum_state=maximum(state),
        final_state=state[end],
        average_state=mean(state)
    )
end

rows = [simulate_member(9100 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_nonlinear_threshold_ensemble.csv")
header = ["seed" "growth_rate" "balancing_strength" "target" "delay" "threshold" "threshold_correction" "minimum_state" "maximum_state" "final_state" "average_state"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.growth_rate for row in rows],
    [row.balancing_strength for row in rows],
    [row.target for row in rows],
    [row.delay for row in rows],
    [row.threshold for row in rows],
    [row.threshold_correction for row in rows],
    [row.minimum_state for row in rows],
    [row.maximum_state for row in rows],
    [row.final_state for row in rows],
    [row.average_state for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia nonlinear threshold ensemble complete.")
println("Median final state: ", median([row.final_state for row in rows]))
println(path)
