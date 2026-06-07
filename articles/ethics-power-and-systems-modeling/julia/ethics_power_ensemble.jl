# ethics_power_ensemble.jl
# Julia ethics, power, and systems modeling diagnostics.

using DelimitedFiles

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

stakeholders = [
    ("public_agency", 0.40, 1.0, 0.95, 0.80, 0.20),
    ("technical_modelers", 0.20, 1.0, 0.85, 0.65, 0.15),
    ("frontline_workers", 0.70, 1.0, 0.45, 0.55, 0.35),
    ("affected_residents", 0.95, 1.0, 0.35, 0.50, 0.60),
    ("low_access_households", 1.00, 0.0, 0.10, 0.35, 0.80),
    ("future_generations", 0.90, 0.0, 0.00, 0.40, 0.75),
    ("local_environment", 0.85, 0.0, 0.05, 0.30, 0.70)
]

rows = []

for s in stakeholders
    group, affected, represented, influence, benefit, burden = s
    net_benefit = benefit - burden
    burden_gap = burden - benefit
    power_burden_gap = affected * burden * (1 - influence)

    label = if power_burden_gap >= 0.45
        "high_power_burden_gap"
    elseif power_burden_gap >= 0.20
        "moderate_power_burden_gap"
    else
        "lower_power_burden_gap"
    end

    push!(rows, (group, affected, represented, influence, benefit, burden, net_benefit, burden_gap, power_burden_gap, label))
end

path = joinpath(tables_dir, "julia_ethics_stakeholder_distributional_diagnostics.csv")
writedlm(path, ["group" "affected" "represented" "influence" "expected_benefit" "expected_burden" "net_benefit" "burden_gap" "power_burden_gap" "risk_label"], ',')

matrix = hcat(
    [row[1] for row in rows],
    [row[2] for row in rows],
    [row[3] for row in rows],
    [row[4] for row in rows],
    [row[5] for row in rows],
    [row[6] for row in rows],
    [row[7] for row in rows],
    [row[8] for row in rows],
    [row[9] for row in rows],
    [row[10] for row in rows]
)

open(path, "a") do io
    writedlm(io, matrix, ',')
end

println("Julia ethics and power ensemble complete.")
println(path)
