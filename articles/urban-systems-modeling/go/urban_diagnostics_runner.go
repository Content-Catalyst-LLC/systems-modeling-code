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
	Steps                     int
	Population                float64
	Housing                   float64
	Transport                 float64
	ServiceCapacity           float64
	GrowthPressure            float64
	AccessibilityAttraction   float64
	CongestionPenalty         float64
	HousingConstraintPenalty  float64
	HousingBuildRate          float64
	TransportInvestmentRate   float64
	ServiceInvestmentRate     float64
	PeriodicPolicyInvestment  float64
	PolicyInterval            int
	PressurePenalty           float64
}

type Summary struct {
	Scenario               string
	FinalPopulation        float64
	FinalHousing           float64
	FinalTransport         float64
	FinalServiceCapacity   float64
	FinalAccessibility     float64
	MaximumServicePressure float64
	MaximumHousingGap      float64
}

func deterministicNoise(step int) float64 {
	return math.Sin(float64(step)*1.61803398875) * 0.10
}

func simulate(s Scenario) Summary {
	population := s.Population
	housing := s.Housing
	transport := s.Transport
	serviceCapacity := s.ServiceCapacity

	maxServicePressure := 0.0
	maxHousingGap := 0.0
	finalAccessibility := 0.0

	for step := 1; step <= s.Steps; step++ {
		accessibility := transport / (1.0 + 0.010*population)
		congestion := population / math.Max(transport, 1.0)
		housingGap := math.Max(population-housing, 0.0)
		servicePressure := population / math.Max(serviceCapacity, 1.0)

		if servicePressure > maxServicePressure {
			maxServicePressure = servicePressure
		}
		if housingGap > maxHousingGap {
			maxHousingGap = housingGap
		}
		finalAccessibility = accessibility

		policyInvestment := 0.0
		if step%s.PolicyInterval == 0 {
			policyInvestment = s.PeriodicPolicyInvestment
		}

		pressureDrag := s.PressurePenalty * math.Max(servicePressure-1.0, 0.0)
		congestionDrag := s.CongestionPenalty * math.Max(congestion-1.0, 0.0)
		housingDrag := s.HousingConstraintPenalty * housingGap / 20.0

		populationChange := s.GrowthPressure +
			s.AccessibilityAttraction*accessibility/55.0 -
			congestionDrag -
			housingDrag -
			pressureDrag +
			deterministicNoise(step)

		population = math.Max(0.0, population+populationChange)
		housing = math.Max(0.0, housing+s.HousingBuildRate+0.020*population-0.004*housing)
		transport = math.Max(1.0, transport+s.TransportInvestmentRate+0.010*housing-0.030*math.Max(congestion-1.0, 0.0))
		serviceCapacity = math.Max(1.0, serviceCapacity+s.ServiceInvestmentRate+policyInvestment-0.003*serviceCapacity)
	}

	return Summary{
		Scenario:               s.Name,
		FinalPopulation:        population,
		FinalHousing:           housing,
		FinalTransport:         transport,
		FinalServiceCapacity:   serviceCapacity,
		FinalAccessibility:     finalAccessibility,
		MaximumServicePressure: maxServicePressure,
		MaximumHousingGap:      maxHousingGap,
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_neighborhood", 100, 100, 112, 90, 120, 1.10, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35, 8, 20, 0.70},
		{"strong_growth_pressure", 100, 100, 112, 90, 120, 1.65, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35, 8, 20, 0.70},
		{"housing_constraint", 100, 100, 106, 90, 120, 1.10, 1.25, 0.70, 0.55, 0.25, 0.45, 0.35, 8, 20, 0.70},
		{"transport_investment", 100, 100, 112, 90, 120, 1.10, 1.25, 0.70, 0.45, 0.65, 1.15, 0.85, 10, 20, 0.70},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_urban_system_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"final_population",
		"final_housing",
		"final_transport",
		"final_service_capacity",
		"final_accessibility",
		"maximum_service_pressure",
		"maximum_housing_gap",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "managed growth pathway"
		if result.MaximumServicePressure > 1.0 || result.MaximumHousingGap > 10.0 {
			label = "capacity constrained pathway"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalPopulation),
			fmt.Sprintf("%.6f", result.FinalHousing),
			fmt.Sprintf("%.6f", result.FinalTransport),
			fmt.Sprintf("%.6f", result.FinalServiceCapacity),
			fmt.Sprintf("%.6f", result.FinalAccessibility),
			fmt.Sprintf("%.6f", result.MaximumServicePressure),
			fmt.Sprintf("%.6f", result.MaximumHousingGap),
			label,
		})
	}

	fmt.Println("Go urban diagnostics runner complete.")
	fmt.Println(path)
}
