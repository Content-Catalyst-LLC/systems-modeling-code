# phase_transition_ensemble.jl
# Julia phase-transition ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function linear_space(start_value, stop_value, count)
    step = (stop_value - start_value) / (count - 1)
    return [start_value + (i - 1) * step for i in 1:count]
end

function bifurcation_branches()
    rows = []

    for (index, control_parameter) in enumerate(linear_space(-1.5, 1.5, 301))
        if control_parameter > 0
            stable_positive = sqrt(control_parameter)
            stable_negative = -sqrt(control_parameter)
            order_magnitude = stable_positive
            phase_label = "two ordered phases"
        else
            stable_positive = 0.0
            stable_negative = 0.0
            order_magnitude = 0.0
            phase_label = "single neutral phase"
        end

        push!(rows, (
            index,
            control_parameter,
            stable_positive,
            stable_negative,
            0.0,
            order_magnitude,
            phase_label
        ))
    end

    return rows
end

function random_graph_component_fraction(node_count, probability, seed_value)
    Random.seed!(seed_value)
    adjacency = [Int[] for _ in 1:node_count]

    for source in 1:node_count
        for target in (source + 1):node_count
            if target <= node_count && rand() < probability
                push!(adjacency[source], target)
                push!(adjacency[target], source)
            end
        end
    end

    visited = falses(node_count)
    largest = 0
    components = 0
    edges = sum(length(neighbors) for neighbors in adjacency) ÷ 2

    for node in 1:node_count
        if !visited[node]
            components += 1
            queue = [node]
            visited[node] = true
            size = 0

            while !isempty(queue)
                current = popfirst!(queue)
                size += 1

                for neighbor in adjacency[current]
                    if !visited[neighbor]
                        visited[neighbor] = true
                        push!(queue, neighbor)
                    end
                end
            end

            largest = max(largest, size)
        end
    end

    return (edges, components, largest / node_count)
end

branch_rows = bifurcation_branches()
branch_path = joinpath(tables_dir, "julia_bifurcation_order_parameter_branches.csv")
branch_header = ["step" "control_parameter" "stable_state_positive" "stable_state_negative" "neutral_state" "order_parameter_magnitude" "phase_label"]
writedlm(branch_path, branch_header, ',')

branch_matrix = hcat(
    [row[1] for row in branch_rows],
    [row[2] for row in branch_rows],
    [row[3] for row in branch_rows],
    [row[4] for row in branch_rows],
    [row[5] for row in branch_rows],
    [row[6] for row in branch_rows],
    [row[7] for row in branch_rows]
)

open(branch_path, "a") do io
    writedlm(io, branch_matrix, ',')
end

network_rows = []
scenarios = [
    ("small_network", 60, 0.0, 0.10, 45, 42),
    ("medium_network", 120, 0.0, 0.08, 45, 84),
    ("larger_network", 240, 0.0, 0.05, 45, 126)
]

for scenario in scenarios
    name, node_count, p_start, p_end, p_steps, seed_value = scenario

    for (step_index, probability) in enumerate(linear_space(p_start, p_end, p_steps))
        edges, components, fraction = random_graph_component_fraction(node_count, probability, seed_value + step_index)
        average_degree = (2 * edges) / node_count

        push!(network_rows, (
            name,
            step_index,
            node_count,
            probability,
            edges,
            average_degree,
            components,
            fraction
        ))
    end
end

network_path = joinpath(tables_dir, "julia_network_phase_transition_trajectories.csv")
network_header = ["scenario" "step" "node_count" "link_probability" "edge_count" "average_degree" "component_count" "largest_component_fraction"]
writedlm(network_path, network_header, ',')

network_matrix = hcat(
    [row[1] for row in network_rows],
    [row[2] for row in network_rows],
    [row[3] for row in network_rows],
    [row[4] for row in network_rows],
    [row[5] for row in network_rows],
    [row[6] for row in network_rows],
    [row[7] for row in network_rows],
    [row[8] for row in network_rows]
)

open(network_path, "a") do io
    writedlm(io, network_matrix, ',')
end

println("Julia phase-transition ensemble complete.")
println(branch_path)
println(network_path)
