# network_diffusion_ensemble.jl
# Julia ensemble for diffusion and removal diagnostics on a synthetic network.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function build_graph(n, seed)
    Random.seed!(seed)
    graph = [Set{Int}() for _ in 1:n]

    communities = [1:16, 17:32, 33:48]
    for community in communities
        for i in community
            for j in community
                if i < j && rand() < 0.18
                    push!(graph[i], j)
                    push!(graph[j], i)
                end
            end
        end
    end

    bridges = [(3, 19), (7, 25), (21, 35), (29, 42), (12, 37), (2, 18), (18, 34)]
    for (a, b) in bridges
        push!(graph[a], b)
        push!(graph[b], a)
    end

    return graph
end

function simulate_contagion(graph, probability, seed; steps=24)
    Random.seed!(seed)
    infected = Set([3])
    n = length(graph)

    for _ in 1:steps
        next_infected = copy(infected)
        for node in infected
            for neighbor in graph[node]
                if !(neighbor in infected) && rand() < probability
                    push!(next_infected, neighbor)
                end
            end
        end
        infected = next_infected
    end

    return length(infected) / n
end

rows = []
for run_id in 1:300
    probability = rand() * 0.25 + 0.05
    graph = build_graph(48, 10000 + run_id)
    final_share = simulate_contagion(graph, probability, 11000 + run_id)
    degrees = [length(neighbors) for neighbors in graph]
    push!(rows, (run_id, probability, mean(degrees), maximum(degrees), final_share))
end

path = joinpath(tables_dir, "julia_network_diffusion_ensemble.csv")
header = ["run_id" "contagion_probability" "average_degree" "maximum_degree" "final_infected_share"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia network diffusion ensemble complete.")
println("Median final infected share: ", median([row[5] for row in rows]))
println(path)
