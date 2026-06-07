package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name          string
	ForwardStart  float64
	ForwardEnd    float64
	Steps         int
	InitialState  float64
	DT            float64
	JumpThreshold float64
}

type Summary struct {
	Scenario          string
	Path              string
	InitialState      float64
	FinalState        float64
	MinimumState      float64
	MaximumState      float64
	MaximumJumpSize   float64
	TransitionFlags   int
}

func updateState(x float64, r float64, dt float64) float64 {
	return x + dt*(r+x-x*x*x)
}

func linearSpace(start float64, stop float64, count int) []float64 {
	values := make([]float64, count)
	step := (stop - start) / float64(count-1)

	for i := 0; i < count; i++ {
		values[i] = start + float64(i)*step
	}

	return values
}

func simulatePath(s Scenario, pathName string, values []float64, initialState float64) Summary {
	x := initialState
	initialX := x
	minimumState := x
	maximumState := x
	maximumJump := 0.0
	transitionFlags := 0

	for stepIndex, r := range values {
		previousX := x

		if stepIndex > 0 {
			x = updateState(x, r, s.DT)
		}

		jump := math.Abs(x - previousX)
		if jump > s.JumpThreshold {
			transitionFlags++
		}

		minimumState = math.Min(minimumState, x)
		maximumState = math.Max(maximumState, x)
		maximumJump = math.Max(maximumJump, jump)
	}

	return Summary{
		Scenario:        s.Name,
		Path:            pathName,
		InitialState:    initialX,
		FinalState:      x,
		MinimumState:    minimumState,
		MaximumState:    maximumState,
		MaximumJumpSize: maximumJump,
		TransitionFlags: transitionFlags,
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_hysteresis", -1.20, 1.20, 300, -1.00, 0.050, 0.150},
		{"slow_forcing", -1.20, 1.20, 500, -1.00, 0.035, 0.120},
		{"fast_forcing", -1.20, 1.20, 150, -1.00, 0.075, 0.220},
		{"wide_forcing", -1.45, 1.45, 360, -1.10, 0.050, 0.150},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_critical_transition_hysteresis_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "path", "initial_state", "final_state", "minimum_state", "maximum_state", "maximum_jump_size", "transition_flags"})

	for _, scenario := range scenarios {
		forwardValues := linearSpace(scenario.ForwardStart, scenario.ForwardEnd, scenario.Steps)
		forwardSummary := simulatePath(scenario, "forward_forcing", forwardValues, scenario.InitialState)

		backwardValues := linearSpace(scenario.ForwardEnd, scenario.ForwardStart, scenario.Steps)
		backwardSummary := simulatePath(scenario, "backward_forcing", backwardValues, forwardSummary.FinalState)

		for _, result := range []Summary{forwardSummary, backwardSummary} {
			writer.Write([]string{
				result.Scenario,
				result.Path,
				fmt.Sprintf("%.6f", result.InitialState),
				fmt.Sprintf("%.6f", result.FinalState),
				fmt.Sprintf("%.6f", result.MinimumState),
				fmt.Sprintf("%.6f", result.MaximumState),
				fmt.Sprintf("%.6f", result.MaximumJumpSize),
				fmt.Sprintf("%d", result.TransitionFlags),
			})
		}
	}

	fmt.Println("Go tipping diagnostics runner complete.")
	fmt.Println(path)
}
