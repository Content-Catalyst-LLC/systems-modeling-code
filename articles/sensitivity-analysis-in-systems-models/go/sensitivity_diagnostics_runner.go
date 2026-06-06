package main

import (
	"encoding/csv"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
)

type Parameters struct {
	GrowthRate         float64
	CarryingCapacity   float64
	ExtractionPressure float64
	RecoveryDelay      int
	FeedbackStrength   float64
	ShockIntensity     float64
}

type Result struct {
	FinalState   float64
	MaximumState float64
	MinimumState float64
	MeanState    float64
}

func simulateSystem(p Parameters) Result {
	steps := 80
	state := make([]float64, steps)
	state[0] = 10.0
	shockTime := steps / 2

	for time := 1; time < steps; time++ {
		delayedIndex := time - p.RecoveryDelay
		if delayedIndex < 0 {
			delayedIndex = 0
		}

		delayedRecovery := p.FeedbackStrength * state[delayedIndex]
		shockEffect := 0.0
		if time == shockTime {
			shockEffect = p.ShockIntensity
		}

		previous := state[time-1]
		nextState := previous +
			p.GrowthRate*previous*(1.0-previous/p.CarryingCapacity) -
			p.ExtractionPressure*previous +
			delayedRecovery -
			shockEffect

		if nextState < 0.0 {
			nextState = 0.0
		}
		state[time] = nextState
	}

	maximum := state[0]
	minimum := state[0]
	total := 0.0

	for _, value := range state {
		if value > maximum {
			maximum = value
		}
		if value < minimum {
			minimum = value
		}
		total += value
	}

	return Result{
		FinalState:   state[steps-1],
		MaximumState: maximum,
		MinimumState: minimum,
		MeanState:    total / float64(steps),
	}
}

func main() {
	rng := rand.New(rand.NewSource(60606))

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_sensitivity_diagnostics.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"run_id", "growth_rate", "carrying_capacity", "extraction_pressure", "recovery_delay", "feedback_strength", "shock_intensity", "final_state", "maximum_state", "minimum_state", "mean_state"})

	for runID := 1; runID <= 400; runID++ {
		p := Parameters{
			GrowthRate:         0.04 + rng.Float64()*(0.12-0.04),
			CarryingCapacity:   60.0 + rng.Float64()*80.0,
			ExtractionPressure: 0.005 + rng.Float64()*(0.060-0.005),
			RecoveryDelay:      1 + rng.Intn(12),
			FeedbackStrength:   0.005 + rng.Float64()*(0.050-0.005),
			ShockIntensity:     rng.Float64() * 24.0,
		}

		result := simulateSystem(p)

		writer.Write([]string{
			fmt.Sprintf("%d", runID),
			fmt.Sprintf("%.6f", p.GrowthRate),
			fmt.Sprintf("%.6f", p.CarryingCapacity),
			fmt.Sprintf("%.6f", p.ExtractionPressure),
			fmt.Sprintf("%d", p.RecoveryDelay),
			fmt.Sprintf("%.6f", p.FeedbackStrength),
			fmt.Sprintf("%.6f", p.ShockIntensity),
			fmt.Sprintf("%.6f", result.FinalState),
			fmt.Sprintf("%.6f", result.MaximumState),
			fmt.Sprintf("%.6f", result.MinimumState),
			fmt.Sprintf("%.6f", result.MeanState),
		})
	}

	fmt.Println("Go sensitivity diagnostics runner complete.")
	fmt.Println(path)
}
