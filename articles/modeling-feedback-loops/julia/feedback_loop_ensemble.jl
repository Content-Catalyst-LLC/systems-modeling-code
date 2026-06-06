# feedback_loop_ensemble.jl
# Julia feedback dynamics and delay ensemble workflow.

using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_delayed_balancing(initial, target, correction, delay, steps)
    values = zeros(Float64, steps)
    values[1] = initial

    for t in 2:steps
        delayed_index = max(1, t - delay)
        values[t] = values[t - 1] + correction * (target - values[delayed_index])
    end

    return values
end

function target_crossings(values, target)
    centered = values .- target
    changes = 0

    for i in 2:length(centered)
        if centered[i - 1] == 0 || centered[i] == 0
            continue
        end

        if (centered[i - 1] < 0 && centered[i] > 0) || (centered[i - 1] > 0 && centered[i] < 0)
            changes += 1
        end
    end

    return changes
end

steps = 90
target = 20.0
rows = []

scenario_id = 0

for delay in [1, 3, 5, 8, 12]
    for correction in [0.12, 0.20, 0.28, 0.36]
        global scenario_id += 1
        values = simulate_delayed_balancing(5.0, target, correction, delay, steps)

        push!(rows, (
            scenario_id,
            delay,
            correction,
            values[end],
            maximum(values),
            minimum(values),
            max(0.0, maximum(values) - target),
            target_crossings(values, target),
            mean(abs.(values .- target))
        ))
    end
end

path = joinpath(tables_dir, "julia_delayed_feedback_ensemble.csv")
header = ["scenario_id" "delay" "correction_strength" "final_state" "maximum_state" "minimum_state" "overshoot_above_target" "target_crossings" "mean_absolute_target_gap"]
writedlm(path, header, ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows],
    [row[6] for row in rows],
    [row[7] for row in rows],
    [row[8] for row in rows],
    [row[9] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia feedback loop ensemble complete.")
println(path)
