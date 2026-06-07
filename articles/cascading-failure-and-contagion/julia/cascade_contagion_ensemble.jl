# cascade_contagion_ensemble.jl
# Julia cascade and contagion ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function build_random_network(node_count, link_probability, seed_value)
    Random.seed!(seed_value)
    adjacency = [Set{Int}() for _ in 1:node_count]

    for source in 1:node_count
        for target in (source + 1):node_count
            if target <= node_count && rand() < link_probability
                push!(adjacency[source], target)
                push!(adjacency[target], source)
            end
        end
    end

    return adjacency
end

function simulate_threshold_cascade(scenario, node_count, link_probability, threshold, seed_count, max_steps, seed_value)
    adjacency = build_random_network(node_count, link_probability, seed_value)
    degrees = [length(neighbors) for neighbors in adjacency]
    seed_nodes = sortperm(degrees, rev=true)[1:seed_count]
    affected = Set(seed_nodes)

    rows = []

    for step in 0:max_steps
        push!(rows, (
            scenario,
            step,
            node_count,
            link_probability,
            threshold,
            seed_count,
            length(affected),
            length(affected) / node_count,
            mean(degrees),
            maximum(degrees)
        ))

        newly_affected = Set{Int}()

        for node in 1:node_count
            if node in affected || degrees[node] == 0
                continue
            end

            affected_neighbors = length(intersect(adjacency[node], affected))
            exposure_share = affected_neighbors / degrees[node]

            if exposure_share >= threshold
                push!(newly_affected, node)
            end
        end

        if isempty(newly_affected)
            break
        end

        union!(affected, newly_affected)
    end

    return rows
end

scenarios = [
    ("baseline_threshold", 90, 0.055, 0.25, 4, 40, 42),
    ("lower_threshold", 90, 0.055, 0.18, 4, 40, 43),
    ("higher_connectivity", 90, 0.075, 0.25, 4, 40, 44),
    ("larger_initial_shock", 90, 0.055, 0.25, 8, 40, 45)
]

all_rows = []

for scenario in scenarios
    append!(all_rows, simulate_threshold_cascade(scenario...))
end

trajectory_path = joinpath(tables_dir, "julia_threshold_cascade_trajectories.csv")
header = ["scenario" "step" "node_count" "link_probability" "threshold" "seed_count" "affected_count" "affected_share" "mean_degree" "maximum_degree"]
writedlm(trajectory_path, header, ',')

matrix = hcat(
    [row[1] for row in all_rows],
    [row[2] for row in all_rows],
    [row[3] for row in all_rows],
    [row[4] for row in all_rows],
    [row[5] for row in all_rows],
    [row[6] for row in all_rows],
    [row[7] for row in all_rows],
    [row[8] for row in all_rows],
    [row[9] for row in all_rows],
    [row[10] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    final = subset[end]
    push!(summary_rows, (
        scenario,
        final[7],
        final[8],
        final[2],
        final[9],
        final[10],
        final[8] >= 0.5 ? "systemic cascade" : "contained cascade"
    ))
end

summary_path = joinpath(tables_dir, "julia_threshold_cascade_summary.csv")
summary_header = ["scenario" "final_affected_count" "final_affected_share" "cascade_duration" "mean_degree" "maximum_degree" "diagnostic_label"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia cascade contagion ensemble complete.")
println(summary_path)
