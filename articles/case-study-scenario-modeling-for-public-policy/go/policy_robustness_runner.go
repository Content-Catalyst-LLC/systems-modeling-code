package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
)

type Summary struct {
	Policy          string
	AverageScore    float64
	WorstCaseScore  float64
	BestCaseScore   float64
	MaximumRegret   float64
	AcceptableShare float64
	RobustnessScore float64
}

func main() {
	summaries := []Summary{
		{"adaptive_pathway", 0.617, 0.557, 0.684, 0.000, 1.000, 0.591},
		{"targeted_intervention", 0.550, 0.493, 0.622, 0.093, 0.833, 0.502},
		{"universal_program", 0.545, 0.473, 0.628, 0.112, 0.667, 0.485},
		{"status_quo_maintenance", 0.380, 0.338, 0.423, 0.275, 0.000, 0.292},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_policy_robustness_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"policy", "average_score", "worst_case_score", "best_case_score", "maximum_regret", "acceptable_scenario_share", "robustness_score"})

	for _, item := range summaries {
		writer.Write([]string{
			item.Policy,
			fmt.Sprintf("%.6f", item.AverageScore),
			fmt.Sprintf("%.6f", item.WorstCaseScore),
			fmt.Sprintf("%.6f", item.BestCaseScore),
			fmt.Sprintf("%.6f", item.MaximumRegret),
			fmt.Sprintf("%.6f", item.AcceptableShare),
			fmt.Sprintf("%.6f", item.RobustnessScore),
		})
	}

	fmt.Println("Go policy robustness runner complete.")
	fmt.Println(path)
}
