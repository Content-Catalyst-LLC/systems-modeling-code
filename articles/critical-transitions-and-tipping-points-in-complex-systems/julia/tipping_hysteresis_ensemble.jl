# tipping_hysteresis_ensemble.jl
# Julia critical-transition and hysteresis ensemble workflow.

using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function update_state(x, r, dt)
    return x + dt * (r + x - x^3)
end

function linear_space(start_value, stop_value, count)
    step = (stop_value - start_value) / (count - 1)
    return [start_value + (i - 1) * step for i in 1:count]
end

function simulate_path(scenario, path_name, r_values, initial_x, dt, jump_threshold)
    x = initial_x
    rows = []

    for step_index in 1:length(r_values)
        previous_x = x

        if step_index > 1
            x = update_state(x, r_values[step_index], dt)
        end

        jump_size = abs(x - previous_x)
        transition_flag = jump_size > jump_threshold ? 1 : 0

        push!(rows, (scenario, path_name, step_index, r_values[step_index], x, jump_size, transition_flag))
    end

    return rows
end

scenarios = [
    ("baseline_hysteresis", -1.20, 1.20, 300, -1.00, 0.050, 0.150),
    ("slow_forcing", -1.20, 1.20, 500, -1.00, 0.035, 0.120),
    ("fast_forcing", -1.20, 1.20, 150, -1.00, 0.075, 0.220),
    ("wide_forcing", -1.45, 1.45, 360, -1.10, 0.050, 0.150)
]

all_rows = []

for scenario in scenarios
    name, forward_start, forward_end, steps, initial_state, dt, jump_threshold = scenario

    forward_r = linear_space(forward_start, forward_end, steps)
    forward_rows = simulate_path(name, "forward_forcing", forward_r, initial_state, dt, jump_threshold)

    backward_r = linear_space(forward_end, forward_start, steps)
    backward_initial = forward_rows[end][5]
    backward_rows = simulate_path(name, "backward_forcing", backward_r, backward_initial, dt, jump_threshold)

    append!(all_rows, forward_rows)
    append!(all_rows, backward_rows)
end

trajectory_path = joinpath(tables_dir, "julia_critical_transition_hysteresis_trajectories.csv")
header = ["scenario" "path" "step" "control_parameter" "system_state" "jump_size" "transition_flag"]
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
scenario_names = unique([row[1] for row in all_rows])

for scenario_name in scenario_names
    for path_name in ["forward_forcing", "backward_forcing"]
        subset = [row for row in all_rows if row[1] == scenario_name && row[2] == path_name]
        states = [row[5] for row in subset]
        jumps = [row[6] for row in subset]
        transitions = [row[7] for row in subset]

        push!(summary_rows, (
            scenario_name,
            path_name,
            states[1],
            states[end],
            minimum(states),
            maximum(states),
            maximum(jumps),
            sum(transitions)
        ))
    end
end

summary_path = joinpath(tables_dir, "julia_critical_transition_hysteresis_summary.csv")
summary_header = ["scenario" "path" "initial_state" "final_state" "minimum_state" "maximum_state" "maximum_jump_size" "transition_flags"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows],
    [row[8] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia tipping hysteresis ensemble complete.")
println(summary_path)
