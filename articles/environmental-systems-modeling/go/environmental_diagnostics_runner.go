package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name             string
	Steps            int
	InitialStock     float64
	CarryingCapacity float64
	GrowthRate       float64
	ExtractionRate   float64
	RestorationRate  float64
	DisturbanceStep  int
	DisturbanceSize  float64
}

type Summary struct {
	Scenario             string
	FinalStock           float64
	MinimumStock         float64
	MaximumStock         float64
	FinalResilienceIndex float64
	AverageExtraction    float64
	AverageRestoration   float64
}

func simulate(s Scenario) Summary {
	stock := s.InitialStock
	minStock := stock
	maxStock := stock
	totalExtraction := 0.0
	totalRestoration := 0.0

	for step := 1; step <= s.Steps; step++ {
		regeneration := s.GrowthRate * stock * (1.0 - stock/s.CarryingCapacity)
		extraction := s.ExtractionRate * stock
		restoration := s.RestorationRate * (s.CarryingCapacity - stock)

		disturbance := 0.0
		if step == s.DisturbanceStep {
			disturbance = s.DisturbanceSize
		}

		stock = math.Max(0.0, math.Min(s.CarryingCapacity, stock+regeneration-extraction+restoration-disturbance))

		if stock < minStock {
			minStock = stock
		}
		if stock > maxStock {
			maxStock = stock
		}

		totalExtraction += extraction
		totalRestoration += restoration
	}

	return Summary{
		Scenario:             s.Name,
		FinalStock:           stock,
		MinimumStock:         minStock,
		MaximumStock:         maxStock,
		FinalResilienceIndex: stock / s.CarryingCapacity,
		AverageExtraction:    totalExtraction / float64(s.Steps),
		AverageRestoration:   totalRestoration / float64(s.Steps),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_pressure", 120, 70.0, 100.0, 0.065, 0.040, 0.010, 65, 12.0},
		{"high_extraction", 120, 70.0, 100.0, 0.065, 0.065, 0.010, 65, 12.0},
		{"restoration_investment", 120, 70.0, 100.0, 0.065, 0.040, 0.035, 65, 12.0},
		{"larger_disturbance", 120, 70.0, 100.0, 0.065, 0.040, 0.010, 65, 24.0},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_environmental_stock_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"final_stock",
		"minimum_stock",
		"maximum_stock",
		"final_resilience_index",
		"average_extraction",
		"average_restoration",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "degraded pathway"
		if result.FinalResilienceIndex >= 0.70 {
			label = "recovering pathway"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalStock),
			fmt.Sprintf("%.6f", result.MinimumStock),
			fmt.Sprintf("%.6f", result.MaximumStock),
			fmt.Sprintf("%.6f", result.FinalResilienceIndex),
			fmt.Sprintf("%.6f", result.AverageExtraction),
			fmt.Sprintf("%.6f", result.AverageRestoration),
			label,
		})
	}

	fmt.Println("Go environmental diagnostics runner complete.")
	fmt.Println(path)
}
