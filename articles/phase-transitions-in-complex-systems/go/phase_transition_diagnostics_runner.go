package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type BranchRow struct {
	ControlParameter       float64
	OrderParameterMagnitude float64
	PhaseLabel             string
}

func linearValue(start float64, stop float64, index int, count int) float64 {
	step := (stop - start) / float64(count-1)
	return start + float64(index)*step
}

func main() {
	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_bifurcation_order_parameter_branches.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"step", "control_parameter", "stable_state_positive", "stable_state_negative", "neutral_state", "order_parameter_magnitude", "phase_label"})

	count := 301

	for index := 0; index < count; index++ {
		control := linearValue(-1.5, 1.5, index, count)
		positive := 0.0
		negative := 0.0
		magnitude := 0.0
		label := "single neutral phase"

		if control > 0.0 {
			positive = math.Sqrt(control)
			negative = -math.Sqrt(control)
			magnitude = positive
			label = "two ordered phases"
		}

		writer.Write([]string{
			fmt.Sprintf("%d", index+1),
			fmt.Sprintf("%.6f", control),
			fmt.Sprintf("%.6f", positive),
			fmt.Sprintf("%.6f", negative),
			fmt.Sprintf("%.6f", 0.0),
			fmt.Sprintf("%.6f", magnitude),
			label,
		})
	}

	fmt.Println("Go phase-transition diagnostics runner complete.")
	fmt.Println(path)
}
