# panarchy_multiscale_ensemble.jl
# Julia panarchy and multi-scale systems ensemble workflow.

using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function classify_phase(fast_cycle, release_event)
    if release_event == 1
        return "release"
    elseif fast_cycle < 0.8
        return "reorganization"
    elseif fast_cycle < 2.0
        return "growth"
    else
        return "conservation"
    end
end

function simulate_panarchy(name, fast_growth, fast_capacity, slow_constraint, release_threshold, release_magnitude, revolt_strength, remember_strength, slow_adjustment, slow_target; steps=160)
    fast_cycle = 0.5
    slow_memory = 1.0
    rows = []

    for time in 1:steps
        release_event = 0

        if time > 1
            fast_cycle = fast_cycle + fast_growth * fast_cycle * (1.0 - fast_cycle / fast_capacity) - slow_constraint * slow_memory

            if fast_cycle > release_threshold
                fast_cycle = max(0.0, fast_cycle - release_magnitude)
                slow_memory += revolt_strength
                release_event = 1
            else
                slow_memory = slow_memory + slow_adjustment * (slow_target - slow_memory)
            end

            fast_cycle = max(0.0, fast_cycle + remember_strength * slow_memory)
        end

        phase = classify_phase(fast_cycle, release_event)
        push!(rows, (name, time, fast_cycle, slow_memory, release_event, phase, fast_cycle * slow_memory))
    end

    return rows
end

scenarios = [
    ("baseline_panarchy", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.035, 0.010, 1.60),
    ("strong_revolt", 0.16, 3.20, 0.08, 2.35, 1.35, 0.24, 0.035, 0.010, 1.60),
    ("strong_remember", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.065, 0.014, 1.60),
    ("rigid_slow_structure", 0.16, 3.20, 0.13, 2.50, 1.35, 0.14, 0.020, 0.004, 1.60),
    ("weak_memory_high_volatility", 0.17, 3.10, 0.06, 2.30, 1.45, 0.20, 0.015, 0.008, 1.45)
]

all_rows = []
for scenario in scenarios
    append!(all_rows, simulate_panarchy(scenario...))
end

trajectory_path = joinpath(tables_dir, "julia_panarchy_multiscale_trajectories.csv")
header = ["scenario" "time" "fast_cycle" "slow_memory" "release_event" "phase" "cross_scale_coupling"]
writedlm(trajectory_path, header, ',')

matrix = hcat(
    [row[1] for row in all_rows],
    [row[2] for row in all_rows],
    [row[3] for row in all_rows],
    [row[4] for row in all_rows],
    [row[5] for row in all_rows],
    [row[6] for row in all_rows],
    [row[7] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in scenarios
    name = scenario[1]
    subset = [row for row in all_rows if row[1] == name]
    fast_values = [row[3] for row in subset]
    slow_values = [row[4] for row in subset]
    release_values = [row[5] for row in subset]
    coupling_values = [row[7] for row in subset]

    push!(summary_rows, (
        name,
        fast_values[end],
        slow_values[end],
        sum(release_values),
        maximum(fast_values),
        maximum(slow_values),
        mean(coupling_values)
    ))
end

summary_path = joinpath(tables_dir, "julia_panarchy_multiscale_summary.csv")
summary_header = ["scenario" "final_fast_cycle" "final_slow_memory" "release_events" "maximum_fast_cycle" "maximum_slow_memory" "mean_cross_scale_coupling"]
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

println("Julia panarchy multi-scale ensemble complete.")
println(summary_path)
