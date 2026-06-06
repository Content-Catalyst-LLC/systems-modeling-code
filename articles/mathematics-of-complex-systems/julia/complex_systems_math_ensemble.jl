# complex_systems_math_ensemble.jl
# Julia nonlinear dynamics and network diffusion workflow.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function logistic_map(r, initial_state, steps)
    values = zeros(Float64, steps)
    values[1] = initial_state

    for i in 2:steps
        values[i] = r * values[i - 1] * (1.0 - values[i - 1])
    end

    return values
end

function entropy(values; bins=10)
    low = minimum(values)
    high = maximum(values)

    if high == low
        return 0.0
    end

    counts = zeros(Int64, bins)

    for value in values
        index = floor(Int, (value - low) / (high - low) * bins) + 1
        if index > bins
            index = bins
        end
        counts[index] += 1
    end

    total = sum(counts)
    result = 0.0

    for count in counts
        if count > 0
            p = count / total
            result -= p * log(p)
        end
    end

    return result
end

steps = 120
trajectory_1 = logistic_map(3.9, 0.4000, steps)
trajectory_2 = logistic_map(3.9, 0.4001, steps)

rows = []

for time in 1:steps
    push!(rows, (
        time,
        trajectory_1[time],
        trajectory_2[time],
        abs(trajectory_1[time] - trajectory_2[time])
    ))
end

path = joinpath(tables_dir, "julia_logistic_sensitivity.csv")
header = ["time" "trajectory_1" "trajectory_2" "absolute_difference"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

summary_path = joinpath(tables_dir, "julia_complexity_math_summary.csv")
summary_header = ["metric" "value"]
summary_matrix = [
    "maximum_absolute_difference" maximum([row[4] for row in rows]);
    "mean_absolute_difference" mean([row[4] for row in rows]);
    "trajectory_entropy" entropy(trajectory_1)
]
writedlm(summary_path, summary_header, ',')
open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia complex systems mathematics ensemble complete.")
println(path)
println(summary_path)
