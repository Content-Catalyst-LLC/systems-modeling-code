package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                 string
	Steps                int
	InitialCapacity      float64
	InitialDemand        float64
	InitialTrust         float64
	DemandGrowth         float64
	PreventionEffect     float64
	WorkforceRecovery    float64
	BurnoutSensitivity   float64
	AttritionSensitivity float64
	HiringRate           float64
	AccessBarrier        float64
	TrustLossRate        float64
	TrustGainRate        float64
	SurgeStart           int
	SurgeEnd             int
	SurgeIntensity       float64
}

type Summary struct {
	Scenario         string
	FinalCapacity    float64
	FinalBacklog     float64
	FinalTrust       float64
	MaximumPressure  float64
	MaximumBurnout   float64
	TotalUnmetNeed   float64
	AverageAccessGap float64
	MinimumTrust     float64
}

func bounded(value float64, low float64, high float64) float64 {
	return math.Max(low, math.Min(high, value))
}

func deterministicNoise(step int) float64 {
	return math.Sin(float64(step)*1.61803398875) * 0.004
}

func simulate(s Scenario) Summary {
	capacity := s.InitialCapacity
	demand := s.InitialDemand
	trust := s.InitialTrust
	backlog := 0.0
	burnout := 0.12

	maxPressure := 0.0
	maxBurnout := burnout
	totalUnmetNeed := 0.0
	totalAccessGap := 0.0
	minTrust := trust

	for step := 0; step < s.Steps; step++ {
		pressure := demand / math.Max(capacity, 1.0)
		slack := math.Max(1.0-pressure, 0.0)
		burnout = math.Max(0.0, burnout+s.BurnoutSensitivity*math.Max(pressure-1.0, 0.0)-s.WorkforceRecovery*slack)
		attrition := s.AttritionSensitivity * burnout * capacity

		surge := 0.0
		if step >= s.SurgeStart && step <= s.SurgeEnd {
			surge = s.SurgeIntensity
		}

		effectiveCapacity := math.Max(0.0, capacity+s.HiringRate-attrition-0.10*math.Max(pressure-1.0, 0.0)*capacity)
		served := math.Min(demand, effectiveCapacity)
		unmetNeed := math.Max(demand-served, 0.0)
		accessGap := s.AccessBarrier*demand + unmetNeed
		backlog = math.Max(0.0, backlog+demand-served)
		trust = bounded(trust+s.TrustGainRate*slack-s.TrustLossRate*math.Max(pressure-1.0, 0.0)-0.004*accessGap/math.Max(demand, 1.0)+deterministicNoise(step), 0.0, 1.0)

		maxPressure = math.Max(maxPressure, pressure)
		maxBurnout = math.Max(maxBurnout, burnout)
		totalUnmetNeed += unmetNeed
		totalAccessGap += accessGap
		minTrust = math.Min(minTrust, trust)

		capacity = effectiveCapacity
		preventionReduction := s.PreventionEffect * float64(step+1)
		demand = math.Max(0.0, s.InitialDemand+s.DemandGrowth*float64(step+1)+surge-preventionReduction+0.08*backlog)
	}

	return Summary{s.Name, capacity, backlog, trust, maxPressure, maxBurnout, totalUnmetNeed, totalAccessGap / float64(s.Steps), minTrust}
}

func main() {
	scenarios := []Scenario{
		{"baseline_health_system", 120, 100, 92, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18},
		{"higher_demand_growth", 120, 100, 92, 0.64, 0.65, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18},
		{"stronger_prevention", 120, 100, 92, 0.70, 0.35, 0.060, 0.035, 0.085, 0.030, 0.50, 0.16, 0.018, 0.018, 45, 65, 18},
		{"larger_surge", 120, 100, 92, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 32},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_health_system_summary.csv")
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
		"final_backlog",
		"final_trust",
		"maximum_pressure",
		"maximum_burnout",
		"total_unmet_need",
		"average_access_gap",
		"minimum_trust",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "manageable health system pathway"
		if result.MaximumPressure > 1.25 || result.TotalUnmetNeed > 1000 || result.MinimumTrust < 0.35 {
			label = "high strain health system pathway"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalCapacity),
			fmt.Sprintf("%.6f", result.FinalBacklog),
			fmt.Sprintf("%.6f", result.FinalTrust),
			fmt.Sprintf("%.6f", result.MaximumPressure),
			fmt.Sprintf("%.6f", result.MaximumBurnout),
			fmt.Sprintf("%.6f", result.TotalUnmetNeed),
			fmt.Sprintf("%.6f", result.AverageAccessGap),
			fmt.Sprintf("%.6f", result.MinimumTrust),
			label,
		})
	}

	fmt.Println("Go health system diagnostics runner complete.")
	fmt.Println(path)
}
