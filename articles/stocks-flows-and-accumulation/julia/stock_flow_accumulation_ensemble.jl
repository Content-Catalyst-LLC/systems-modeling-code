# stock_flow_accumulation_ensemble.jl
# Julia accumulation scenario ensemble workflow.

using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_scenario(name; steps=120)
    backlog = 80.0
    resource = 600.0
    condition = 72.0

    rows = []

    for time in 1:steps
        if name == "baseline"
            arrivals = 18.0
            extraction = 24.0
            maintenance = 0.9
        elseif name == "capacity_and_conservation"
            arrivals = time < 50 ? 16.0 : 13.0
            extraction = time < 70 ? 22.0 : 12.0
            maintenance = time < 60 ? 1.2 : 2.8
        elseif name == "delayed_response"
            arrivals = time < 75 ? 18.0 : 13.0
            extraction = time < 85 ? 24.0 : 12.0
            maintenance = time < 85 ? 0.9 : 2.8
        else
            arrivals = time < 50 ? 16.0 : 12.0
            extraction = time < 55 ? 22.0 : 10.0
            maintenance = time < 50 ? 1.4 : 3.4
        end

        completions = min(backlog + arrivals, 12.0 + 0.08 * backlog)
        backlog_net = arrivals - completions
        backlog = max(0.0, backlog + backlog_net)

        regeneration = 0.045 * resource * (1.0 - resource / 1000.0)
        resource_net = regeneration - extraction
        resource = max(0.0, resource + resource_net)

        wear = 1.4 + 0.012 * max(0.0, 100.0 - condition)
        condition_net = maintenance - wear
        condition = min(100.0, max(0.0, condition + condition_net))

        push!(rows, (name, time, backlog, resource, condition, backlog_net, resource_net, condition_net))
    end

    return rows
end

all_rows = []
for scenario in ["baseline", "capacity_and_conservation", "delayed_response", "adaptive_recovery"]
    append!(all_rows, simulate_scenario(scenario))
end

path = joinpath(tables_dir, "julia_stock_flow_trajectories.csv")
header = ["scenario" "time" "backlog" "resource" "infrastructure_condition" "backlog_net_flow" "resource_net_flow" "condition_net_flow"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in all_rows],
    [row[2] for row in all_rows],
    [row[3] for row in all_rows],
    [row[4] for row in all_rows],
    [row[5] for row in all_rows],
    [row[6] for row in all_rows],
    [row[7] for row in all_rows],
    [row[8] for row in all_rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

summary_path = joinpath(tables_dir, "julia_stock_flow_summary.csv")
summary_rows = []

for scenario in ["baseline", "capacity_and_conservation", "delayed_response", "adaptive_recovery"]
    subset = [row for row in all_rows if row[1] == scenario]
    backlog_values = [row[3] for row in subset]
    resource_values = [row[4] for row in subset]
    condition_values = [row[5] for row in subset]

    push!(summary_rows, (scenario, "backlog", backlog_values[1], backlog_values[end], minimum(backlog_values), maximum(backlog_values)))
    push!(summary_rows, (scenario, "resource", resource_values[1], resource_values[end], minimum(resource_values), maximum(resource_values)))
    push!(summary_rows, (scenario, "infrastructure_condition", condition_values[1], condition_values[end], minimum(condition_values), maximum(condition_values)))
end

summary_header = ["scenario" "stock" "initial_value" "final_value" "minimum_value" "maximum_value"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia stock-flow accumulation ensemble complete.")
println(path)
println(summary_path)
