package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name               string
	Steps              int
	InitialState       float64
	StatePersistence   float64
	DriftAmplitude     float64
	ProcessNoise       float64
	ObservationNoise   float64
	UpdateGain         float64
	AnomalyThreshold   float64
	InterventionEffect float64
	ShockMagnitude     float64
}

func deterministicNoise(step int, scale float64) float64 {
	return math.Sin(float64(step)*1.61803398875) * scale
}

func shockAt(step int) bool {
	return step == 35 || step == 80 || step == 105
}

func simulate(s Scenario) (float64, float64, float64, float64, int, int, float64) {
	trueState := make([]float64, s.Steps)
	observedState := make([]float64, s.Steps)
	twinState := make([]float64, s.Steps)

	anomalyCount := 0
	interventionCount := 0

	trueState[0] = s.InitialState
	observedState[0] = trueState[0] + deterministicNoise(0, s.ObservationNoise)
	twinState[0] = observedState[0]

	for step := 1; step < s.Steps; step++ {
		drift := s.DriftAmplitude * math.Sin(float64(step)/12.0)
		shock := 0.0
		if shockAt(step) {
			shock = s.ShockMagnitude
		}

		trueState[step] = s.StatePersistence*trueState[step-1] + drift + shock + deterministicNoise(step, s.ProcessNoise)
		observedState[step] = trueState[step] + deterministicNoise(step+200, s.ObservationNoise)

		prediction := s.StatePersistence*twinState[step-1] + drift
		residual := observedState[step] - prediction

		if math.Abs(residual) > s.AnomalyThreshold {
			anomalyCount++
		}

		if residual > s.AnomalyThreshold {
			interventionCount++
			prediction -= s.InterventionEffect
		}

		twinState[step] = prediction + s.UpdateGain*residual
	}

	observedAbs := 0.0
	twinAbs := 0.0
	observedSquared := 0.0
	twinSquared := 0.0

	for step := 0; step < s.Steps; step++ {
		observedError := observedState[step] - trueState[step]
		twinError := twinState[step] - trueState[step]
		observedAbs += math.Abs(observedError)
		twinAbs += math.Abs(twinError)
		observedSquared += observedError * observedError
		twinSquared += twinError * twinError
	}

	n := float64(s.Steps)
	observedMAE := observedAbs / n
	twinMAE := twinAbs / n
	observedRMSE := math.Sqrt(observedSquared / n)
	twinRMSE := math.Sqrt(twinSquared / n)
	improvement := (observedRMSE - twinRMSE) / math.Max(observedRMSE, 1e-12)

	return observedMAE, twinMAE, observedRMSE, twinRMSE, anomalyCount, interventionCount, improvement
}

func main() {
	scenarios := []Scenario{
		{"baseline_twin", 120, 50, 0.95, 0.15, 0.60, 1.80, 0.35, 3.50, 1.00, 4.0},
		{"high_noise_twin", 120, 50, 0.95, 0.15, 0.60, 3.20, 0.30, 4.80, 1.00, 4.0},
		{"slow_update_twin", 120, 50, 0.95, 0.15, 0.60, 1.80, 0.18, 3.50, 1.00, 4.0},
		{"resilient_twin", 120, 50, 0.95, 0.15, 0.45, 1.25, 0.45, 3.25, 1.25, 3.5},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_digital_twin_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"MAE_observed",
		"MAE_twin",
		"RMSE_observed",
		"RMSE_twin",
		"anomaly_count",
		"intervention_count",
		"tracking_improvement_ratio",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		observedMAE, twinMAE, observedRMSE, twinRMSE, anomalyCount, interventionCount, improvement := simulate(scenario)
		label := "twin improved noisy observation"
		if twinRMSE >= observedRMSE {
			label = "twin did not improve noisy observation"
		}

		writer.Write([]string{
			scenario.Name,
			fmt.Sprintf("%.6f", observedMAE),
			fmt.Sprintf("%.6f", twinMAE),
			fmt.Sprintf("%.6f", observedRMSE),
			fmt.Sprintf("%.6f", twinRMSE),
			fmt.Sprintf("%d", anomalyCount),
			fmt.Sprintf("%d", interventionCount),
			fmt.Sprintf("%.6f", improvement),
			label,
		})
	}

	fmt.Println("Go digital twin diagnostics runner complete.")
	fmt.Println(path)
}
