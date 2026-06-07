package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                   string
	Steps                  int
	InitialCapacity        float64
	InitialWorkload        float64
	InitialTrust           float64
	DemandGrowth           float64
	HiringRate             float64
	LearningRate           float64
	BurnoutSensitivity     float64
	RecoveryRate           float64
	AttritionSensitivity   float64
	CoordinationBurdenRate float64
	TrustLossRate          float64
	TrustGainRate          float64
}

type Summary struct {
	Scenario         string
	FinalCapacity    float64
	FinalWorkload    float64
	FinalBacklog     float64
	FinalTrust       float64
	MaximumPressure  float64
	MaximumBurnout   float64
	TotalAttrition   float64
	AverageDelivery  float64
	MinimumTrust     float64
}

func bounded(value float64, low float64, high float64) float64 {
	return math.Max(low, math.Min(high, value))
}

func deterministicNoise(step int) float64 {
	return math.Sin(float64(step)*1.61803398875) * 0.005
}

func simulate(s Scenario) Summary {
	capacity := s.InitialCapacity
	workload := s.InitialWorkload
	trust := s.InitialTrust
	backlog := 0.0
	burnout := 0.10

	maxPressure := 0.0
	maxBurnout := burnout
	totalAttrition := 0.0
	totalDelivery := 0.0
	minTrust := trust

	for step := 0; step < s.Steps; step++ {
		pressure := workload / math.Max(capacity, 1.0)
		slack := math.Max(1.0-pressure, 0.0)
		learning := s.LearningRate * capacity * slack * trust
		coordinationBurden := s.CoordinationBurdenRate * math.Max(pressure-1.0, 0.0) * capacity
		burnout = math.Max(0.0, burnout+s.BurnoutSensitivity*math.Max(pressure-1.0, 0.0)-s.RecoveryRate*slack)
		attrition := s.AttritionSensitivity * burnout * capacity
		effectiveCapacity := math.Max(0.0, capacity+s.HiringRate+learning-attrition-coordinationBurden)
		delivery := math.Min(workload, effectiveCapacity)
		backlog = math.Max(0.0, backlog+workload-delivery)
		trust = bounded(trust+s.TrustGainRate*slack-s.TrustLossRate*math.Max(pressure-1.0, 0.0)-0.005*burnout+deterministicNoise(step), 0.0, 1.0)

		maxPressure = math.Max(maxPressure, pressure)
		maxBurnout = math.Max(maxBurnout, burnout)
		totalAttrition += attrition
		totalDelivery += delivery
		minTrust = math.Min(minTrust, trust)

		capacity = effectiveCapacity
		workload = s.InitialWorkload + s.DemandGrowth*float64(step+1) + 0.10*backlog
	}

	return Summary{s.Name, capacity, workload, backlog, trust, maxPressure, maxBurnout, totalAttrition, totalDelivery / float64(s.Steps), minTrust}
}

func main() {
	scenarios := []Scenario{
		{"baseline_organization", 100, 100, 95, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010},
		{"high_demand_growth", 100, 100, 95, 0.62, 0.85, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010},
		{"faster_hiring", 100, 100, 95, 0.62, 0.45, 1.25, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010},
		{"high_coordination_burden", 100, 100, 95, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.22, 0.030, 0.010},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_organizational_system_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"final_capacity",
		"final_workload",
		"final_backlog",
		"final_trust",
		"maximum_pressure",
		"maximum_burnout",
		"total_attrition",
		"average_delivery",
		"minimum_trust",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "manageable operating pathway"
		if result.MaximumPressure > 1.25 || result.MaximumBurnout > 0.60 || result.MinimumTrust < 0.30 {
			label = "unsustainable operating pathway"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalCapacity),
			fmt.Sprintf("%.6f", result.FinalWorkload),
			fmt.Sprintf("%.6f", result.FinalBacklog),
			fmt.Sprintf("%.6f", result.FinalTrust),
			fmt.Sprintf("%.6f", result.MaximumPressure),
			fmt.Sprintf("%.6f", result.MaximumBurnout),
			fmt.Sprintf("%.6f", result.TotalAttrition),
			fmt.Sprintf("%.6f", result.AverageDelivery),
			fmt.Sprintf("%.6f", result.MinimumTrust),
			label,
		})
	}

	fmt.Println("Go organizational diagnostics runner complete.")
	fmt.Println(path)
}
