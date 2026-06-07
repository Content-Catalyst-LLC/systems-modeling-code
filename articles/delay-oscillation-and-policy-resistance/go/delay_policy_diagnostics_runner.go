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
	Delay                   int
	CorrectionStrength      float64
	CounterresponseStrength float64
	PerceptionSmoothing     float64
}

type Summary struct {
	Scenario                  string
	InitialState              float64
	FinalState                float64
	MinimumState              float64
	MaximumState              float64
	TargetCrossings           int
	MaximumOvershoot          float64
	MeanAbsoluteTargetGap     float64
	CumulativeIntervention    float64
	CumulativeCounterresponse float64
	ResistanceRatio           float64
}

func targetCrossings(values []float64, target float64) int {
	crossings := 0
	for i := 1; i < len(values); i++ {
		leftGap := values[i-1] - target
		rightGap := values[i] - target

		if leftGap == 0.0 || rightGap == 0.0 {
			continue
		}

		if (leftGap < 0.0 && rightGap > 0.0) || (leftGap > 0.0 && rightGap < 0.0) {
			crossings++
		}
	}
	return crossings
}

func simulate(s Scenario, steps int) Summary {
	target := 50.0
	state := make([]float64, steps)
	perceived := make([]float64, steps)
	intervention := make([]float64, steps)
	counterresponse := make([]float64, steps)

	state[0] = 80.0
	perceived[0] = 80.0

	for t := 1; t < steps; t++ {
		perceived[t] = s.PerceptionSmoothing*state[t-1] + (1.0-s.PerceptionSmoothing)*perceived[t-1]
		observedIndex := t - s.Delay
		if observedIndex < 0 {
			observedIndex = 0
		}
		observedGap := perceived[observedIndex] - target

		action := s.CorrectionStrength * math.Max(0.0, observedGap)
		response := s.CounterresponseStrength * action
		naturalPressure := 2.0 + 0.025*state[t-1]

		intervention[t] = action
		counterresponse[t] = response
		state[t] = math.Max(0.0, state[t-1]+naturalPressure+response-action)
	}

	minimum := state[0]
	maximum := state[0]
	totalGap := 0.0
	totalIntervention := 0.0
	totalCounterresponse := 0.0

	for i := 0; i < steps; i++ {
		minimum = math.Min(minimum, state[i])
		maximum = math.Max(maximum, state[i])
		totalGap += math.Abs(state[i] - target)
		totalIntervention += intervention[i]
		totalCounterresponse += counterresponse[i]
	}

	resistanceRatio := 0.0
	if totalIntervention > 0.0 {
		resistanceRatio = totalCounterresponse / totalIntervention
	}

	return Summary{
		Scenario:                  s.Name,
		InitialState:              state[0],
		FinalState:                state[steps-1],
		MinimumState:              minimum,
		MaximumState:              maximum,
		TargetCrossings:           targetCrossings(state, target),
		MaximumOvershoot:          math.Max(0.0, maximum-target),
		MeanAbsoluteTargetGap:     totalGap / float64(steps),
		CumulativeIntervention:    totalIntervention,
		CumulativeCounterresponse: totalCounterresponse,
		ResistanceRatio:           resistanceRatio,
	}
}

func main() {
	scenarios := []Scenario{
		{"timely_moderate_response", 1, 0.18, 0.00, 0.75},
		{"delayed_response", 6, 0.18, 0.00, 0.55},
		{"overcorrection", 6, 0.34, 0.00, 0.55},
		{"undercorrection", 6, 0.09, 0.00, 0.55},
		{"policy_resistance", 6, 0.24, 0.42, 0.55},
		{"slow_recognition_high_resistance", 10, 0.24, 0.55, 0.35},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_delay_oscillation_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "initial_state", "final_state", "minimum_state", "maximum_state", "target_crossings", "maximum_overshoot_above_target", "mean_absolute_target_gap", "cumulative_intervention", "cumulative_counterresponse", "resistance_ratio"})

	for _, scenario := range scenarios {
		result := simulate(scenario, 100)
		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.InitialState),
			fmt.Sprintf("%.6f", result.FinalState),
			fmt.Sprintf("%.6f", result.MinimumState),
			fmt.Sprintf("%.6f", result.MaximumState),
			fmt.Sprintf("%d", result.TargetCrossings),
			fmt.Sprintf("%.6f", result.MaximumOvershoot),
			fmt.Sprintf("%.6f", result.MeanAbsoluteTargetGap),
			fmt.Sprintf("%.6f", result.CumulativeIntervention),
			fmt.Sprintf("%.6f", result.CumulativeCounterresponse),
			fmt.Sprintf("%.6f", result.ResistanceRatio),
		})
	}

	fmt.Println("Go delay-policy diagnostics runner complete.")
	fmt.Println(path)
}
