# sensitivity_uncertainty_ensemble.jl
# Julia ensemble for sensitivity uncertainty propagation.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_system(growth_rate, carrying_capacity, extraction_pressure, recovery_delay, feedback_strength, shock_intensity; steps=80)
    state_values = zeros(Float64, steps)
    state_values[1] = 10.0
    shock_time = div(steps, 2)

    for time in 2:steps
        delayed_index = max(1, time - recovery_delay)
        delayed_recovery = feedback_strength * state_values[delayed_index]
        shock_effect = time == shock_time ? shock_intensity : 0.0

        previous = state_values[time - 1]
        next_state = previous +
            growth_rate * previous * (1 - previous / carrying_capacity) -
            extraction_pressure * previous +
            delayed_recovery -
            shock_effect

        state_values[time] = max(0.0, next_state)
    end

    return (
        final_state=state_values[end],
        maximum_state=maximum(state_values),
        minimum_state=minimum(state_values),
        mean_state=mean(state_values)
    )
end

Random.seed!(60606)
rows = []

for run_id in 1:400
    growth_rate = 0.04 + rand() * (0.12 - 0.04)
    carrying_capacity = 60.0 + rand() * 80.0
    extraction_pressure = 0.005 + rand() * (0.060 - 0.005)
    recovery_delay = rand(1:12)
    feedback_strength = 0.005 + rand() * (0.050 - 0.005)
    shock_intensity = rand() * 24.0

    result = simulate_system(
        growth_rate,
        carrying_capacity,
        extraction_pressure,
        recovery_delay,
        feedback_strength,
        shock_intensity
    )

    push!(rows, (
        run_id,
        growth_rate,
        carrying_capacity,
        extraction_pressure,
        recovery_delay,
        feedback_strength,
        shock_intensity,
        result.final_state,
        result.maximum_state,
        result.minimum_state,
        result.mean_state
    ))
end

path = joinpath(tables_dir, "julia_sensitivity_uncertainty_ensemble.csv")
header = ["run_id" "growth_rate" "carrying_capacity" "extraction_pressure" "recovery_delay" "feedback_strength" "shock_intensity" "final_state" "maximum_state" "minimum_state" "mean_state"]
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
    [row[10] for row in rows],
    [row[11] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia sensitivity uncertainty ensemble complete.")
println("Median final state: ", median([row[8] for row in rows]))
println(path)
