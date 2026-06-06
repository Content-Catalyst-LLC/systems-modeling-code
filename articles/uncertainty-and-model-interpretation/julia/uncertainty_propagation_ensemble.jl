# uncertainty_propagation_ensemble.jl
# Julia ensemble for uncertainty propagation.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_system(growth_rate, carrying_capacity, extraction_pressure, shock_intensity, shock_time; steps=80)
    state = zeros(Float64, steps)
    state[1] = 10.0

    for t in 2:steps
        shock_effect = t == shock_time ? shock_intensity : 0.0
        previous = state[t - 1]

        state[t] = max(
            0.0,
            previous +
            growth_rate * previous * (1.0 - previous / carrying_capacity) -
            extraction_pressure * previous -
            shock_effect
        )
    end

    return state
end

Random.seed!(60606)
rows = []

for run_id in 1:500
    growth_rate = 0.045 + rand() * (0.120 - 0.045)
    carrying_capacity = 70.0 + rand() * 75.0
    extraction_pressure = 0.005 + rand() * (0.050 - 0.005)
    shock_intensity = rand() * 20.0
    shock_time = rand(30:55)

    state = simulate_system(growth_rate, carrying_capacity, extraction_pressure, shock_intensity, shock_time)

    push!(rows, (
        run_id,
        growth_rate,
        carrying_capacity,
        extraction_pressure,
        shock_intensity,
        shock_time,
        state[end],
        maximum(state),
        minimum(state),
        mean(state)
    ))
end

path = joinpath(tables_dir, "julia_uncertainty_propagation_ensemble.csv")
header = ["run_id" "growth_rate" "carrying_capacity" "extraction_pressure" "shock_intensity" "shock_time" "final_state" "maximum_state" "minimum_state" "mean_state"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows],
    [row[6] for row in rows],
    [row[7] for row in rows],
    [row[8] for row in rows],
    [row[9] for row in rows],
    [row[10] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia uncertainty propagation ensemble complete.")
println("Median final state: ", median([row[7] for row in rows]))
println(path)
