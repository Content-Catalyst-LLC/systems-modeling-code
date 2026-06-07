package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
)

type ModelResult struct {
	ID                    string
	Type                  string
	LowerBound            float64
	UpperBound            float64
	AssumptionDisclosure  float64
	UncertaintyDisclosure float64
	BoundaryDisclosure    float64
	MisuseWarning          float64
}

func communicationQuality(r ModelResult) float64 {
	return 0.30*r.AssumptionDisclosure + 0.30*r.UncertaintyDisclosure + 0.20*r.BoundaryDisclosure + 0.20*r.MisuseWarning
}

func falsePrecisionLabel(r ModelResult) string {
	width := r.UpperBound - r.LowerBound
	if r.UncertaintyDisclosure < 0.60 && width > 0.20 {
		return "high_false_precision_risk"
	}
	if r.UncertaintyDisclosure < 0.70 {
		return "moderate_false_precision_risk"
	}
	return "lower_false_precision_risk"
}

func main() {
	results := []ModelResult{
		{"R1", "scenario", 0.55, 0.88, 0.80, 0.85, 0.70, 0.75},
		{"R2", "forecast", 9000.0, 16000.0, 0.60, 0.75, 0.55, 0.60},
		{"R3", "ranking", 0.75, 0.89, 0.70, 0.55, 0.65, 0.45},
		{"R4", "map", 0.40, 0.82, 0.45, 0.40, 0.50, 0.40},
		{"R5", "optimization", 0.80, 0.96, 0.65, 0.60, 0.60, 0.55},
		{"R6", "dashboard", 0.62, 0.86, 0.55, 0.50, 0.55, 0.35},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_model_result_communication_diagnostics.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"result_id", "result_type", "uncertainty_width", "communication_quality_score", "false_precision_risk"})

	for _, r := range results {
		width := r.UpperBound - r.LowerBound
		writer.Write([]string{
			r.ID,
			r.Type,
			fmt.Sprintf("%.6f", width),
			fmt.Sprintf("%.6f", communicationQuality(r)),
			falsePrecisionLabel(r),
		})
	}

	fmt.Println("Go communication diagnostics runner complete.")
	fmt.Println(path)
}
