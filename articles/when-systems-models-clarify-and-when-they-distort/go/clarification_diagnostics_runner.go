package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
)

type ModelCase struct {
	Name                   string
	StructuralClarity      float64
	DynamicClarity         float64
	ScenarioClarity        float64
	AssumptionTransparency float64
	FalsePrecisionRisk     float64
	BoundaryRisk           float64
	ProxyRisk              float64
	MisuseRisk             float64
}

func clarificationScore(m ModelCase) float64 {
	return 0.30*m.StructuralClarity + 0.25*m.DynamicClarity + 0.25*m.ScenarioClarity + 0.20*m.AssumptionTransparency
}

func distortionRiskScore(m ModelCase) float64 {
	return 0.25*m.FalsePrecisionRisk + 0.30*m.BoundaryRisk + 0.20*m.ProxyRisk + 0.25*m.MisuseRisk
}

func useLabel(net float64) string {
	if net >= 0.20 {
		return "strong_clarification_with_managed_risk"
	}
	if net >= 0.0 {
		return "useful_with_strong_caveats"
	}
	return "high_distortion_risk_without_revision"
}

func main() {
	cases := []ModelCase{
		{"infrastructure_resilience_model", 0.85, 0.70, 0.80, 0.65, 0.45, 0.65, 0.45, 0.50},
		{"public_health_capacity_model", 0.75, 0.85, 0.70, 0.60, 0.55, 0.70, 0.55, 0.65},
		{"urban_accessibility_model", 0.70, 0.50, 0.60, 0.70, 0.60, 0.75, 0.70, 0.55},
		{"energy_transition_pathway_model", 0.80, 0.80, 0.85, 0.55, 0.50, 0.65, 0.50, 0.60},
		{"machine_learning_risk_model", 0.45, 0.40, 0.35, 0.35, 0.85, 0.70, 0.85, 0.90},
		{"digital_twin_operations_model", 0.75, 0.65, 0.70, 0.50, 0.70, 0.60, 0.50, 0.75},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_clarification_distortion_model_cases.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"model_case", "clarification_score", "distortion_risk_score", "net_interpretive_value", "use_label"})

	for _, item := range cases {
		clarification := clarificationScore(item)
		distortion := distortionRiskScore(item)
		net := clarification - distortion

		writer.Write([]string{
			item.Name,
			fmt.Sprintf("%.6f", clarification),
			fmt.Sprintf("%.6f", distortion),
			fmt.Sprintf("%.6f", net),
			useLabel(net),
		})
	}

	fmt.Println("Go clarification diagnostics runner complete.")
	fmt.Println(path)
}
