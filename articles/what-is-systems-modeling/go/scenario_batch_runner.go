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
	CouplingStrength float64
	RecoveryRate     float64
	Redundancy        float64
	ShockSize         float64
}

func clamp(value, low, high float64) float64 {
	return math.Max(low, math.Min(high, value))
}

func simulateScenario(s Scenario) []string {
	nSteps := 120
	state := 1.0
	minState := state
	shockTime := 40

	for t := 1; t < nSteps; t++ {
		dependencyLoss := s.CouplingStrength * (state - 1.0) * (1.0 - s.Redundancy)
		recovery := s.RecoveryRate * (1.0 - state)
		shock := 0.0
		if t == shockTime {
			shock = s.ShockSize
		}

		state = clamp(state+dependencyLoss+recovery+shock, 0.0, 1.25)
		if state < minState {
			minState = state
		}
	}

	return []string{
		s.Name,
		fmt.Sprintf("%.6f", minState),
		fmt.Sprintf("%.6f", 1.0-minState),
		fmt.Sprintf("%.6f", state),
		fmt.Sprintf("%.6f", 1.0-state),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline", 0.18, 0.075, 0.20, -0.55},
		{"high_coupling", 0.28, 0.070, 0.12, -0.55},
		{"higher_redundancy", 0.16, 0.105, 0.42, -0.55},
		{"severe_shock", 0.18, 0.065, 0.20, -0.72},
	}

	outputDir := filepath.Join("outputs", "tables")
	_ = os.MkdirAll(outputDir, 0755)

	path := filepath.Join(outputDir, "go_scenario_batch_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "minimum_state", "maximum_loss", "final_state", "unrecovered_loss"})
	for _, scenario := range scenarios {
		writer.Write(simulateScenario(scenario))
	}

	fmt.Println("Go scenario batch runner complete.")
	fmt.Println(path)
}
