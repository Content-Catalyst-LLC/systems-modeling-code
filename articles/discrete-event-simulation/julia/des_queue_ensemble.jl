# des_queue_ensemble.jl
# Julia ensemble for single-server queue diagnostics.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_queue(seed; n_entities=240)
    Random.seed!(seed)

    arrival_rate = rand() * 0.12 + 0.12
    service_rate = rand() * 0.16 + 0.18
    interarrival = randexp(n_entities) ./ arrival_rate
    service_time = randexp(n_entities) ./ service_rate

    arrival_time = cumsum(interarrival)
    service_start = zeros(n_entities)
    departure_time = zeros(n_entities)
    waiting_time = zeros(n_entities)

    service_start[1] = arrival_time[1]
    departure_time[1] = service_start[1] + service_time[1]

    for i in 2:n_entities
        service_start[i] = max(arrival_time[i], departure_time[i - 1])
        departure_time[i] = service_start[i] + service_time[i]
        waiting_time[i] = service_start[i] - arrival_time[i]
    end

    return (
        seed=seed,
        arrival_rate=arrival_rate,
        service_rate=service_rate,
        implied_utilization=arrival_rate / service_rate,
        average_waiting_time=mean(waiting_time),
        maximum_waiting_time=maximum(waiting_time),
        average_time_in_system=mean(departure_time .- arrival_time),
        service_level_share=mean(waiting_time .<= 12.0)
    )
end

rows = [simulate_queue(12000 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_des_queue_ensemble.csv")
header = ["seed" "arrival_rate" "service_rate" "implied_utilization" "average_waiting_time" "maximum_waiting_time" "average_time_in_system" "service_level_share"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.arrival_rate for row in rows],
    [row.service_rate for row in rows],
    [row.implied_utilization for row in rows],
    [row.average_waiting_time for row in rows],
    [row.maximum_waiting_time for row in rows],
    [row.average_time_in_system for row in rows],
    [row.service_level_share for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia DES queue ensemble complete.")
println("Median average waiting time: ", median([row.average_waiting_time for row in rows]))
println(path)
