# adaptive_monitoring_ensemble.jl
# Julia adaptive monitoring diagnostics.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

true_state = 12.0
estimate = 12.0
drift = 0.0

rows = []

for t in 0:23
    shock = (t == 8 || t == 16) ? 4.0 : 0.0
    global true_state = 0.93 * true_state + 0.3 * sin(t / 10.0) + shock
    observed = true_state + 0.4 * sin(t / 3.0)

    prediction = 0.93 * estimate + 0.3 * sin(t / 10.0)
    residual = observed - prediction
    intervention = abs(residual) > 3.0 ? 1 : 0

    if intervention == 1
        prediction = prediction + 0.25 * residual
    end

    global estimate = 0.70 * prediction + 0.30 * observed
    global drift = 0.80 * drift + 0.20 * abs(observed - estimate)

    push!(rows, (t, true_state, observed, estimate, residual, drift, intervention))
end

path = joinpath(tables_dir, "julia_adaptive_monitoring.csv")
writedlm(path, ["time" "true_state" "observed_state" "estimated_state" "residual" "drift_indicator" "intervention_flag"], ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows],
    [row[6] for row in rows],
    [row[7] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia adaptive monitoring ensemble complete.")
println(path)
