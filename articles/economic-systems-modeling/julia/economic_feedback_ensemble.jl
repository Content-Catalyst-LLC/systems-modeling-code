# economic_feedback_ensemble.jl
# Julia economic systems feedback ensemble workflow.

using DelimitedFiles
using Random
using Statistics

article_root = normpath(joinpath(@__DIR__, ".."))
tables_dir = joinpath(article_root, "outputs", "tables")
mkpath(tables_dir)

function simulate_economy(
    scenario;
    n_steps = 120,
    demand_sensitivity = 0.62,
    investment_sensitivity = 0.16,
    interest_rate = 0.035,
    depreciation = 0.045,
    credit_sensitivity = 0.10,
    shock_step = 70,
    shock_size = -8.0,
    seed_value = 42
)
    Random.seed!(seed_value)

    output = 100.0
    capital = 190.0
    debt = 60.0
    government = 22.0
    rows = []

    for time in 1:n_steps
        consumption = max(0.0, 18.0 + demand_sensitivity * output - 0.025 * debt)
        investment = max(0.0, investment_sensitivity * output - interest_rate * debt)

        if time > 1
            capital = max(0.0, capital + investment - depreciation * capital)
            new_credit = max(0.0, credit_sensitivity * investment)
            repayment = 0.025 * debt
            debt = max(0.0, debt + new_credit - repayment)
            shock = time == shock_step ? shock_size : 0.0
            output = max(0.0, 0.33 * capital + consumption + government + shock + randn() * 0.35)
        end

        fragility = debt / max(capital, 1.0)
        debt_service = interest_rate * debt
        demand_gap = output - consumption - investment - government

        push!(rows, (
            scenario,
            time,
            output,
            consumption,
            investment,
            capital,
            debt,
            debt_service,
            fragility,
            government,
            demand_gap
        ))
    end

    return rows
end

scenarios = [
    ("baseline_feedback", Dict(:seed_value => 42)),
    ("higher_investment", Dict(:investment_sensitivity => 0.21, :seed_value => 43)),
    ("tighter_credit", Dict(:interest_rate => 0.055, :seed_value => 44)),
    ("larger_shock", Dict(:shock_size => -18.0, :seed_value => 45)),
    ("higher_debt_growth", Dict(:credit_sensitivity => 0.18, :seed_value => 46))
]

all_rows = []

for (name, kwargs) in scenarios
    append!(all_rows, simulate_economy(name; kwargs...))
end

trajectory_path = joinpath(tables_dir, "julia_economic_feedback_trajectories.csv")
header = ["scenario" "time" "output" "consumption" "investment" "capital" "debt" "debt_service" "fragility" "government" "demand_gap"]
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
    [row[11] for row in all_rows]
)

open(trajectory_path, "a") do io
    writedlm(io, matrix, ',')
end

summary_rows = []

for scenario in unique([row[1] for row in all_rows])
    subset = [row for row in all_rows if row[1] == scenario]
    final = subset[end]
    maximum_fragility = maximum([row[9] for row in subset])
    minimum_output = minimum([row[3] for row in subset])
    average_output = mean([row[3] for row in subset])
    label = maximum_fragility > 0.75 ? "high fragility pathway" : "moderate fragility pathway"

    push!(summary_rows, (
        scenario,
        final[3],
        final[6],
        final[7],
        final[9],
        maximum_fragility,
        minimum_output,
        average_output,
        label
    ))
end

summary_path = joinpath(tables_dir, "julia_economic_feedback_summary.csv")
summary_header = ["scenario" "final_output" "final_capital" "final_debt" "final_fragility" "maximum_fragility" "minimum_output" "average_output" "diagnostic_label"]
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

println("Julia economic feedback ensemble complete.")
println(summary_path)
