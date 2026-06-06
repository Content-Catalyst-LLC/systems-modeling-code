# system_dynamics_ensemble.jl
# Julia ensemble for stock-flow, delay, threshold, and system dynamics diagnostics.

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

    growth_rate = rand() * 0.075 + 0.060
    balancing_strength = rand() * 0.075 + 0.020
    target = rand() * 30.0 + 50.0
    delay = rand(2:16)
    capacity = rand() * 55.0 + 75.0
    threshold = rand() * 35.0 + 70.0
    threshold_correction = rand() * 0.095 + 0.020
    shock_size = -(rand() * 14.0 + 4.0)

    stock = [20.0]

    maximum_inflow = 0.0
    maximum_outflow = 0.0
    threshold_active_periods = 0

    for time in 0:periods
        current = stock[end]
        delayed_index = max(1, length(stock) - delay)
        delayed_stock = stock[delayed_index]

        inflow = growth_rate * current * (1.0 - current / capacity)
        outflow = balancing_strength * max(delayed_stock - target, 0.0)
        threshold_penalty = current >= threshold ? threshold_correction * (current - threshold) : 0.0
        shock = time == 95 ? shock_size : 0.0

        if threshold_penalty > 0
            threshold_active_periods += 1
        end

        maximum_inflow = max(maximum_inflow, inflow)
        maximum_outflow = max(maximum_outflow, outflow)

        push!(stock, clamp(current + inflow - outflow - threshold_penalty + shock, 0.0, 250.0))
    end

    return (
        seed=seed,
        growth_rate=growth_rate,
        balancing_strength=balancing_strength,
        target=target,
        delay=delay,
        capacity=capacity,
        threshold=threshold,
        threshold_correction=threshold_correction,
        final_stock=stock[end],
        maximum_stock=maximum(stock),
        average_stock=mean(stock),
        maximum_inflow=maximum_inflow,
        maximum_outflow=maximum_outflow,
        threshold_active_periods=threshold_active_periods
    )
end

rows = [simulate_member(9300 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_system_dynamics_ensemble.csv")
header = ["seed" "growth_rate" "balancing_strength" "target" "delay" "capacity" "threshold" "threshold_correction" "final_stock" "maximum_stock" "average_stock" "maximum_inflow" "maximum_outflow" "threshold_active_periods"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.growth_rate for row in rows],
    [row.balancing_strength for row in rows],
    [row.target for row in rows],
    [row.delay for row in rows],
    [row.capacity for row in rows],
    [row.threshold for row in rows],
    [row.threshold_correction for row in rows],
    [row.final_stock for row in rows],
    [row.maximum_stock for row in rows],
    [row.average_stock for row in rows],
    [row.maximum_inflow for row in rows],
    [row.maximum_outflow for row in rows],
    [row.threshold_active_periods for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia system dynamics ensemble complete.")
println("Median maximum stock: ", median([row.maximum_stock for row in rows]))
println(path)
