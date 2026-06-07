# infrastructure_systems_ensemble.jl
# Julia infrastructure cascade ensemble workflow.

using DelimitedFiles
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_cascade(
    scenario;
    n_steps = 80,
    shock_start = 20,
    shock_end = 36,
    power_loss_rate = 0.035,
    power_recovery_rate = 0.025,
    communications_dependency = 0.72,
    water_power_dependency = 0.55,
    water_comms_dependency = 0.25,
    transport_power_dependency = 0.30,
    transport_comms_dependency = 0.25
)
    power = 1.0
    communications = 1.0
    water = 1.0
    transport = 1.0
    rows = []

    for time in 0:(n_steps - 1)
        if shock_start <= time <= shock_end
            power = max(0.45, power - power_loss_rate)
        elseif time > shock_end
            power = min(1.0, power + power_recovery_rate)
        else
            power = 1.0
        end

        communications = max(0.40, communications_dependency * power + (1.0 - communications_dependency) * communications)
        water = max(0.35, water_power_dependency * power + water_comms_dependency * communications + (1.0 - water_power_dependency - water_comms_dependency) * water)
        transport = max(0.35, transport_power_dependency * power + transport_comms_dependency * communications + (1.0 - transport_power_dependency - transport_comms_dependency) * transport)

        composite_service = mean([power, communications, water, transport])
        unmet_service = 1.0 - composite_service

        push!(rows, (
            scenario,
            time,
            power,
            communications,
            water,
            transport,
            composite_service,
            unmet_service,
            shock_start <= time <= shock_end ? 1 : 0
        ))
    end

    return rows
end

scenarios = [
    ("baseline_cascade", Dict()),
    ("larger_power_loss", Dict(:power_loss_rate => 0.055)),
    ("faster_recovery", Dict(:power_recovery_rate => 0.045)),
    ("high_digital_dependency", Dict(:communications_dependency => 0.88, :water_comms_dependency => 0.32, :transport_comms_dependency => 0.35)),
    ("longer_shock", Dict(:shock_end => 48)),
    ("resilient_backup", Dict(:power_loss_rate => 0.028, :power_recovery_rate => 0.040, :communications_dependency => 0.55, :water_power_dependency => 0.45, :water_comms_dependency => 0.18, :transport_power_dependency => 0.22, :transport_comms_dependency => 0.18))
]

all_rows = []

for (name, kwargs) in scenarios
    append!(all_rows, simulate_cascade(name; kwargs...))
end

trajectory_path = joinpath(tables_dir, "julia_infrastructure_cascade_trajectories.csv")
header = ["scenario" "time" "power" "communications" "water" "transport" "composite_service" "unmet_service" "shock_active"]
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
    [row[9] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    final = subset[end]
    maximum_unmet = maximum([row[8] for row in subset])
    total_unmet = sum([row[8] for row in subset])
    label = maximum_unmet > 0.35 ? "severe cascade pathway" : "managed cascade pathway"

    push!(summary_rows, (
        scenario,
        final[7],
        minimum([row[3] for row in subset]),
        minimum([row[4] for row in subset]),
        minimum([row[5] for row in subset]),
        minimum([row[6] for row in subset]),
        maximum_unmet,
        total_unmet,
        label
    ))
end

summary_path = joinpath(tables_dir, "julia_infrastructure_cascade_summary.csv")
summary_header = ["scenario" "final_composite_service" "minimum_power" "minimum_communications" "minimum_water" "minimum_transport" "maximum_unmet_service" "total_unmet_service" "diagnostic_label"]
writedlm(summary_path, summary_header, ',')

summary_matrix = hcat(
    [row[1] for row in summary_rows],
    [row[2] for row in summary_rows],
    [row[3] for row in summary_rows],
    [row[4] for row in summary_rows],
    [row[5] for row in summary_rows],
    [row[6] for row in summary_rows],
    [row[7] for row in summary_rows],
    [row[8] for row in summary_rows],
    [row[9] for row in summary_rows]
)

open(summary_path, "a") do io
    writedlm(io, summary_matrix, ',')
end

println("Julia infrastructure systems ensemble complete.")
println(trajectory_path)
println(summary_path)
