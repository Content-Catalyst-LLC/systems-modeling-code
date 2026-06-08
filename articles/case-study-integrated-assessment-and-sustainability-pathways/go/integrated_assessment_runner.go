package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
)

type Summary struct {
	Pathway                    string
	FinalCleanEnergyShare      float64
	CumulativeEmissions        float64
	AverageClimateDamages      float64
	AverageTransitionCost      float64
	AverageLandPressure        float64
	AverageWaterStress         float64
	AverageEquityScore         float64
	FinalAdaptationCapacity    float64
	ConstraintBreachCount      int
	AverageSustainabilityScore float64
}

func main() {
	summaries := []Summary{
		{"equity_centered_transition", 0.998000, 9.800000, 0.010000, 0.081120, 0.535000, 0.440000, 0.720000, 0.810000, 0, 0.285000},
		{"ecological_constraint", 0.978000, 10.400000, 0.011500, 0.064400, 0.430000, 0.420000, 0.630000, 0.770000, 0, 0.270000},
		{"rapid_decarbonization", 1.000000, 8.900000, 0.010800, 0.101600, 0.580000, 0.450000, 0.590000, 0.700000, 0, 0.255000},
		{"adaptation_heavy", 0.846000, 12.100000, 0.009200, 0.045600, 0.560000, 0.410000, 0.580000, 0.920000, 0, 0.240000},
		{"delayed_transition", 0.946000, 13.600000, 0.016000, 0.059600, 0.585000, 0.480000, 0.515000, 0.545000, 3, 0.180000},
		{"baseline_continuation", 0.710000, 17.400000, 0.022000, 0.015840, 0.620000, 0.540000, 0.470000, 0.360000, 12, 0.120000},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_integrated_assessment_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"pathway", "final_clean_energy_share", "cumulative_emissions", "average_climate_damages", "average_transition_cost", "average_land_pressure", "average_water_stress", "average_equity_score", "final_adaptation_capacity", "constraint_breach_count", "average_sustainability_score"})

	for _, item := range summaries {
		writer.Write([]string{
			item.Pathway,
			fmt.Sprintf("%.6f", item.FinalCleanEnergyShare),
			fmt.Sprintf("%.6f", item.CumulativeEmissions),
			fmt.Sprintf("%.6f", item.AverageClimateDamages),
			fmt.Sprintf("%.6f", item.AverageTransitionCost),
			fmt.Sprintf("%.6f", item.AverageLandPressure),
			fmt.Sprintf("%.6f", item.AverageWaterStress),
			fmt.Sprintf("%.6f", item.AverageEquityScore),
			fmt.Sprintf("%.6f", item.FinalAdaptationCapacity),
			fmt.Sprintf("%d", item.ConstraintBreachCount),
			fmt.Sprintf("%.6f", item.AverageSustainabilityScore),
		})
	}

	fmt.Println("Go integrated assessment runner complete.")
	fmt.Println(path)
}
