package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

func logisticMap(r float64, initialState float64, steps int) []float64 {
	values := make([]float64, steps)
	values[0] = initialState

	for i := 1; i < steps; i++ {
		values[i] = r * values[i-1] * (1.0 - values[i-1])
	}

	return values
}

func entropy(values []float64, bins int) float64 {
	low := values[0]
	high := values[0]

	for _, value := range values {
		if value < low {
			low = value
		}
		if value > high {
			high = value
		}
	}

	if high == low {
		return 0.0
	}

	counts := make([]int, bins)

	for _, value := range values {
		index := int((value - low) / (high - low) * float64(bins))
		if index == bins {
			index = bins - 1
		}
		counts[index]++
	}

	total := 0
	for _, count := range counts {
		total += count
	}

	result := 0.0
	for _, count := range counts {
		if count > 0 {
			p := float64(count) / float64(total)
			result -= p * math.Log(p)
		}
	}

	return result
}

func main() {
	steps := 120
	trajectory1 := logisticMap(3.9, 0.4000, steps)
	trajectory2 := logisticMap(3.9, 0.4001, steps)

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_logistic_sensitivity.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"time", "trajectory_1", "trajectory_2", "absolute_difference"})

	maxDiff := 0.0
	sumDiff := 0.0

	for i := 0; i < steps; i++ {
		diff := math.Abs(trajectory1[i] - trajectory2[i])
		if diff > maxDiff {
			maxDiff = diff
		}
		sumDiff += diff

		writer.Write([]string{
			fmt.Sprintf("%d", i+1),
			fmt.Sprintf("%.8f", trajectory1[i]),
			fmt.Sprintf("%.8f", trajectory2[i]),
			fmt.Sprintf("%.8f", diff),
		})
	}

	summaryPath := filepath.Join(outputDir, "go_complexity_math_summary.csv")
	summaryFile, err := os.Create(summaryPath)
	if err != nil {
		panic(err)
	}
	defer summaryFile.Close()

	summaryWriter := csv.NewWriter(summaryFile)
	defer summaryWriter.Flush()

	summaryWriter.Write([]string{"metric", "value"})
	summaryWriter.Write([]string{"maximum_absolute_difference", fmt.Sprintf("%.8f", maxDiff)})
	summaryWriter.Write([]string{"mean_absolute_difference", fmt.Sprintf("%.8f", sumDiff/float64(steps))})
	summaryWriter.Write([]string{"trajectory_entropy", fmt.Sprintf("%.8f", entropy(trajectory1, 10))})

	fmt.Println("Go complex systems mathematics runner complete.")
	fmt.Println(path)
	fmt.Println(summaryPath)
}
