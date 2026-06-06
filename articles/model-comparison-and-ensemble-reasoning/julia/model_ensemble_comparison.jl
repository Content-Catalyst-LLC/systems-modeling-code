# model_ensemble_comparison.jl
# Julia ensemble comparison and validation-weighting workflow.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_managed(growth, capacity, extraction, steps, initial)
    values = zeros(Float64, steps)
    values[1] = initial

    for i in 2:steps
        previous = values[i - 1]
        values[i] = max(0.0, previous + growth * previous * (1.0 - previous / capacity) - extraction * previous)
    end

    return values
end

function simulate_logistic(growth, capacity, steps, initial)
    values = zeros(Float64, steps)
    values[1] = initial

    for i in 2:steps
        previous = values[i - 1]
        values[i] = max(0.0, previous + growth * previous * (1.0 - previous / capacity))
    end

    return values
end

function rmse(actual, predicted)
    return sqrt(mean((actual .- predicted).^2))
end

Random.seed!(42)

steps = 90
train_cutoff = 60
observed = simulate_managed(0.085, 130.0, 0.012, steps, 12.0) .+ randn(steps) .* 1.1
observed = max.(0.0, observed)

models = [
    ("logistic_low", simulate_logistic(0.070, 115.0, steps, observed[1])),
    ("logistic_high", simulate_logistic(0.095, 145.0, steps, observed[1])),
    ("managed_reference", simulate_managed(0.085, 130.0, 0.012, steps, observed[1]))
]

rows = []

for (model_name, prediction) in models
    calibration_rmse = rmse(observed[1:train_cutoff], prediction[1:train_cutoff])
    validation_rmse = rmse(observed[(train_cutoff + 1):end], prediction[(train_cutoff + 1):end])

    push!(rows, (
        model_name,
        calibration_rmse,
        validation_rmse,
        validation_rmse - calibration_rmse
    ))
end

path = joinpath(tables_dir, "julia_model_ensemble_comparison.csv")
header = ["model" "calibration_rmse" "validation_rmse" "generalization_gap"]
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

println("Julia model ensemble comparison complete.")
println(path)
