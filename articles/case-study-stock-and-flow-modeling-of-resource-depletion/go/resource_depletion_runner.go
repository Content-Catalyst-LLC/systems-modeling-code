package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                    string
	Periods                 int
	Stock                   float64
	RegenerationRate        float64
	DemandGrowth            float64
	ExtractionEfficiency    float64
	ConservationSensitivity float64
	MaxConservation         float64
}

func main() {
	scenarios := []Scenario{
		{"baseline", 80, 80, 0.080, 0.015, 0.120, 0.45, 0.35},
		{"high_demand", 80, 80, 0.080, 0.035, 0.120, 0.45, 0.35},
		{"conservation", 80, 80, 0.080, 0.015, 0.120, 0.85, 0.55},
		{"technology_rebound", 80, 80, 0.080, 0.030, 0.180, 0.35, 0.30},
		{"regeneration_stress", 80, 80, 0.045, 0.015, 0.120, 0.45, 0.35},
		{"delayed_governance", 80, 80, 0.080, 0.025, 0.120, 0.20, 0.20},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_resource_depletion_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "final_stock", "minimum_stock", "cumulative_extraction", "cumulative_regeneration", "overshoot_periods"})

	for _, s := range scenarios {
		stock := s.Stock
		minStock := stock
		cumulativeExtraction := 0.0
		cumulativeRegeneration := 0.0
		overshootPeriods := 0

		for t := 0; t < s.Periods; t++ {
			demand := 4.0 * math.Pow(1.0+s.DemandGrowth, float64(t))
			scarcity := math.Max(0.0, 1.0-stock/70.0)
			conservation := math.Min(s.MaxConservation, s.ConservationSensitivity*scarcity)
			effectiveDemand := demand * (1.0 - conservation)
			regeneration := s.RegenerationRate * stock * (1.0 - stock/100.0)
			regeneration = math.Max(0.0, regeneration)
			extraction := math.Min(effectiveDemand, math.Min(s.ExtractionEfficiency*stock, stock+regeneration))

			if extraction > regeneration {
				overshootPeriods++
			}

			cumulativeExtraction += extraction
			cumulativeRegeneration += regeneration
			stock = math.Max(0.0, stock+regeneration-extraction)
			minStock = math.Min(minStock, stock)
		}

		writer.Write([]string{
			s.Name,
			fmt.Sprintf("%.6f", stock),
			fmt.Sprintf("%.6f", minStock),
			fmt.Sprintf("%.6f", cumulativeExtraction),
			fmt.Sprintf("%.6f", cumulativeRegeneration),
			fmt.Sprintf("%d", overshootPeriods),
		})
	}

	fmt.Println("Go resource depletion runner complete.")
	fmt.Println(path)
}
