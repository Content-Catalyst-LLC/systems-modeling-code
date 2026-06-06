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
	state := []float64{12.0}
	maximumState := 12.0
	minimumState := 12.0
	timeToPeak := 0
	thresholdActivePeriods := 0
	maximumBalancingOutflow := 0.0

	for time := 0; time <= periods; time++ {
		current := state[len(state)-1]
		delayedIndex := len(state) - 1 - s.Delay
		if delayedIndex < 0 {
			delayedIndex = 0
		}
		delayedState := state[delayedIndex]

		inflow := s.GrowthRate * current
		balancingOutflow := s.BalancingStrength * math.Max(delayedState-s.Target, 0.0)

		thresholdPenalty := 0.0
		if current >= s.Threshold {
			thresholdPenalty = s.ThresholdCorrection * (current - s.Threshold)
			thresholdActivePeriods++
		}

		shock := 0.0
		if time == s.ShockTime {
			shock = s.ShockSize
		}

		nextState := clamp(current+inflow-balancingOutflow-thresholdPenalty+shock, 0.0, 250.0)
		state = append(state, nextState)

		if current > maximumState {
			maximumState = current
			timeToPeak = time
		}
		if current < minimumState {
			minimumState = current
		}
		if balancingOutflow > maximumBalancingOutflow {
			maximumBalancingOutflow = balancingOutflow
		}
	}

	finalState := state[len(state)-2]

	return []string{
		s.Name,
		fmt.Sprintf("%.6f", minimumState),
		fmt.Sprintf("%.6f", maximumState),
		fmt.Sprintf("%.6f", finalState),
		fmt.Sprintf("%.6f", maximumState-12.0),
		fmt.Sprintf("%d", timeToPeak),
		fmt.Sprintf("%d", thresholdActivePeriods),
		fmt.Sprintf("%.6f", maximumBalancingOutflow),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_delayed_feedback", 0.080, 0.060, 50.0, 7, 85.0, 0.035, 70, -10.0},
		{"short_delay", 0.080, 0.060, 50.0, 2, 85.0, 0.035, 70, -10.0},
		{"long_delay", 0.080, 0.060, 50.0, 14, 85.0, 0.035, 70, -10.0},
		{"weak_balancing", 0.080, 0.030, 50.0, 7, 85.0, 0.035, 70, -10.0},
		{"strong_threshold_response", 0.080, 0.060, 50.0, 7, 85.0, 0.080, 70, -10.0},
		{"higher_growth", 0.105, 0.060, 50.0, 7, 85.0, 0.035, 70, -10.0},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_scenario_diagnostics.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "minimum_state", "maximum_state", "final_state", "maximum_overshoot", "time_to_peak", "threshold_active_periods", "maximum_balancing_outflow"})

	for _, scenario := range scenarios {
		writer.Write(simulate(scenario))
	}

	fmt.Println("Go scenario diagnostics complete.")
	fmt.Println(path)
}
