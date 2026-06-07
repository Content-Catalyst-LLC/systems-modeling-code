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
	TargetState          float64
	SystemState          float64
	InstitutionalCapacity float64
	Trust                float64
	AdministrativeBurden float64
	PolicyIntensity      float64
	MaxPolicy            float64
	MinPolicy            float64
	PolicyIncreaseRate   float64
	PolicyDecreaseRate   float64
	PolicyEffect         float64
	CapacityLearningRate float64
	BurdenGrowth         float64
	BurdenRelief         float64
	SideEffectRate       float64
}

type Summary struct {
	Scenario               string
	FinalSystemState       float64
	FinalPolicyIntensity   float64
	FinalCapacity          float64
	FinalTrust             float64
	MaximumBurden          float64
	MaximumSideEffect      float64
	AverageUptake          float64
	AveragePolicyIntensity float64
}

func bounded(value float64, low float64, high float64) float64 {
	return math.Max(low, math.Min(high, value))
}

func deterministicNoise(step int) float64 {
	return math.Sin(float64(step)*1.61803398875) * 0.12
}

func simulate(s Scenario) Summary {
	systemState := s.SystemState
	capacity := s.InstitutionalCapacity
	trust := s.Trust
	burden := s.AdministrativeBurden
	policy := s.PolicyIntensity
	sideEffect := 0.0

	maxBurden := burden
	maxSideEffect := sideEffect
	totalUptake := 0.0
	totalPolicy := 0.0

	for step := 0; step < s.Steps; step++ {
		uptake := bounded(0.42+0.30*trust+0.035*capacity-0.45*burden, 0.0, 1.0)
		gap := s.TargetState - systemState

		if gap > 0.0 {
			policy = math.Min(s.MaxPolicy, policy+s.PolicyIncreaseRate)
		} else {
			policy = math.Max(s.MinPolicy, policy-s.PolicyDecreaseRate)
		}

		nextState := systemState + s.PolicyEffect*policy*uptake - 0.12*systemState + 0.05*capacity + deterministicNoise(step)
		nextCapacity := capacity + s.CapacityLearningRate*(systemState-capacity)
		nextBurden := math.Max(0.0, burden+s.BurdenGrowth*policy-s.BurdenRelief*capacity)
		nextSideEffect := math.Max(0.0, sideEffect+s.SideEffectRate*policy-0.06*sideEffect)
		nextTrust := bounded(trust+0.015*uptake-0.018*nextBurden-0.010*nextSideEffect, 0.0, 1.0)

		totalUptake += uptake
		totalPolicy += policy
		maxBurden = math.Max(maxBurden, burden)
		maxSideEffect = math.Max(maxSideEffect, sideEffect)

		systemState = math.Max(0.0, nextState)
		capacity = math.Max(0.0, nextCapacity)
		burden = nextBurden
		sideEffect = nextSideEffect
		trust = nextTrust
	}

	return Summary{
		Scenario:               s.Name,
		FinalSystemState:       systemState,
		FinalPolicyIntensity:   policy,
		FinalCapacity:          capacity,
		FinalTrust:             trust,
		MaximumBurden:          maxBurden,
		MaximumSideEffect:      maxSideEffect,
		AverageUptake:          totalUptake / float64(s.Steps),
		AveragePolicyIntensity: totalPolicy / float64(s.Steps),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_adaptive_policy", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08},
		{"aggressive_policy_rule", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.4, 0.25, 0.14, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08},
		{"low_capacity_learning", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.035, 0.05, 0.025, 0.08},
		{"high_burden_design", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.10, 0.025, 0.08},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_public_policy_adaptive_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"final_system_state",
		"final_policy_intensity",
		"final_capacity",
		"final_trust",
		"maximum_burden",
		"maximum_side_effect",
		"average_uptake",
		"average_policy_intensity",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "manageable policy pathway"
		if result.MaximumBurden > 1.0 || result.MaximumSideEffect > 1.0 {
			label = "high burden policy pathway"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalSystemState),
			fmt.Sprintf("%.6f", result.FinalPolicyIntensity),
			fmt.Sprintf("%.6f", result.FinalCapacity),
			fmt.Sprintf("%.6f", result.FinalTrust),
			fmt.Sprintf("%.6f", result.MaximumBurden),
			fmt.Sprintf("%.6f", result.MaximumSideEffect),
			fmt.Sprintf("%.6f", result.AverageUptake),
			fmt.Sprintf("%.6f", result.AveragePolicyIntensity),
			label,
		})
	}

	fmt.Println("Go public policy diagnostics runner complete.")
	fmt.Println(path)
}
