# abm_threshold_ensemble.jl
# Julia ensemble for heterogeneous threshold adoption.

using Random
using Statistics
using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_member(seed; n_agents=180, n_steps=50)
    Random.seed!(seed)

    threshold_low = rand() * 0.20 + 0.05
    threshold_high = min(0.95, threshold_low + rand() * 0.45 + 0.20)
    neighbor_radius = rand(1:5)
    initial_adopters = rand(6:30)

    thresholds = threshold_low .+ rand(n_agents) .* (threshold_high - threshold_low)
    adopted = falses(n_agents)

    initial_ids = shuffle(1:n_agents)[1:initial_adopters]
    adopted[initial_ids] .= true

    final_rate = 0.0
    peak_new = 0
    time_to_half = 0

    for time in 1:n_steps
        previous = copy(adopted)

        for i in 1:n_agents
            if !previous[i]
                local_ids = Int[]
                for offset in -neighbor_radius:neighbor_radius
                    if offset != 0
                        push!(local_ids, mod1(i + offset, n_agents))
                    end
                end

                local_share = mean(previous[local_ids])
                if local_share >= thresholds[i]
                    adopted[i] = true
                end
            end
        end

        new_adopters = count(adopted) - count(previous)
        peak_new = max(peak_new, new_adopters)
        final_rate = mean(adopted)

        if time_to_half == 0 && final_rate >= 0.5
            time_to_half = time
        end
    end

    return (
        seed=seed,
        threshold_low=threshold_low,
        threshold_high=threshold_high,
        neighbor_radius=neighbor_radius,
        initial_adopters=initial_adopters,
        final_adoption_rate=final_rate,
        peak_new_adopters=peak_new,
        time_to_half_adoption=time_to_half,
        mean_threshold=mean(thresholds)
    )
end

rows = [simulate_member(9700 + i) for i in 1:300]

path = joinpath(tables_dir, "julia_abm_threshold_ensemble.csv")
header = ["seed" "threshold_low" "threshold_high" "neighbor_radius" "initial_adopters" "final_adoption_rate" "peak_new_adopters" "time_to_half_adoption" "mean_threshold"]
writedlm(path, header, ',')

matrix = hcat(
    [row.seed for row in rows],
    [row.threshold_low for row in rows],
    [row.threshold_high for row in rows],
    [row.neighbor_radius for row in rows],
    [row.initial_adopters for row in rows],
    [row.final_adoption_rate for row in rows],
    [row.peak_new_adopters for row in rows],
    [row.time_to_half_adoption for row in rows],
    [row.mean_threshold for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia ABM threshold ensemble complete.")
println("Median final adoption rate: ", median([row.final_adoption_rate for row in rows]))
println(path)
