package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Assumption struct {
	ID          string
	Category    string
	Uncertainty float64
	Sensitivity float64
	Consequence float64
}

type Boundary struct {
	Name              string
	CapitalCost       float64
	ServiceReliability float64
	EquityPerformance float64
	LongTermResilience float64
}

func riskScore(a Assumption) float64 {
	return a.Uncertainty * a.Sensitivity * a.Consequence
}

func riskLabel(score float64) string {
	if score >= 0.45 {
		return "high"
	}
	if score >= 0.25 {
		return "moderate"
	}
	return "lower"
}

func boundaryScore(b Boundary) float64 {
	return 0.20*b.CapitalCost + 0.30*b.ServiceReliability + 0.25*b.EquityPerformance + 0.25*b.LongTermResilience
}

func main() {
	assumptions := []Assumption{
		{"A1", "boundary", 0.80, 0.75, 0.90},
		{"A2", "data", 0.55, 0.60, 0.70},
		{"A3", "parameter", 0.40, 0.85, 0.65},
		{"A4", "behavioral", 0.70, 0.50, 0.60},
		{"A5", "scenario", 0.65, 0.80, 0.85},
		{"A6", "normative", 0.75, 0.90, 0.95},
		{"A7", "scale", 0.50, 0.65, 0.75},
		{"A8", "causal", 0.45, 0.80, 0.80},
		{"A9", "measurement", 0.70, 0.70, 0.85},
	}

	boundaries := []Boundary{
		{"narrow_asset_boundary", 0.80, 0.60, 0.35, 0.50},
		{"expanded_service_boundary", 0.72, 0.75, 0.55, 0.65},
		{"community_resilience_boundary", 0.65, 0.78, 0.85, 0.78},
		{"long_horizon_boundary", 0.60, 0.82, 0.70, 0.90},
		{"multi_stakeholder_boundary", 0.62, 0.76, 0.88, 0.82},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	assumptionPath := filepath.Join(outputDir, "go_assumption_register.csv")
	assumptionFile, err := os.Create(assumptionPath)
	if err != nil {
		panic(err)
	}
	defer assumptionFile.Close()

	assumptionWriter := csv.NewWriter(assumptionFile)
	defer assumptionWriter.Flush()

	assumptionWriter.Write([]string{"assumption_id", "category", "uncertainty", "sensitivity", "consequence", "risk_score", "risk_label"})

	for _, assumption := range assumptions {
		score := riskScore(assumption)
		assumptionWriter.Write([]string{
			assumption.ID,
			assumption.Category,
			fmt.Sprintf("%.6f", assumption.Uncertainty),
			fmt.Sprintf("%.6f", assumption.Sensitivity),
			fmt.Sprintf("%.6f", assumption.Consequence),
			fmt.Sprintf("%.6f", score),
			riskLabel(score),
		})
	}

	boundaryPath := filepath.Join(outputDir, "go_boundary_scenario_comparison.csv")
	boundaryFile, err := os.Create(boundaryPath)
	if err != nil {
		panic(err)
	}
	defer boundaryFile.Close()

	boundaryWriter := csv.NewWriter(boundaryFile)
	defer boundaryWriter.Flush()

	boundaryWriter.Write([]string{"boundary", "capital_cost", "service_reliability", "equity_performance", "long_term_resilience", "composite_score"})

	for _, boundary := range boundaries {
		score := boundaryScore(boundary)
		score = math.Max(0.0, math.Min(1.0, score))
		boundaryWriter.Write([]string{
			boundary.Name,
			fmt.Sprintf("%.6f", boundary.CapitalCost),
			fmt.Sprintf("%.6f", boundary.ServiceReliability),
			fmt.Sprintf("%.6f", boundary.EquityPerformance),
			fmt.Sprintf("%.6f", boundary.LongTermResilience),
			fmt.Sprintf("%.6f", score),
		})
	}

	fmt.Println("Go boundary diagnostics runner complete.")
	fmt.Println(boundaryPath)
}
