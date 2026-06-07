package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

func main() {
	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_adaptive_monitoring.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"time", "true_state", "observed_state", "estimated_state", "residual", "drift_indicator", "intervention_flag"})

	trueState := 12.0
	estimate := 12.0
	drift := 0.0

	for t := 0; t < 24; t++ {
		shock := 0.0
		if t == 8 || t == 16 {
			shock = 4.0
		}

		trueState = 0.93*trueState + 0.3*math.Sin(float64(t)/10.0) + shock
		observed := trueState + 0.4*math.Sin(float64(t)/3.0)

		prediction := 0.93*estimate + 0.3*math.Sin(float64(t)/10.0)
		residual := observed - prediction
		intervention := 0

		if math.Abs(residual) > 3.0 {
			intervention = 1
			prediction = prediction + 0.25*residual
		}

		estimate = 0.70*prediction + 0.30*observed
		drift = 0.80*drift + 0.20*math.Abs(observed-estimate)

		writer.Write([]string{
			fmt.Sprintf("%d", t),
			fmt.Sprintf("%.6f", trueState),
			fmt.Sprintf("%.6f", observed),
			fmt.Sprintf("%.6f", estimate),
			fmt.Sprintf("%.6f", residual),
			fmt.Sprintf("%.6f", drift),
			fmt.Sprintf("%d", intervention),
		})
	}

	fmt.Println("Go adaptive monitoring runner complete.")
	fmt.Println(path)
}
