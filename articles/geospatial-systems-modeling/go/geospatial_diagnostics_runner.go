package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                      string
	GridSize                  int
	HazardMultiplier          float64
	VulnerabilityMultiplier   float64
	PopulationMultiplier      float64
	ServiceCapacityMultiplier float64
	ServiceShift              int
}

type Service struct {
	ID       string
	X        float64
	Y        float64
	Capacity float64
}

type Summary struct {
	Scenario          string
	CellCount         int
	Population        float64
	TotalRisk         float64
	AverageRisk       float64
	AverageAccess     float64
	AverageServiceGap float64
}

func distance(x1, y1, x2, y2 float64) float64 {
	return math.Sqrt(math.Pow(x1-x2, 2) + math.Pow(y1-y2, 2))
}

func services(shift int, capacityMultiplier float64) []Service {
	return []Service{
		{"clinic_a", float64(5 + shift), 6, 900 * capacityMultiplier},
		{"clinic_b", 9, float64(20 - shift), 650 * capacityMultiplier},
		{"clinic_c", float64(18 - shift), float64(10 + shift), 800 * capacityMultiplier},
		{"clinic_d", 22, 21, 500 * capacityMultiplier},
	}
}

func simulate(s Scenario) Summary {
	center := float64(s.GridSize+1) / 2.0
	serviceList := services(s.ServiceShift, s.ServiceCapacityMultiplier)

	cellCount := 0
	totalPopulation := 0.0
	totalRisk := 0.0
	totalAccess := 0.0
	totalGap := 0.0

	for x := 1; x <= s.GridSize; x++ {
		for y := 1; y <= s.GridSize; y++ {
			dCenter := distance(float64(x), float64(y), center, center)
			dRiver := math.Abs(float64(y) - (0.45*float64(x) + 4.0))

			population := math.Max(0, (120+500*math.Exp(-dCenter/7)+math.Sin(float64(x*y))*25)*s.PopulationMultiplier)
			hazard := math.Min(1.0, (math.Exp(-dRiver/3)+0.06)*s.HazardMultiplier)
			vulnerability := math.Min(1.0, math.Max(0.0, (0.25+0.45*math.Exp(-dCenter/9)+0.03*math.Sin(float64(x+y)))*s.VulnerabilityMultiplier))
			risk := hazard * population * vulnerability

			access := 0.0
			for _, service := range serviceList {
				d := distance(float64(x), float64(y), service.X, service.Y)
				access += service.Capacity * (1.0 / (1.0 + d*d))
			}

			gap := population / (access + 1.0)

			cellCount++
			totalPopulation += population
			totalRisk += risk
			totalAccess += access
			totalGap += gap
		}
	}

	count := math.Max(float64(cellCount), 1.0)
	return Summary{
		s.Name,
		cellCount,
		totalPopulation,
		totalRisk,
		totalRisk / count,
		totalAccess / count,
		totalGap / count,
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_spatial_system", 25, 1.00, 1.00, 1.00, 1.00, 0},
		{"higher_hazard_system", 25, 1.35, 1.00, 1.00, 1.00, 0},
		{"high_vulnerability_system", 25, 1.00, 1.35, 1.00, 1.00, 0},
		{"low_access_system", 25, 1.00, 1.00, 1.00, 0.65, 0},
		{"resilient_service_system", 25, 0.90, 0.90, 1.00, 1.30, 3},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_geospatial_priority_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"cell_count",
		"population",
		"total_risk_score",
		"average_risk_score",
		"average_accessibility",
		"average_service_gap_score",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "standard spatial pressure"
		if result.AverageRisk > 140 {
			label = "elevated spatial risk pressure"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%d", result.CellCount),
			fmt.Sprintf("%.6f", result.Population),
			fmt.Sprintf("%.6f", result.TotalRisk),
			fmt.Sprintf("%.6f", result.AverageRisk),
			fmt.Sprintf("%.6f", result.AverageAccess),
			fmt.Sprintf("%.6f", result.AverageServiceGap),
			label,
		})
	}

	fmt.Println("Go geospatial diagnostics runner complete.")
	fmt.Println(path)
}
