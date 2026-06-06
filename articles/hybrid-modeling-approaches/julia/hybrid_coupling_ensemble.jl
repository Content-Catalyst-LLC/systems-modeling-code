# hybrid_coupling_ensemble.jl
# Julia ensemble for hybrid agent-queue coupling uncertainty.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function clamp(value, low=0.0, high=1.0)
    return max(low, min(high, value))
end

function simulate(seed; n_agents=160, n_steps=80)
    Random.seed!(seed)

    service_capacity = rand(16:44)
    pressure_sensitivity = rand() * 0.35 + 0.02
    baseline_low = rand() * 0.12 + 0.06
    baseline_high = baseline_low + rand() * 0.28 + 0.18

    propensities = baseline_low .+ rand(n_agents) .* (baseline_high - baseline_low)
    queue_length = 0

    queue_values = Float64[]
    utilization_values = Float64[]
    arrival_values = Float64[]

    for _ in 1:n_steps
        pressure = queue_length / max(1, service_capacity)
        effective = [clamp(p - pressure_sensitivity * pressure) for p in propensities]

        arrivals = sum(rand(n_agents) .< effective)
        available_work = queue_length + arrivals
        served = min(service_capacity, available_work)
        queue_length = max(0, available_work - served)

        push!(queue_values, queue_length)
        push!(utilization_values, served / service_capacity)
        push!(arrival_values, arrivals)
    end

    return (
        seed=seed,
        service_capacity=service_capacity,
        pressure_sensitivity=pressure_sensitivity,
        average_arrivals=mean(arrival_values),
        average_queue_length=mean(queue_values),
        maximum_queue_length=maximum(queue_values),
        average_utilization=mean(utilization_values),
        final_queue_length=queue_values[end]
    )
end

rows = [simulate(14000 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_hybrid_coupling_ensemble.csv")
header = ["seed" "service_capacity" "pressure_sensitivity" "average_arrivals" "average_queue_length" "maximum_queue_length" "average_utilization" "final_queue_length"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.service_capacity for row in rows],
    [row.pressure_sensitivity for row in rows],
    [row.average_arrivals for row in rows],
    [row.average_queue_length for row in rows],
    [row.maximum_queue_length for row in rows],
    [row.average_utilization for row in rows],
    [row.final_queue_length for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia hybrid coupling ensemble complete.")
println("Median average queue length: ", median([row.average_queue_length for row in rows]))
println(path)
