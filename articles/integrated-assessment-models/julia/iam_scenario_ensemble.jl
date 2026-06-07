using DelimitedFiles
root = normpath(joinpath(@__DIR__, ".."))
tables = joinpath(root, "outputs", "tables")
mkpath(tables)

function simulate(name; output=100.0, pg=0.012, ei=0.42, eid=0.012, mu=0.06, mug=0.025, mumax=0.95, dc=0.010, mc=0.040, dr=0.015)
    ap = 1.0; temp = 1.2; rows = []
    for (idx, year) in enumerate(2025:5:2100)
        if idx > 1
            output *= (1 + pg)^5
            ei = max(0.02, ei * (1 - eid)^5)
            mu = min(mumax, mu + mug)
        end
        emissions = output * ei * (1 - mu)
        if idx > 1
            ap = max(0.0, ap + 0.012 * emissions - 0.010 * ap)
            temp = max(0.0, temp + 0.030 * ap - 0.012 * temp)
        end
        damages = dc * temp^2 * output
        cost = mc * mu^2 * output
        cons = max(0.0, output - damages - cost)
        welfare = log(cons + 1) / ((1 + dr)^(year - 2025))
        push!(rows, (name, year, output, ei, mu, emissions, ap, temp, damages, cost, cons, welfare))
    end
    rows
end

rows = vcat(
    simulate("delayed_transition", eid=0.006, mu=0.02, mug=0.010, dc=0.012),
    simulate("moderate_transition"),
    simulate("accelerated_decarbonization", eid=0.018, mu=0.10, mug=0.045, mumax=0.98, dc=0.008, mc=0.055),
    simulate("high_innovation_pathway", pg=0.013, eid=0.026, mu=0.08, mug=0.040, mumax=0.98, dc=0.008, mc=0.038)
)

path = joinpath(tables, "julia_iam_pathway_trajectories.csv")
header = ["scenario" "year" "output" "emissions_intensity" "mitigation_rate" "emissions" "atmospheric_pressure" "temperature_proxy" "damages" "mitigation_cost" "consumption_proxy" "discounted_welfare_proxy"]
writedlm(path, header, ',')
open(path, "a") do io
    writedlm(io, hcat([r[1] for r in rows], [r[2] for r in rows], [r[3] for r in rows], [r[4] for r in rows], [r[5] for r in rows], [r[6] for r in rows], [r[7] for r in rows], [r[8] for r in rows], [r[9] for r in rows], [r[10] for r in rows], [r[11] for r in rows], [r[12] for r in rows]), ',')
end
println("Julia IAM ensemble complete.")
println(path)
