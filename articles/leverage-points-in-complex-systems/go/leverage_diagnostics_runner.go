package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                 string
	FeedbackGain         float64
	ExternalCorrection   float64
	InformationDelay     int
	InformationQuality   float64
	BufferCapacity       float64
	RuleThreshold        float64
	RuleFeedbackGain     float64
	SelfOrganizationRate float64
	GoalWeightResilience float64
	ImplementationDelay  int
	HasRule              bool
}

type Result struct {
	InitialState            float64
	FinalState              float64
	MaximumState            float64
	MeanPressure            float64
	FinalResilience         float64
	FinalLearningCapacity   float64
	CumulativeIntervention  float64
}

func simulate(s Scenario, steps int) Result {
	state := make([]float64, steps)
	pressure := make([]float64, steps)
	resilience := make([]float64, steps)
	learning := make([]float64, steps)
	intervention := make([]float64, steps)
	bufferRemaining := make([]float64, steps)

	state[0] = 70.0
	pressure[0] = 50.0
	resilience[0] = 30.0
	bufferRemaining[0] = s.BufferCapacity

	for t := 1; t < steps; t++ {
		observedIndex := t - s.InformationDelay
		if observedIndex < 0 {
			observedIndex = 0
		}

		delayedSignal := state[observedIndex]
		currentSignal := state[t-1]
		observedState := s.InformationQuality*currentSignal + (1.0-s.InformationQuality)*delayedSignal

		currentGain := s.FeedbackGain
		if s.HasRule && observedState > s.RuleThreshold {
			currentGain = s.RuleFeedbackGain
		}

		learning[t] = math.Min(100.0, learning[t-1]+s.SelfOrganizationRate*(100.0-learning[t-1])/8.0)

		resilienceGap := math.Max(0.0, 100.0-resilience[t-1])
		resilienceInvestment := s.GoalWeightResilience * resilienceGap

		bufferAbsorption := math.Min(bufferRemaining[t-1], 0.10*pressure[t-1])
		bufferRemaining[t] = math.Max(0.0, bufferRemaining[t-1]-bufferAbsorption+0.02*s.BufferCapacity)

		correction := 0.0
		if t+1 >= s.ImplementationDelay {
			correction = s.ExternalCorrection + 0.05*math.Max(0.0, observedState-40.0) + resilienceInvestment + 0.04*learning[t]
		}

		intervention[t] = correction

		pressure[t] = math.Max(0.0, 0.91*pressure[t-1]+0.07*state[t-1]-0.30*correction-0.08*bufferAbsorption-0.04*resilience[t-1])
		resilience[t] = math.Min(100.0, math.Max(0.0, resilience[t-1]+0.18*resilienceInvestment+0.05*learning[t]-0.025*pressure[t-1]))
		state[t] = math.Max(0.0, currentGain*state[t-1]+0.24*pressure[t]-0.34*correction-0.08*bufferAbsorption-0.045*resilience[t])
	}

	maximumState := state[0]
	meanPressure := 0.0
	cumulativeIntervention := 0.0

	for i := 0; i < steps; i++ {
		if state[i] > maximumState {
			maximumState = state[i]
		}
		meanPressure += pressure[i]
		cumulativeIntervention += intervention[i]
	}

	meanPressure /= float64(steps)

	return Result{
		InitialState:           state[0],
		FinalState:             state[steps-1],
		MaximumState:           maximumState,
		MeanPressure:           meanPressure,
		FinalResilience:        resilience[steps-1],
		FinalLearningCapacity:  learning[steps-1],
		CumulativeIntervention: cumulativeIntervention,
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline", 0.96, 2.0, 6, 0.70, 0.0, 0.0, 0.96, 0.00, 0.00, 1, false},
		{"parameter_intervention", 0.96, 5.0, 6, 0.70, 0.0, 0.0, 0.96, 0.00, 0.00, 1, false},
		{"feedback_intervention", 0.78, 2.0, 6, 0.70, 0.0, 0.0, 0.78, 0.00, 0.00, 1, false},
		{"rule_intervention", 0.96, 2.0, 2, 0.85, 0.0, 45.0, 0.70, 0.00, 0.00, 1, true},
		{"goal_intervention", 0.90, 2.0, 2, 0.90, 10.0, 45.0, 0.72, 0.12, 0.10, 1, true},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_leverage_intervention_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "initial_state", "final_state", "maximum_state", "mean_pressure", "final_resilience", "final_learning_capacity", "cumulative_intervention", "behavior_change_from_baseline", "leverage_ratio"})

	results := make(map[string]Result)
	for _, scenario := range scenarios {
		results[scenario.Name] = simulate(scenario, 96)
	}

	baselineFinal := results["baseline"].FinalState

	for _, scenario := range scenarios {
		result := results[scenario.Name]
		behaviorChange := baselineFinal - result.FinalState
		leverageRatio := 0.0
		if result.CumulativeIntervention > 0.0 {
			leverageRatio = behaviorChange / result.CumulativeIntervention
		}

		writer.Write([]string{
			scenario.Name,
			fmt.Sprintf("%.6f", result.InitialState),
			fmt.Sprintf("%.6f", result.FinalState),
			fmt.Sprintf("%.6f", result.MaximumState),
			fmt.Sprintf("%.6f", result.MeanPressure),
			fmt.Sprintf("%.6f", result.FinalResilience),
			fmt.Sprintf("%.6f", result.FinalLearningCapacity),
			fmt.Sprintf("%.6f", result.CumulativeIntervention),
			fmt.Sprintf("%.6f", behaviorChange),
			fmt.Sprintf("%.6f", leverageRatio),
		})
	}

	fmt.Println("Go leverage diagnostics runner complete.")
	fmt.Println(path)
}
