package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Stakeholder struct {
	Name        string
	Access      float64
	Cost        float64
	Resilience  float64
	Equity      float64
	Feasibility float64
}

type Scenario struct {
	Name        string
	Access      float64
	Cost        float64
	Resilience  float64
	Equity      float64
	Feasibility float64
}

func score(stakeholder Stakeholder, scenario Scenario) float64 {
	return stakeholder.Access*scenario.Access +
		stakeholder.Cost*scenario.Cost +
		stakeholder.Resilience*scenario.Resilience +
		stakeholder.Equity*scenario.Equity +
		stakeholder.Feasibility*scenario.Feasibility
}

func mean(values []float64) float64 {
	total := 0.0
	for _, value := range values {
		total += value
	}
	return total / math.Max(float64(len(values)), 1.0)
}

func stddev(values []float64) float64 {
	mu := mean(values)
	total := 0.0
	for _, value := range values {
		total += (value - mu) * (value - mu)
	}
	return math.Sqrt(total / math.Max(float64(len(values)), 1.0))
}

func minMax(values []float64) (float64, float64) {
	minimum := values[0]
	maximum := values[0]
	for _, value := range values {
		if value < minimum {
			minimum = value
		}
		if value > maximum {
			maximum = value
		}
	}
	return minimum, maximum
}

func main() {
	stakeholders := []Stakeholder{
		{"community_residents", 0.30, 0.10, 0.20, 0.30, 0.10},
		{"frontline_staff", 0.20, 0.15, 0.25, 0.20, 0.20},
		{"technical_experts", 0.15, 0.20, 0.30, 0.15, 0.20},
		{"public_agency", 0.20, 0.25, 0.25, 0.15, 0.15},
		{"service_users", 0.35, 0.10, 0.15, 0.30, 0.10},
		{"resource_managers", 0.15, 0.20, 0.30, 0.15, 0.20},
	}

	scenarios := []Scenario{
		{"targeted_service_expansion", 0.85, 0.55, 0.65, 0.90, 0.60},
		{"infrastructure_repair_priority", 0.55, 0.65, 0.85, 0.50, 0.75},
		{"digital_monitoring_platform", 0.60, 0.50, 0.70, 0.45, 0.70},
		{"community_led_resilience", 0.75, 0.70, 0.80, 0.85, 0.55},
		{"baseline_policy_continuation", 0.40, 0.90, 0.35, 0.30, 0.85},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_participatory_scenario_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"mean_score",
		"disagreement_sd",
		"minimum_score",
		"maximum_score",
		"score_range",
		"legitimacy_adjusted_score",
		"consensus_label",
	})

	for _, scenario := range scenarios {
		values := make([]float64, 0, len(stakeholders))
		for _, stakeholder := range stakeholders {
			values = append(values, score(stakeholder, scenario))
		}

		mu := mean(values)
		sd := stddev(values)
		minimum, maximum := minMax(values)
		legitimacyAdjusted := mu - 0.50*sd

		label := "low disagreement"
		if sd >= 0.08 {
			label = "high disagreement"
		} else if sd >= 0.04 {
			label = "moderate disagreement"
		}

		writer.Write([]string{
			scenario.Name,
			fmt.Sprintf("%.6f", mu),
			fmt.Sprintf("%.6f", sd),
			fmt.Sprintf("%.6f", minimum),
			fmt.Sprintf("%.6f", maximum),
			fmt.Sprintf("%.6f", maximum-minimum),
			fmt.Sprintf("%.6f", legitimacyAdjusted),
			label,
		})
	}

	fmt.Println("Go participatory diagnostics runner complete.")
	fmt.Println(path)
}
