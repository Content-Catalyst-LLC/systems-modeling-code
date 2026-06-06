package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name              string
	ArrivalMultiplier float64
	CompletionShift  float64
	ExtractionBefore float64
	ExtractionAfter  float64
	ResourcePolicyTime int
	MaintenanceBefore float64
	MaintenanceAfter  float64
	MaintenancePolicyTime int
}

type Summary struct {
	Scenario       string
	Stock          string
	InitialValue   float64
	FinalValue     float64
	MinimumValue   float64
	MaximumValue   float64
	MeanNetFlow    float64
}

func simulate(s Scenario, steps int) []Summary {
	backlog := 80.0
	resource := 600.0
	condition := 72.0

	backlogValues := make([]float64, 0, steps)
	resourceValues := make([]float64, 0, steps)
	conditionValues := make([]float64, 0, steps)
	backlogNetFlows := make([]float64, 0, steps)
	resourceNetFlows := make([]float64, 0, steps)
	conditionNetFlows := make([]float64, 0, steps)

	for time := 1; time <= steps; time++ {
		arrivals := 18.0 * s.ArrivalMultiplier
		if (s.Name == "capacity_and_conservation" || s.Name == "adaptive_recovery") && time >= 50 {
			arrivals = 18.0 * 0.72 * s.ArrivalMultiplier
		}
		if s.Name == "delayed_response" && time >= 75 {
			arrivals = 18.0 * 0.72 * s.ArrivalMultiplier
		}

		extraction := s.ExtractionBefore
		if time >= s.ResourcePolicyTime {
			extraction = s.ExtractionAfter
		}

		maintenance := s.MaintenanceBefore
		if time >= s.MaintenancePolicyTime {
			maintenance = s.MaintenanceAfter
		}

		completions := math.Min(backlog+arrivals, 12.0+s.CompletionShift+0.08*backlog)
		backlogNet := arrivals - completions
		backlog = math.Max(0.0, backlog+backlogNet)

		regeneration := 0.045 * resource * (1.0 - resource/1000.0)
		resourceNet := regeneration - extraction
		resource = math.Max(0.0, resource+resourceNet)

		wear := 1.4 + 0.012*math.Max(0.0, 100.0-condition)
		conditionNet := maintenance - wear
		condition = math.Min(100.0, math.Max(0.0, condition+conditionNet))

		backlogValues = append(backlogValues, backlog)
		resourceValues = append(resourceValues, resource)
		conditionValues = append(conditionValues, condition)
		backlogNetFlows = append(backlogNetFlows, backlogNet)
		resourceNetFlows = append(resourceNetFlows, resourceNet)
		conditionNetFlows = append(conditionNetFlows, conditionNet)
	}

	return []Summary{
		summarize(s.Name, "backlog", backlogValues, backlogNetFlows),
		summarize(s.Name, "resource", resourceValues, resourceNetFlows),
		summarize(s.Name, "infrastructure_condition", conditionValues, conditionNetFlows),
	}
}

func summarize(scenario string, stock string, values []float64, netFlows []float64) Summary {
	minimum := values[0]
	maximum := values[0]
	totalNet := 0.0

	for i := range values {
		minimum = math.Min(minimum, values[i])
		maximum = math.Max(maximum, values[i])
		totalNet += netFlows[i]
	}

	return Summary{
		Scenario:     scenario,
		Stock:        stock,
		InitialValue: values[0],
		FinalValue:   values[len(values)-1],
		MinimumValue: minimum,
		MaximumValue: maximum,
		MeanNetFlow:  totalNet / float64(len(netFlows)),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline", 1.00, 0.00, 24.0, 24.0, 999, 0.9, 0.9, 999},
		{"capacity_and_conservation", 0.85, 2.0, 22.0, 12.0, 70, 1.2, 2.8, 60},
		{"delayed_response", 1.00, 1.5, 24.0, 12.0, 85, 0.9, 2.8, 85},
		{"adaptive_recovery", 0.90, 3.0, 22.0, 10.0, 55, 1.4, 3.4, 50},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_stock_flow_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "stock", "initial_value", "final_value", "minimum_value", "maximum_value", "mean_net_flow"})

	for _, scenario := range scenarios {
		for _, summary := range simulate(scenario, 120) {
			writer.Write([]string{
				summary.Scenario,
				summary.Stock,
				fmt.Sprintf("%.6f", summary.InitialValue),
				fmt.Sprintf("%.6f", summary.FinalValue),
				fmt.Sprintf("%.6f", summary.MinimumValue),
				fmt.Sprintf("%.6f", summary.MaximumValue),
				fmt.Sprintf("%.6f", summary.MeanNetFlow),
			})
		}
	}

	fmt.Println("Go stock-flow diagnostics runner complete.")
	fmt.Println(path)
}
