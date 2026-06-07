# geospatial_grid_ensemble.jl
# Julia grid exposure and accessibility ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function distance(x1, y1, x2, y2)
    return sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

function percentile(values, p)
    sorted_values = sort(values)
    index = clamp(round(Int, (length(sorted_values) - 1) * p) + 1, 1, length(sorted_values))
    return sorted_values[index]
end

function make_services(service_shift, service_capacity_multiplier)
    return [
        ("clinic_a", 5 + service_shift, 6, 900.0 * service_capacity_multiplier),
        ("clinic_b", 9, 20 - service_shift, 650.0 * service_capacity_multiplier),
        ("clinic_c", 18 - service_shift, 10 + service_shift, 800.0 * service_capacity_multiplier),
        ("clinic_d", 22, 21, 500.0 * service_capacity_multiplier)
    ]
end

function simulate_spatial_system(
    scenario;
    grid_size = 25,
    hazard_multiplier = 1.0,
    vulnerability_multiplier = 1.0,
    population_multiplier = 1.0,
    service_capacity_multiplier = 1.0,
    service_shift = 0
)
    Random.seed!(42)

    center_x = (grid_size + 1) / 2
    center_y = (grid_size + 1) / 2
    services = make_services(service_shift, service_capacity_multiplier)

    rows = []

    for x in 1:grid_size
        for y in 1:grid_size
            distance_to_center = distance(x, y, center_x, center_y)
            distance_to_river = abs(y - (0.45 * x + 4))

            population = max(0, round(Int, (120 + 500 * exp(-distance_to_center / 7) + randn() * 25) * population_multiplier))
            hazard = min(1.0, (exp(-distance_to_river / 3) + rand() * 0.12) * hazard_multiplier)
            vulnerability = min(1.0, max(0.0, (0.25 + 0.45 * exp(-distance_to_center / 9) + (rand() * 0.2 - 0.1)) * vulnerability_multiplier))
            risk_score = hazard * population * vulnerability

            accessibility = 0.0
            nearest_service = ""
            nearest_distance = 1.0e9

            for service in services
                service_id, sx, sy, capacity = service
                d = distance(x, y, sx, sy)
                impedance = 1.0 / (1.0 + d^2)
                accessibility += capacity * impedance

                if d < nearest_distance
                    nearest_distance = d
                    nearest_service = service_id
                end
            end

            service_gap_score = population / (accessibility + 1.0)

            push!(rows, (
                scenario,
                "cell_$(x)_$(y)",
                x,
                y,
                population,
                hazard,
                vulnerability,
                risk_score,
                accessibility,
                nearest_service,
                nearest_distance,
                service_gap_score
            ))
        end
    end

    risk_threshold = percentile([row[8] for row in rows], 0.85)
    gap_threshold = percentile([row[12] for row in rows], 0.85)

    classified_rows = []

    for row in rows
        high_risk = row[8] >= risk_threshold
        high_gap = row[12] >= gap_threshold

        priority = if high_risk && high_gap
            "high_risk_high_service_gap"
        elseif high_risk
            "high_risk"
        elseif high_gap
            "high_service_gap"
        else
            "standard_monitoring"
        end

        push!(classified_rows, (row..., priority))
    end

    return classified_rows
end

scenarios = [
    ("baseline_spatial_system", Dict()),
    ("higher_hazard_system", Dict(:hazard_multiplier => 1.35)),
    ("high_vulnerability_system", Dict(:vulnerability_multiplier => 1.35)),
    ("low_access_system", Dict(:service_capacity_multiplier => 0.65)),
    ("population_growth_system", Dict(:population_multiplier => 1.25)),
    ("resilient_service_system", Dict(:hazard_multiplier => 0.90, :vulnerability_multiplier => 0.90, :service_capacity_multiplier => 1.30, :service_shift => 3))
]

all_rows = []

for (name, kwargs) in scenarios
    append!(all_rows, simulate_spatial_system(name; kwargs...))
end

trajectory_path = joinpath(tables_dir, "julia_geospatial_grid_risk_access.csv")
header = ["scenario" "cell_id" "x" "y" "population" "hazard" "vulnerability" "risk_score" "accessibility" "nearest_service" "nearest_distance" "service_gap_score" "priority_zone"]
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
    [row[10] for row in all_rows],
    [row[11] for row in all_rows],
    [row[12] for row in all_rows],
    [row[13] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    for zone in unique([row[13] for row in subset])
        zone_rows = [row for row in subset if row[13] == zone]
        push!(summary_rows, (
            scenario,
            zone,
            length(zone_rows),
            sum([row[5] for row in zone_rows]),
            sum([row[8] for row in zone_rows]),
            mean([row[8] for row in zone_rows]),
            mean([row[9] for row in zone_rows]),
            mean([row[12] for row in zone_rows])
        ))
    end
end

summary_path = joinpath(tables_dir, "julia_geospatial_priority_summary.csv")
summary_header = ["scenario" "priority_zone" "cell_count" "population" "total_risk_score" "average_risk_score" "average_accessibility" "average_service_gap_score"]
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

println("Julia geospatial grid ensemble complete.")
println(summary_path)
