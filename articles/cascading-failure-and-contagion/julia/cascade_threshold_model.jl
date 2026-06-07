# Minimal Julia cascade threshold example.

nodes = [
    ("energy", 0.75, 0.20),
    ("water", 0.70, 0.62),
    ("telecom", 0.72, 0.58),
    ("health", 0.78, 0.55),
    ("public_services", 0.64, 0.77),
]

println("Cascade threshold diagnostics")
for (sector, threshold, stress) in nodes
    status = stress >= threshold ? "failure risk" : "within threshold"
    println(sector, ", stress=", stress, ", threshold=", threshold, ", status=", status)
end
