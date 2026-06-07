package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name           string
	Steps          int
	StabilityStart float64
	StabilityEnd   float64
	NoiseSD        float64
	Window         int
}

type Summary struct {
	Scenario               string
	FinalStability         float64
	FinalState             float64
	MaximumAbsState        float64
	FinalRollingVariance   float64
}

func linearValue(start float64, stop float64, index int, count int) float64 {
	step := (stop - start) / float64(count-1)
	return start + float64(index)*step
}

func deterministicNoise(index int, scale float64) float64 {
	return math.Sin(float64(index)*1.61803398875) * scale
}

func rollingVariance(values []float64) float64 {
	if len(values) < 2 {
		return 0.0
	}

	total := 0.0
	for _, value := range values {
		total += value
	}
	meanValue := total / float64(len(values))

	ss := 0.0
	for _, value := range values {
		delta := value - meanValue
		ss += delta * delta
	}

	return ss / float64(len(values)-1)
}

func simulate(s Scenario) Summary {
	state := 0.0
	maximumAbsState := 0.0
	finalVariance := 0.0
	history := []float64{}

	for index := 0; index < s.Steps; index++ {
		stability := linearValue(s.StabilityStart, s.StabilityEnd, index, s.Steps)

		if index > 0 {
			state = stability*state + deterministicNoise(index, s.NoiseSD)
		}

		history = append(history, state)
		maximumAbsState = math.Max(maximumAbsState, math.Abs(state))

		if len(history) >= s.Window {
			recent := history[len(history)-s.Window:]
			finalVariance = rollingVariance(recent)
		}
	}

	return Summary{
		Scenario:             s.Name,
		FinalStability:       s.StabilityEnd,
		FinalState:           state,
		MaximumAbsState:      maximumAbsState,
		FinalRollingVariance: finalVariance,
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_destabilization", 320, 0.55, 0.985, 1.00, 25},
		{"moderate_destabilization", 320, 0.45, 0.900, 1.00, 25},
		{"high_noise_destabilization", 320, 0.55, 0.985, 1.40, 25},
		{"low_noise_destabilization", 320, 0.55, 0.985, 0.65, 25},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_early_warning_indicator_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "final_stability", "final_state", "maximum_abs_state", "final_rolling_variance"})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalStability),
			fmt.Sprintf("%.6f", result.FinalState),
			fmt.Sprintf("%.6f", result.MaximumAbsState),
			fmt.Sprintf("%.6f", result.FinalRollingVariance),
		})
	}

	fmt.Println("Go early-warning diagnostics runner complete.")
	fmt.Println(path)
}
