package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name              string
	GrowthRate        float64
	CarryingCapacity  float64
	BalancingStrength float64
	Target            float64
	Delay             int
	ShockTime         int
	ShockSize         float64
}

func clamp(value, low, high float64) float64 {
	return math.Max(low, math.Min(high, value))
}

func simulate(s Scenario) []string {
	nSteps := 160
	exponential := []float64{10.0}
	logistic := []float64{10.0}
	delayedFeedback := []float64{10.0}

	maxDelayed := 10.0
	timeToPeak := 0
	maxOutflow := 0.0

	for time := 0; time <= nSteps; time++ {
		currentExponential := exponential[len(exponential)-1]
		currentLogistic := logistic[len(logistic)-1]
		currentDelayed := delayedFeedback[len(delayedFeedback)-1]

		delayedIndex := len(delayedFeedback) - 1 - s.Delay
		if delayedIndex < 0 {
			delayedIndex = 0
		}

		delayedState := delayedFeedback[delayedIndex]
		inflow := s.GrowthRate * currentDelayed
		outflow := s.BalancingStrength * math.Max(delayedState-s.Target, 0.0)

		shock := 0.0
		if time == s.ShockTime {
			shock = s.ShockSize
		}

		nextExponential := clamp(currentExponential+s.GrowthRate*currentExponential, 0.0, 250.0)
		nextLogistic := clamp(currentLogistic+s.GrowthRate*currentLogistic*(1.0-currentLogistic/s.CarryingCapacity), 0.0, 250.0)
		nextDelayed := clamp(currentDelayed+inflow-outflow+shock, 0.0, 250.0)

		exponential = append(exponential, nextExponential)
		logistic = append(logistic, nextLogistic)
		delayedFeedback = append(delayedFeedback, nextDelayed)

		if currentDelayed > maxDelayed {
			maxDelayed = currentDelayed
			timeToPeak = time
		}
		if outflow > maxOutflow {
			maxOutflow = outflow
		}
	}

	finalExponential := exponential[len(exponential)-2]
	finalLogistic := logistic[len(logistic)-2]
	finalDelayed := delayedFeedback[len(delayedFeedback)-2]

	return []string{
		s.Name,
		fmt.Sprintf("%.6f", finalExponential),
		fmt.Sprintf("%.6f", finalLogistic),
		fmt.Sprintf("%.6f", finalDelayed),
		fmt.Sprintf("%.6f", maxDelayed),
		fmt.Sprintf("%d", timeToPeak),
		fmt.Sprintf("%.6f", maxOutflow),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_historical_dynamics", 0.080, 80.0, 0.060, 55.0, 7, 90, -8.0},
		{"short_delay", 0.080, 80.0, 0.060, 55.0, 2, 90, -8.0},
		{"long_delay", 0.080, 80.0, 0.060, 55.0, 14, 90, -8.0},
		{"weak_balancing", 0.080, 80.0, 0.030, 55.0, 7, 90, -8.0},
		{"higher_growth", 0.105, 80.0, 0.060, 55.0, 7, 90, -8.0},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_historical_scenario_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "final_exponential", "final_logistic", "final_delayed_feedback", "maximum_delayed_feedback", "time_to_peak", "maximum_outflow"})
	for _, scenario := range scenarios {
		writer.Write(simulate(scenario))
	}

	fmt.Println("Go historical scenario runner complete.")
	fmt.Println(path)
}
