package main

import (
	"encoding/csv"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                string
	NAgents             int
	NSteps              int
	ServiceCapacity     int
	PressureSensitivity float64
	BaselineLow         float64
	BaselineHigh        float64
	Seed                int64
}

func clamp(value float64) float64 {
	if value < 0.0 {
		return 0.0
	}
	if value > 1.0 {
		return 1.0
	}
	return value
}

func simulate(s Scenario) []string {
	rng := rand.New(rand.NewSource(s.Seed))

	propensities := make([]float64, s.NAgents)
	for i := 0; i < s.NAgents; i++ {
		propensities[i] = s.BaselineLow + rng.Float64()*(s.BaselineHigh-s.BaselineLow)
	}

	queueLength := 0
	totalArrivals := 0
	totalQueue := 0
	maxQueue := 0
	totalUtilization := 0.0

	for step := 0; step < s.NSteps; step++ {
		pressure := float64(queueLength) / float64(s.ServiceCapacity)
		arrivals := 0

		for _, propensity := range propensities {
			effective := clamp(propensity - s.PressureSensitivity*pressure)
			if rng.Float64() < effective {
				arrivals++
			}
		}

		availableWork := queueLength + arrivals
		served := availableWork
		if served > s.ServiceCapacity {
			served = s.ServiceCapacity
		}
		queueLength = availableWork - served

		totalArrivals += arrivals
		totalQueue += queueLength
		if queueLength > maxQueue {
			maxQueue = queueLength
		}
		totalUtilization += float64(served) / float64(s.ServiceCapacity)
	}

	return []string{
		s.Name,
		fmt.Sprintf("%d", totalArrivals),
		fmt.Sprintf("%.6f", float64(totalArrivals)/float64(s.NSteps)),
		fmt.Sprintf("%.6f", float64(totalQueue)/float64(s.NSteps)),
		fmt.Sprintf("%d", maxQueue),
		fmt.Sprintf("%.6f", totalUtilization/float64(s.NSteps)),
		fmt.Sprintf("%d", queueLength),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_hybrid_agent_queue", 160, 80, 28, 0.18, 0.10, 0.42, 60606},
		{"low_capacity", 160, 80, 18, 0.18, 0.10, 0.42, 60607},
		{"high_capacity", 160, 80, 42, 0.18, 0.10, 0.42, 60608},
		{"strong_pressure_feedback", 160, 80, 28, 0.35, 0.10, 0.42, 60610},
		{"higher_baseline_demand", 160, 80, 28, 0.18, 0.20, 0.55, 60611},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_hybrid_agent_queue_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "total_arrivals", "average_arrivals", "average_queue_length", "maximum_queue_length", "average_utilization", "final_queue_length"})
	for _, scenario := range scenarios {
		writer.Write(simulate(scenario))
	}

	fmt.Println("Go hybrid scenario runner complete.")
	fmt.Println(path)
}
