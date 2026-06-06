# uncertainty_ensemble.jl
# Lightweight uncertainty ensemble for nonlinear systems modeling.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function run_member(seed)
    Random.seed!(seed)
    n_steps = 120
    x = zeros(Float64, n_steps)
    x[1] = 30.0
    r = rand() * 0.04 + 0.025
    loss = rand() * 0.025 + 0.010
    shock = -(rand() * 12.0 + 5.0)

    for t in 2:n_steps
        current_shock = t == 55 ? shock : 0.0
        x[t] = max(0.0, x[t-1] + r*x[t-1]*(1 - x[t-1]/110.0) - loss*max(x[t-1] - 70.0, 0.0) + current_shock)
    end

    return (seed=seed, final=x[end], minimum=minimum(x), maximum=maximum(x), r=r, loss=loss, shock=shock)
end

rows = [run_member(5000 + i) for i in 1:200]
matrix = hcat(
    [row.seed for row in rows],
    [row.final for row in rows],
    [row.minimum for row in rows],
    [row.maximum for row in rows],
    [row.r for row in rows],
    [row.loss for row in rows],
    [row.shock for row in rows]
)

path = joinpath(tables_dir, "julia_uncertainty_ensemble.csv")
writedlm(path, ["seed" "final_state" "minimum_state" "maximum_state" "growth_rate" "loss_rate" "shock_size"], ',')
open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia uncertainty ensemble complete.")
println("Median final state: ", median([row.final for row in rows]))
