package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name                    string
	Steps                   int
	ShockStart              int
	ShockEnd                int
	PowerLossRate           float64
	PowerRecoveryRate       float64
	CommunicationsDependency float64
	WaterPowerDependency    float64
	WaterCommsDependency    float64
	TransportPowerDependency float64
	TransportCommsDependency float64
}

type Summary struct {
	Scenario               string
	FinalCompositeService  float64
	MinimumPower           float64
	MinimumCommunications  float64
	MinimumWater           float64
	MinimumTransport       float64
	MaximumUnmetService    float64
	TotalUnmetService      float64
}

func simulate(s Scenario) Summary {
	power := 1.0
	communications := 1.0
	water := 1.0
	transport := 1.0

	minPower := 1.0
	minCommunications := 1.0
	minWater := 1.0
	minTransport := 1.0
	maxUnmet := 0.0
	totalUnmet := 0.0
	finalComposite := 1.0

	for time := 0; time < s.Steps; time++ {
		if time >= s.ShockStart && time <= s.ShockEnd {
			power = math.Max(0.45, power-s.PowerLossRate)
		} else if time > s.ShockEnd {
			power = math.Min(1.0, power+s.PowerRecoveryRate)
		} else {
			power = 1.0
		}

		communications = math.Max(0.40, s.CommunicationsDependency*power+(1.0-s.CommunicationsDependency)*communications)
		water = math.Max(0.35, s.WaterPowerDependency*power+s.WaterCommsDependency*communications+(1.0-s.WaterPowerDependency-s.WaterCommsDependency)*water)
		transport = math.Max(0.35, s.TransportPowerDependency*power+s.TransportCommsDependency*communications+(1.0-s.TransportPowerDependency-s.TransportCommsDependency)*transport)

		composite := (power + communications + water + transport) / 4.0
		unmet := 1.0 - composite

		minPower = math.Min(minPower, power)
		minCommunications = math.Min(minCommunications, communications)
		minWater = math.Min(minWater, water)
		minTransport = math.Min(minTransport, transport)
		maxUnmet = math.Max(maxUnmet, unmet)
		totalUnmet += unmet
		finalComposite = composite
	}

	return Summary{s.Name, finalComposite, minPower, minCommunications, minWater, minTransport, maxUnmet, totalUnmet}
}

func main() {
	scenarios := []Scenario{
		{"baseline_cascade", 80, 20, 36, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25},
		{"larger_power_loss", 80, 20, 36, 0.055, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25},
		{"faster_recovery", 80, 20, 36, 0.035, 0.045, 0.72, 0.55, 0.25, 0.30, 0.25},
		{"longer_shock", 80, 20, 48, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_infrastructure_cascade_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{
		"scenario",
		"final_composite_service",
		"minimum_power",
		"minimum_communications",
		"minimum_water",
		"minimum_transport",
		"maximum_unmet_service",
		"total_unmet_service",
		"diagnostic_label",
	})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "managed cascade pathway"
		if result.MaximumUnmetService > 0.35 {
			label = "severe cascade pathway"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.FinalCompositeService),
			fmt.Sprintf("%.6f", result.MinimumPower),
			fmt.Sprintf("%.6f", result.MinimumCommunications),
			fmt.Sprintf("%.6f", result.MinimumWater),
			fmt.Sprintf("%.6f", result.MinimumTransport),
			fmt.Sprintf("%.6f", result.MaximumUnmetService),
			fmt.Sprintf("%.6f", result.TotalUnmetService),
			label,
		})
	}

	fmt.Println("Go infrastructure diagnostics runner complete.")
	fmt.Println(path)
}
