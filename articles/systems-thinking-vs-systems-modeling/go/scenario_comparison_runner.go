package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                    string
	DemandGrowth            float64
	CapacityGrowth          float64
	ReworkRate              float64
	TrustLossFromBacklog    float64
	TrustGainFromService    float64
	InterventionPressure    float64
	SystemsRedesignStrength float64
	DelayFactor             float64
	UncertaintyHumility     float64
}

func clamp(value, low, high float64) float64 {
	return math.Max(low, math.Min(high, value))
}

func simulate(s Scenario) []string {
	demand := 80.0
	capacity := 70.0
	backlog := 22.0
	trust := 58.0
	rework := 8.0
	learning := 22.0

	finalConceptualScore := 0.0
	finalModeledScore := 0.0
	maxBacklog := backlog
	minTrust := trust

	for period := 0; period <= 80; period++ {
		serviceGap := math.Max(demand+backlog-capacity, 0.0)
		serviceQuality := clamp(100.0-serviceGap*0.50-rework*0.35, 0.0, 100.0)

		conceptualScore := clamp(
			50.0+s.SystemsRedesignStrength*24.0+s.UncertaintyHumility*14.0-s.InterventionPressure*8.0-serviceGap*0.08,
			0.0,
			100.0,
		)

		modeledScore := clamp(
			serviceQuality*0.30+trust*0.25+learning*0.20+capacity*0.10-backlog*0.10-rework*0.15,
			0.0,
			100.0,
		)

		finalConceptualScore = conceptualScore
		finalModeledScore = modeledScore
		maxBacklog = math.Max(maxBacklog, backlog)
		minTrust = math.Min(minTrust, trust)

		pressureGain := s.InterventionPressure * 4.0
		redesignGain := s.SystemsRedesignStrength * 3.2
		delayedLearningEffect := learning * 0.03 * (1.0 - s.DelayFactor)

		demand = demand + s.DemandGrowth*demand
		capacity = capacity + s.CapacityGrowth*capacity + redesignGain + delayedLearningEffect - rework*0.015
		backlog = backlog + demand*0.10 + rework*0.30 - capacity*0.09 - redesignGain*0.80
		rework = rework + serviceGap*s.ReworkRate + pressureGain*0.15 - redesignGain*0.45
		trust = trust - backlog*s.TrustLossFromBacklog + serviceQuality*s.TrustGainFromService + redesignGain*0.10
		learning = learning + s.UncertaintyHumility*1.3 + s.SystemsRedesignStrength*1.1 - s.InterventionPressure*0.45

		demand = clamp(demand, 0.0, 200.0)
		capacity = clamp(capacity, 0.0, 200.0)
		backlog = clamp(backlog, 0.0, 200.0)
		trust = clamp(trust, 0.0, 100.0)
		rework = clamp(rework, 0.0, 120.0)
		learning = clamp(learning, 0.0, 100.0)
	}

	return []string{
		s.Name,
		fmt.Sprintf("%.6f", finalConceptualScore),
		fmt.Sprintf("%.6f", finalModeledScore),
		fmt.Sprintf("%.6f", finalConceptualScore-finalModeledScore),
		fmt.Sprintf("%.6f", maxBacklog),
		fmt.Sprintf("%.6f", minTrust),
	}
}

func main() {
	scenarios := []Scenario{
		{"linear_pressure_frame", 0.018, 0.006, 0.025, 0.010, 0.004, 0.82, 0.12, 0.70, 0.18},
		{"conceptual_systems_frame", 0.018, 0.010, 0.018, 0.007, 0.006, 0.48, 0.54, 0.45, 0.55},
		{"formal_model_learning_frame", 0.018, 0.014, 0.012, 0.005, 0.008, 0.28, 0.78, 0.25, 0.82},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_scenario_comparison.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "final_conceptual_score", "final_modeled_score", "conceptual_model_gap", "maximum_backlog", "minimum_trust"})
	for _, scenario := range scenarios {
		writer.Write(simulate(scenario))
	}

	fmt.Println("Go scenario comparison complete.")
	fmt.Println(path)
}
