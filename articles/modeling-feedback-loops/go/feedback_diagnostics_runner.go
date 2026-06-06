package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

func simulateDelayedBalancing(initial float64, target float64, correction float64, delay int, steps int) []float64 {
	values := make([]float64, steps)
	values[0] = initial

	for t := 1; t < steps; t++ {
		delayedIndex := t - delay
		if delayedIndex < 0 {
			delayedIndex = 0
		}
		values[t] = values[t-1] + correction*(target-values[delayedIndex])
	}

	return values
}

func targetCrossings(values []float64, target float64) int {
	changes := 0

	for i := 1; i < len(values); i++ {
		left := values[i-1] - target
		right := values[i] - target

		if left == 0.0 || right == 0.0 {
			continue
		}

		if (left < 0.0 && right > 0.0) || (left > 0.0 && right < 0.0) {
			changes++
		}
	}

	return changes
}

func meanAbsoluteGap(values []float64, target float64) float64 {
	total := 0.0
	for _, value := range values {
		total += math.Abs(value - target)
	}
	return total / float64(len(values))
}

func main() {
	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_delayed_feedback_ensemble.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario_id", "delay", "correction_strength", "final_state", "maximum_state", "minimum_state", "overshoot_above_target", "target_crossings", "mean_absolute_target_gap"})

	scenarioID := 0
	target := 20.0

	for _, delay := range []int{1, 3, 5, 8, 12} {
		for _, correction := range []float64{0.12, 0.20, 0.28, 0.36} {
			scenarioID++
			values := simulateDelayedBalancing(5.0, target, correction, delay, 90)

			maximum := values[0]
			minimum := values[0]
			for _, value := range values {
				if value > maximum {
					maximum = value
				}
				if value < minimum {
					minimum = value
				}
			}

			overshoot := maximum - target
			if overshoot < 0.0 {
				overshoot = 0.0
			}

			writer.Write([]string{
				fmt.Sprintf("%d", scenarioID),
				fmt.Sprintf("%d", delay),
				fmt.Sprintf("%.6f", correction),
				fmt.Sprintf("%.6f", values[len(values)-1]),
				fmt.Sprintf("%.6f", maximum),
				fmt.Sprintf("%.6f", minimum),
				fmt.Sprintf("%.6f", overshoot),
				fmt.Sprintf("%d", targetCrossings(values, target)),
				fmt.Sprintf("%.6f", meanAbsoluteGap(values, target)),
			})
		}
	}

	fmt.Println("Go feedback diagnostics runner complete.")
	fmt.Println(path)
}
