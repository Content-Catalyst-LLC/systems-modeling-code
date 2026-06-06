package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"math/rand"
	"os"
	"path/filepath"
)

func simulateModel(growthRate float64, carryingCapacity float64, nSteps int, initialState float64) []float64 {
	values := make([]float64, nSteps)
	values[0] = initialState

	for i := 1; i < nSteps; i++ {
		previous := values[i-1]
		nextValue := previous + growthRate*previous*(1.0-previous/carryingCapacity)
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

	nSteps := 80
	trainCutoff := 52
	trueGrowth := 0.095
	trueCapacity := 120.0

	trueState := simulateModel(trueGrowth, trueCapacity, nSteps, 10.0)
	observed := make([]float64, nSteps)

	for i := range observed {
		observed[i] = trueState[i] + rng.NormFloat64()*0.85
		if observed[i] < 0.0 {
			observed[i] = 0.0
		}
	}

	trainObserved := observed[:trainCutoff]
	validObserved := observed[trainCutoff:]

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_calibration_validation_grid.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"candidate_id", "growth_rate", "carrying_capacity", "calibration_rmse", "validation_rmse", "generalization_gap"})

	candidateID := 0

	for gi := 0; gi <= 64; gi++ {
		growthRate := 0.040 + float64(gi)*(0.200-0.040)/64.0

		for ci := 0; ci <= 44; ci++ {
			capacity := 70.0 + float64(ci)*(180.0-70.0)/44.0
			candidateID++

			trainPred := simulateModel(growthRate, capacity, len(trainObserved), trainObserved[0])
			validPred := simulateModel(growthRate, capacity, len(validObserved)+1, trainObserved[len(trainObserved)-1])[1:]

			calibrationRMSE := rmse(trainObserved, trainPred)
			validationRMSE := rmse(validObserved, validPred)

			writer.Write([]string{
				fmt.Sprintf("%d", candidateID),
				fmt.Sprintf("%.6f", growthRate),
				fmt.Sprintf("%.6f", capacity),
				fmt.Sprintf("%.6f", calibrationRMSE),
				fmt.Sprintf("%.6f", validationRMSE),
				fmt.Sprintf("%.6f", validationRMSE-calibrationRMSE),
			})
		}
	}

	fmt.Println("Go calibration and validation runner complete.")
	fmt.Println(path)
}
