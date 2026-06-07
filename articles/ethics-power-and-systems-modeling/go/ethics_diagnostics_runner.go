package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
)

type Stakeholder struct {
	Name            string
	Affected        float64
	Represented     int
	Influence       float64
	ExpectedBenefit float64
	ExpectedBurden  float64
}

func burdenLabel(score float64) string {
	if score >= 0.45 {
		return "high_power_burden_gap"
	}
	if score >= 0.20 {
		return "moderate_power_burden_gap"
	}
	return "lower_power_burden_gap"
}

func main() {
	stakeholders := []Stakeholder{
		{"public_agency", 0.40, 1, 0.95, 0.80, 0.20},
		{"technical_modelers", 0.20, 1, 0.85, 0.65, 0.15},
		{"frontline_workers", 0.70, 1, 0.45, 0.55, 0.35},
		{"affected_residents", 0.95, 1, 0.35, 0.50, 0.60},
		{"low_access_households", 1.00, 0, 0.10, 0.35, 0.80},
		{"future_generations", 0.90, 0, 0.00, 0.40, 0.75},
		{"local_environment", 0.85, 0, 0.05, 0.30, 0.70},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_ethics_stakeholder_distributional_diagnostics.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"group", "affected", "represented", "influence", "expected_benefit",
		"expected_burden", "net_benefit", "burden_gap", "power_burden_gap", "risk_label",
	})

	for _, s := range stakeholders {
		netBenefit := s.ExpectedBenefit - s.ExpectedBurden
		burdenGap := s.ExpectedBurden - s.ExpectedBenefit
		powerBurdenGap := s.Affected * s.ExpectedBurden * (1.0 - s.Influence)

		writer.Write([]string{
			s.Name,
			fmt.Sprintf("%.6f", s.Affected),
			fmt.Sprintf("%d", s.Represented),
			fmt.Sprintf("%.6f", s.Influence),
			fmt.Sprintf("%.6f", s.ExpectedBenefit),
			fmt.Sprintf("%.6f", s.ExpectedBurden),
			fmt.Sprintf("%.6f", netBenefit),
			fmt.Sprintf("%.6f", burdenGap),
			fmt.Sprintf("%.6f", powerBurdenGap),
			burdenLabel(powerBurdenGap),
		})
	}

	fmt.Println("Go ethics diagnostics runner complete.")
	fmt.Println(path)
}
