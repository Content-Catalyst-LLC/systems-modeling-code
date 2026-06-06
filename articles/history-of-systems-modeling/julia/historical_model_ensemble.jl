# historical_model_ensemble.jl
# Julia ensemble for historical systems-modeling structures.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function clamp(value, low, high)
    return max(low, min(high, value))
end

function simulate_member(seed; n_steps=160)
    Random.seed!(seed)

    growth_rate = rand() * 0.060 + 0.055
    carrying_capacity = rand() * 45.0 + 55.0
    balancing_strength = rand() * 0.070 + 0.025
    target = rand() * 25.0 + 45.0
    delay = rand(2:16)
    shock_size = -(rand() * 12.0 + 4.0)

    exponential = [10.0]
    logistic = [10.0]
    delayed_feedback = [10.0]

    for time in 0:n_steps
        current_exponential = exponential[end]
        current_logistic = logistic[end]
        current_delayed = delayed_feedback[end]

        delayed_index = max(1, length(delayed_feedback) - delay)
        delayed_state = delayed_feedback[delayed_index]

        push!(exponential, clamp(current_exponential + growth_rate * current_exponential, 0.0, 250.0))
        push!(logistic, clamp(current_logistic + growth_rate * current_logistic * (1.0 - current_logistic / carrying_capacity), 0.0, 250.0))

        inflow = growth_rate * current_delayed
        outflow = balancing_strength * max(delayed_state - target, 0.0)
        shock = time == 90 ? shock_size : 0.0

        push!(delayed_feedback, clamp(current_delayed + inflow - outflow + shock, 0.0, 250.0))
    end

    return (
        seed=seed,
        growth_rate=growth_rate,
        carrying_capacity=carrying_capacity,
        balancing_strength=balancing_strength,
        target=target,
        delay=delay,
        shock_size=shock_size,
        final_exponential=exponential[end],
        final_logistic=logistic[end],
        final_delayed_feedback=delayed_feedback[end],
        maximum_delayed_feedback=maximum(delayed_feedback),
        average_delayed_feedback=mean(delayed_feedback)
    )
end

rows = [simulate_member(8400 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_historical_model_ensemble.csv")
header = ["seed" "growth_rate" "carrying_capacity" "balancing_strength" "target" "delay" "shock_size" "final_exponential" "final_logistic" "final_delayed_feedback" "maximum_delayed_feedback" "average_delayed_feedback"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.growth_rate for row in rows],
    [row.carrying_capacity for row in rows],
    [row.balancing_strength for row in rows],
    [row.target for row in rows],
    [row.delay for row in rows],
    [row.shock_size for row in rows],
    [row.final_exponential for row in rows],
    [row.final_logistic for row in rows],
    [row.final_delayed_feedback for row in rows],
    [row.maximum_delayed_feedback for row in rows],
    [row.average_delayed_feedback for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia historical model ensemble complete.")
println("Median delayed-feedback peak: ", median([row.maximum_delayed_feedback for row in rows]))
println(path)
