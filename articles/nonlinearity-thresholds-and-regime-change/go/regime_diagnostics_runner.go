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
	CollapseThreshold float64
	RecoveryThreshold float64
	InterventionTime  int
	PressureGrowth    float64
	RecoveryEffort    float64
}

type Summary struct {
	Scenario        string
	InitialState    float64
	FinalState      float64
	MinimumState    float64
	MaximumPressure float64
	DegradedPeriods int
	FinalRegime     string
	MeanNetFlow     float64
	HysteresisGap    float64
}

func simulate(s Scenario, steps int) Summary {
	systemState := 82.0
	initialState := systemState
	pressure := 20.0
	regime := "stable"

	minimumState := systemState
	maximumPressure := pressure
	degradedPeriods := 0
	totalNetFlow := 0.0

	for time := 1; time <= steps; time++ {
		damageFlow := 0.0
		recoveryFlow := 0.0
		netFlow := 0.0

		if time > 1 {
			pressure += s.PressureGrowth

			if time >= s.InterventionTime {
				pressure = math.Max(0.0, pressure-s.RecoveryEffort)
			}

			if regime == "stable" && pressure >= s.CollapseThreshold {
				regime = "degraded"
			} else if regime == "degraded" && pressure <= s.RecoveryThreshold {
				regime = "stable"
			}

			if regime == "stable" {
				damageFlow = 0.05*pressure + 0.002*pressure*pressure
				recoveryFlow = 2.6
			} else {
				damageFlow = 0.09*pressure + 0.006*pressure*pressure + 1.8
				recoveryFlow = 0.8 + 0.03*systemState
			}

			netFlow = recoveryFlow - damageFlow
			systemState = math.Min(100.0, math.Max(0.0, systemState+netFlow))
		}

		if regime == "degraded" {
			degradedPeriods++
		}

		minimumState = math.Min(minimumState, systemState)
		maximumPressure = math.Max(maximumPressure, pressure)
		totalNetFlow += netFlow
	}

	return Summary{
		Scenario:        s.Name,
		InitialState:    initialState,
		FinalState:      systemState,
		MinimumState:    minimumState,
		MaximumPressure: maximumPressure,
		DegradedPeriods: degradedPeriods,
		FinalRegime:     regime,
		MeanNetFlow:     totalNetFlow / float64(steps),
		HysteresisGap:   s.CollapseThreshold - s.RecoveryThreshold,
	}
}

func main() {
	scenarios := []Scenario{
		{"early_intervention", 70.0, 45.0, 55, 0.85, 1.20},
		{"late_intervention", 70.0, 45.0, 85, 0.85, 1.20},
		{"strong_recovery", 70.0, 45.0, 85, 0.85, 2.00},
		{"lower_threshold_stress", 58.0, 38.0, 70, 0.95, 1.20},
		{"hysteresis_trap", 66.0, 30.0, 88, 0.90, 1.30},
		{"rapid_prevention", 70.0, 45.0, 40, 0.85, 1.80},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_nonlinear_regime_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "initial_state", "final_state", "minimum_state", "maximum_pressure", "degraded_periods", "final_regime", "mean_net_flow", "hysteresis_gap"})

	for _, scenario := range scenarios {
		result := simulate(scenario, 140)
		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%.6f", result.InitialState),
			fmt.Sprintf("%.6f", result.FinalState),
			fmt.Sprintf("%.6f", result.MinimumState),
			fmt.Sprintf("%.6f", result.MaximumPressure),
			fmt.Sprintf("%d", result.DegradedPeriods),
			result.FinalRegime,
			fmt.Sprintf("%.6f", result.MeanNetFlow),
			fmt.Sprintf("%.6f", result.HysteresisGap),
		})
	}

	fmt.Println("Go nonlinear regime diagnostics runner complete.")
	fmt.Println(path)
}
