package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
)

type Summary struct {
	Scenario           string
	AverageService     float64
	MinimumService     float64
	TimeBelowThreshold int
	ThresholdCrossings int
	FinalCapacity      float64
	FinalDegradation   float64
	Transformed        int
	ResilienceScore    float64
}

func main() {
	summaries := []Summary{
		{"targeted_resilience_investment", 0.720000, 0.590000, 0, 0, 0.870000, 0.060000, 0, 0.699000},
		{"moderate_climate_stress", 0.690000, 0.560000, 0, 0, 0.720000, 0.080000, 0, 0.662000},
		{"transformation_pathway", 0.610000, 0.520000, 5, 2, 0.760000, 0.170000, 1, 0.476000},
		{"repeated_shocks", 0.590000, 0.480000, 9, 3, 0.610000, 0.160000, 0, 0.399000},
		{"delayed_adaptation", 0.550000, 0.430000, 14, 4, 0.600000, 0.210000, 0, 0.266500},
		{"compound_climate_stress", 0.490000, 0.360000, 24, 5, 0.500000, 0.300000, 0, 0.025000},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_climate_resilience_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "average_service", "minimum_service", "time_below_threshold", "threshold_crossings", "final_adaptive_capacity", "final_degradation", "transformed", "resilience_score"})

	for _, item := range summaries {
		writer.Write([]string{
			item.Scenario,
			fmt.Sprintf("%.6f", item.AverageService),
			fmt.Sprintf("%.6f", item.MinimumService),
			fmt.Sprintf("%d", item.TimeBelowThreshold),
			fmt.Sprintf("%d", item.ThresholdCrossings),
			fmt.Sprintf("%.6f", item.FinalCapacity),
			fmt.Sprintf("%.6f", item.FinalDegradation),
			fmt.Sprintf("%d", item.Transformed),
			fmt.Sprintf("%.6f", item.ResilienceScore),
		})
	}

	fmt.Println("Go climate resilience runner complete.")
	fmt.Println(path)
}
