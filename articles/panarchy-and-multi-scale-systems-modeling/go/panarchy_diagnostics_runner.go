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
	FastGrowth       float64
	FastCapacity     float64
	SlowConstraint   float64
	ReleaseThreshold float64
	ReleaseMagnitude float64
	RevoltStrength   float64
	RememberStrength float64
	SlowAdjustment   float64
	SlowTarget       float64
}

type Summary struct {
	Scenario               string
	FinalFastCycle         float64
	FinalSlowMemory        float64
	ReleaseEvents          int
	MaximumFastCycle       float64
	MaximumSlowMemory      float64
	MeanCrossScaleCoupling float64
}

func simulate(s Scenario, steps int) Summary {
	fastCycle := 0.5
	slowMemory := 1.0
	maxFast := fastCycle
	maxSlow := slowMemory
	releaseEvents := 0
	totalCoupling := 0.0

	for time := 1; time <= steps; time++ {
		if time > 1 {
			fastCycle = fastCycle + s.FastGrowth*fastCycle*(1.0-fastCycle/s.FastCapacity) - s.SlowConstraint*slowMemory

			if fastCycle > s.ReleaseThreshold {
				fastCycle = math.Max(0.0, fastCycle-s.ReleaseMagnitude)
				slowMemory += s.RevoltStrength
				releaseEvents++
			} else {
				slowMemory = slowMemory + s.SlowAdjustment*(s.SlowTarget-slowMemory)
			}

			fastCycle = math.Max(0.0, fastCycle+s.RememberStrength*slowMemory)
		}

		maxFast = math.Max(maxFast, fastCycle)
		maxSlow = math.Max(maxSlow, slowMemory)
		totalCoupling += fastCycle * slowMemory
	}

	return Summary{
		Scenario:               s.Name,
		FinalFastCycle:         fastCycle,
		FinalSlowMemory:        slowMemory,
		ReleaseEvents:          releaseEvents,
		MaximumFastCycle:       maxFast,
		MaximumSlowMemory:      maxSlow,
		MeanCrossScaleCoupling: totalCoupling / float64(steps),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_panarchy", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.035, 0.010, 1.60},
		{"strong_revolt", 0.16, 3.20, 0.08, 2.35, 1.35, 0.24, 0.035, 0.010, 1.60},
		{"strong_remember", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.065, 0.014, 1.60},
		{"rigid_slow_structure", 0.16, 3.20, 0.13, 2.50, 1.35, 0.14, 0.020, 0.004, 1.60},
		{"weak_memory_high_volatility", 0.17, 3.10, 0.06, 2.30, 1.45, 0.20, 0.015, 0.008, 1.45},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_panarchy_multiscale_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "final_fast_cycle", "final_slow_memory", "release_events", "maximum_fast_cycle", "maximum_slow_memory", "mean_cross_scale_coupling"})

	for _, scenario := range scenarios {
		result := simulate(scenario, 160)
		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalFastCycle),
			fmt.Sprintf("%.6f", result.FinalSlowMemory),
			fmt.Sprintf("%d", result.ReleaseEvents),
			fmt.Sprintf("%.6f", result.MaximumFastCycle),
			fmt.Sprintf("%.6f", result.MaximumSlowMemory),
			fmt.Sprintf("%.6f", result.MeanCrossScaleCoupling),
		})
	}

	fmt.Println("Go panarchy diagnostics runner complete.")
	fmt.Println(path)
}
