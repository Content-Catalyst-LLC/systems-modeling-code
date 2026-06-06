package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                string
	GrowthRate          float64
	BalancingStrength   float64
	Target              float64
	Delay               int
	Capacity            float64
	Threshold           float64
	ThresholdCorrection float64
	ShockTime           int
	ShockSize           float64
}

func clamp(value, low, high float64) float64 {
	return math.Max(low, math.Min(high, value))
}

func simulate(s Scenario) []string {
	periods := 160
	stock := []float64{15.0}

	maxStock := 15.0
	minStock := 15.0
	timeToPeak := 0
	maxInflow := 0.0
	maxOutflow := 0.0
	thresholdActive := 0

	for time := 0; time <= periods; time++ {
		current := stock[len(stock)-1]
		delayedIndex := len(stock) - 1 - s.Delay
		if delayedIndex < 0 {
			delayedIndex = 0
		}

		delayedStock := stock[delayedIndex]
		inflow := s.GrowthRate * current * (1.0 - current/s.Capacity)
		outflow := s.BalancingStrength * math.Max(delayedStock-s.Target, 0.0)

		thresholdPenalty := 0.0
		if current >= s.Threshold {
			thresholdPenalty = s.ThresholdCorrection * (current - s.Threshold)
			thresholdActive++
		}

		shock := 0.0
		if time == s.ShockTime {
			shock = s.ShockSize
		}

		nextStock := clamp(current+inflow-outflow-thresholdPenalty+shock, 0.0, 250.0)
		stock = append(stock, nextStock)

		if current > maxStock {
			maxStock = current
			timeToPeak = time
		}
		if current < minStock {
			minStock = current
		}
		if inflow > maxInflow {
			maxInflow = inflow
		}
		if outflow > maxOutflow {
			maxOutflow = outflow
		}
	}

	finalStock := stock[len(stock)-2]

	return []string{
		s.Name,
		fmt.Sprintf("%.6f", minStock),
		fmt.Sprintf("%.6f", maxStock),
		fmt.Sprintf("%.6f", finalStock),
		fmt.Sprintf("%d", timeToPeak),
		fmt.Sprintf("%.6f", maxInflow),
		fmt.Sprintf("%.6f", maxOutflow),
		fmt.Sprintf("%d", thresholdActive),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_core_principles", 0.090, 0.050, 55.0, 6, 90.0, 75.0, 0.040, 90, -8.0},
		{"short_delay", 0.090, 0.050, 55.0, 2, 90.0, 75.0, 0.040, 90, -8.0},
		{"long_delay", 0.090, 0.050, 55.0, 12, 90.0, 75.0, 0.040, 90, -8.0},
		{"weak_balancing", 0.090, 0.025, 55.0, 6, 90.0, 75.0, 0.040, 90, -8.0},
		{"lower_capacity", 0.090, 0.050, 55.0, 6, 70.0, 75.0, 0.040, 90, -8.0},
		{"strong_threshold_correction", 0.090, 0.050, 55.0, 6, 90.0, 75.0, 0.090, 90, -8.0},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_core_principles_scenario_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "minimum_stock", "maximum_stock", "final_stock", "time_to_peak", "maximum_inflow", "maximum_outflow", "threshold_active_periods"})
	for _, scenario := range scenarios {
		writer.Write(simulate(scenario))
	}

	fmt.Println("Go core principles scenario runner complete.")
	fmt.Println(path)
}
