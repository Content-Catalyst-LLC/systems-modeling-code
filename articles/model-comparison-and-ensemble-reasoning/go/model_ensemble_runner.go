package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"math/rand"
	"os"
	"path/filepath"
)

func simulateManaged(growth float64, capacity float64, extraction float64, steps int, initial float64) []float64 {
	values := make([]float64, steps)
	values[0] = initial

	for i := 1; i < steps; i++ {
		previous := values[i-1]
		nextValue := previous + growth*previous*(1.0-previous/capacity) - extraction*previous
		if nextValue < 0.0 {
			nextValue = 0.0
		}
		values[i] = nextValue
	}

	return values
}

func simulateLogistic(growth float64, capacity float64, steps int, initial float64) []float64 {
	values := make([]float64, steps)
	values[0] = initial

	for i := 1; i < steps; i++ {
		previous := values[i-1]
		nextValue := previous + growth*previous*(1.0-previous/capacity)
		if nextValue < 0.0 {
			nextValue = 0.0
		}
		values[i] = nextValue
	}

	return values
}

func rmse(actual []float64, predicted []float64) float64 {
	total := 0.0
	for i := range actual {
		diff := actual[i] - predicted[i]
		total += diff * diff
	}
	return math.Sqrt(total / float64(len(actual)))
}

func main() {
	rng := rand.New(rand.NewSource(42))

	steps := 90
	trainCutoff := 60
	trueState := simulateManaged(0.085, 130.0, 0.012, steps, 12.0)
	observed := make([]float64, steps)

	for i := 0; i < steps; i++ {
		observed[i] = trueState[i] + rng.NormFloat64()*1.1
		if observed[i] < 0.0 {
			observed[i] = 0.0
		}
	}

	models := map[string][]float64{
		"logistic_low":       simulateLogistic(0.070, 115.0, steps, observed[0]),
		"logistic_high":      simulateLogistic(0.095, 145.0, steps, observed[0]),
		"managed_reference":  simulateManaged(0.085, 130.0, 0.012, steps, observed[0]),
		"managed_high_press": simulateManaged(0.090, 140.0, 0.020, steps, observed[0]),
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_model_ensemble_metrics.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"model", "calibration_rmse", "validation_rmse", "generalization_gap"})

	for modelName, prediction := range models {
		calibrationRMSE := rmse(observed[:trainCutoff], prediction[:trainCutoff])
		validationRMSE := rmse(observed[trainCutoff:], prediction[trainCutoff:])

		writer.Write([]string{
			modelName,
			fmt.Sprintf("%.6f", calibrationRMSE),
			fmt.Sprintf("%.6f", validationRMSE),
			fmt.Sprintf("%.6f", validationRMSE-calibrationRMSE),
		})
	}

	fmt.Println("Go model ensemble runner complete.")
	fmt.Println(path)
}
