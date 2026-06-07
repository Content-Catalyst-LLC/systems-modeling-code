package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                  string
	NSteps                int
	DemandSensitivity     float64
	InvestmentSensitivity float64
	InterestRate          float64
	Depreciation          float64
	CreditSensitivity     float64
	ShockStep             int
	ShockSize             float64
}

type Summary struct {
	Scenario          string
	FinalOutput       float64
	FinalCapital      float64
	FinalDebt         float64
	FinalFragility    float64
	MaximumFragility  float64
	MinimumOutput     float64
	AverageOutput     float64
}

func deterministicNoise(step int) float64 {
	return math.Sin(float64(step)*1.61803398875) * 0.35
}

func simulate(s Scenario) Summary {
	output := 100.0
	capital := 190.0
	debt := 60.0
	government := 22.0

	maxFragility := debt / capital
	minOutput := output
	totalOutput := 0.0

	for step := 1; step <= s.NSteps; step++ {
		consumption := math.Max(0.0, 18.0+s.DemandSensitivity*output-0.025*debt)
		investment := math.Max(0.0, s.InvestmentSensitivity*output-s.InterestRate*debt)

		if step > 1 {
			capital = math.Max(0.0, capital+investment-s.Depreciation*capital)
			newCredit := math.Max(0.0, s.CreditSensitivity*investment)
			repayment := 0.025 * debt
			debt = math.Max(0.0, debt+newCredit-repayment)

			shock := 0.0
			if step == s.ShockStep {
				shock = s.ShockSize
			}

			output = math.Max(0.0, 0.33*capital+consumption+government+shock+deterministicNoise(step))
		}

		fragility := debt / math.Max(capital, 1.0)

		if fragility > maxFragility {
			maxFragility = fragility
		}
		if output < minOutput {
			minOutput = output
		}

		totalOutput += output
	}

	return Summary{
		Scenario:         s.Name,
		FinalOutput:      output,
		FinalCapital:     capital,
		FinalDebt:        debt,
		FinalFragility:   debt / math.Max(capital, 1.0),
		MaximumFragility: maxFragility,
		MinimumOutput:    minOutput,
		AverageOutput:    totalOutput / float64(s.NSteps),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_feedback", 120, 0.62, 0.16, 0.035, 0.045, 0.10, 70, -8.0},
		{"higher_investment", 120, 0.62, 0.21, 0.035, 0.045, 0.10, 70, -8.0},
		{"tighter_credit", 120, 0.62, 0.16, 0.055, 0.045, 0.10, 70, -8.0},
		{"larger_shock", 120, 0.62, 0.16, 0.035, 0.045, 0.10, 70, -18.0},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_economic_feedback_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "final_output", "final_capital", "final_debt", "final_fragility", "maximum_fragility", "minimum_output", "average_output", "diagnostic_label"})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "moderate fragility pathway"
		if result.MaximumFragility > 0.75 {
			label = "high fragility pathway"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalOutput),
			fmt.Sprintf("%.6f", result.FinalCapital),
			fmt.Sprintf("%.6f", result.FinalDebt),
			fmt.Sprintf("%.6f", result.FinalFragility),
			fmt.Sprintf("%.6f", result.MaximumFragility),
			fmt.Sprintf("%.6f", result.MinimumOutput),
			fmt.Sprintf("%.6f", result.AverageOutput),
			label,
		})
	}

	fmt.Println("Go economic diagnostics runner complete.")
	fmt.Println(path)
}
