package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                string
	N                   int
	NoiseScale          float64
	StructuralWeight    float64
	ResidualStrength    float64
	InteractionStrength float64
	DriftStrength       float64
}

func deterministicNoise(index int, scale float64) float64 {
	return math.Sin(float64(index)*1.61803398875) * scale
}

func baseline(a, b, c, structuralWeight float64) float64 {
	return structuralWeight * (1.8*math.Sin(a) + 0.6*b - 0.4*c)
}

func simulateSummary(s Scenario) (float64, float64, float64, float64, float64) {
	var baselineSquared float64
	var hybridSquared float64
	var baselineAbs float64
	var hybridAbs float64
	count := 0.0

	for i := 0; i < s.N; i++ {
		share := float64(i) / math.Max(float64(s.N-1), 1.0)
		a := math.Mod(float64(i)*0.137, 10.0)
		b := math.Sin(float64(i)*0.071) * 3.0
		c := 1.0 + math.Mod(float64(i)*0.173, 7.0)

		structuralBaseline := baseline(a, b, c, s.StructuralWeight)
		trueResidual := s.ResidualStrength*b*b + s.InteractionStrength*a*b + s.DriftStrength*share*b + deterministicNoise(i, s.NoiseScale)
		trueResponse := structuralBaseline + trueResidual

		learnedResidual := s.ResidualStrength*b*b + s.InteractionStrength*a*b + s.DriftStrength*share*b
		hybridPrediction := structuralBaseline + learnedResidual

		baselineError := trueResponse - structuralBaseline
		hybridError := trueResponse - hybridPrediction

		baselineSquared += baselineError * baselineError
		hybridSquared += hybridError * hybridError
		baselineAbs += math.Abs(baselineError)
		hybridAbs += math.Abs(hybridError)
		count += 1.0
	}

	baselineRMSE := math.Sqrt(baselineSquared / count)
	hybridRMSE := math.Sqrt(hybridSquared / count)
	baselineMAE := baselineAbs / count
	hybridMAE := hybridAbs / count
	improvement := (baselineRMSE - hybridRMSE) / math.Max(baselineRMSE, 1e-12)

	return baselineRMSE, hybridRMSE, baselineMAE, hybridMAE, improvement
}

func main() {
	scenarios := []Scenario{
		{"baseline_hybrid", 1000, 0.50, 1.00, 0.70, 0.25, 0.00},
		{"high_noise_system", 1000, 0.95, 1.00, 0.70, 0.25, 0.00},
		{"strong_residual_system", 1000, 0.50, 1.00, 1.10, 0.38, 0.00},
		{"drifting_system", 1000, 0.55, 1.00, 0.70, 0.25, 0.45},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_ai_hybrid_metrics.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"baseline_rmse",
		"hybrid_rmse",
		"baseline_mae",
		"hybrid_mae",
		"hybrid_improvement_ratio",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		baseRMSE, hybridRMSE, baseMAE, hybridMAE, improvement := simulateSummary(scenario)
		label := "hybrid improved baseline"
		if hybridRMSE >= baseRMSE {
			label = "hybrid did not improve baseline"
		}

		writer.Write([]string{
			scenario.Name,
			fmt.Sprintf("%.6f", baseRMSE),
			fmt.Sprintf("%.6f", hybridRMSE),
			fmt.Sprintf("%.6f", baseMAE),
			fmt.Sprintf("%.6f", hybridMAE),
			fmt.Sprintf("%.6f", improvement),
			label,
		})
	}

	fmt.Println("Go AI systems diagnostics runner complete.")
	fmt.Println(path)
}
