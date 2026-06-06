package main

import (
	"encoding/csv"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
)

type Policy struct {
	Name             string
	PolicyStrength   float64
	AdaptiveCapacity float64
}

func simulatePolicy(growth float64, shockIntensity float64, shockTiming int, policyStrength float64, adaptiveCapacity float64) (float64, float64, float64, float64) {
	state := 20.0
	maximumState := state
	minimumState := state
	cumulativeStress := 0.0

	for time := 1; time <= 60; time++ {
		shockWave := 0.0
		if time == shockTiming {
			shockWave = shockIntensity
		}

		adaptationEffect := adaptiveCapacity * maxFloat(state-35.0, 0.0)
		state = state + growth*state - policyStrength*state - adaptationEffect - shockWave

		if state < 0.0 {
			state = 0.0
		}
		if state > maximumState {
			maximumState = state
		}
		if state < minimumState {
			minimumState = state
		}
		cumulativeStress += maxFloat(state-40.0, 0.0)
	}

	score := 100.0 - 0.60*state - 0.25*maximumState - 0.10*cumulativeStress
	if score < 0.0 {
		score = 0.0
	}
	if score > 100.0 {
		score = 100.0
	}

	return state, maximumState, cumulativeStress, score
}

func maxFloat(a float64, b float64) float64 {
	if a > b {
		return a
	}
	return b
}

func main() {
	rng := rand.New(rand.NewSource(42))

	policies := []Policy{
		{"Policy_A_low_control", 0.025, 0.010},
		{"Policy_B_balanced", 0.045, 0.020},
		{"Policy_C_high_adaptation", 0.035, 0.045},
		{"Policy_D_precautionary", 0.055, 0.040},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_uncertainty_ensemble.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario_id", "policy", "growth", "shock_intensity", "shock_timing", "final_state", "maximum_state", "cumulative_stress", "resilience_score"})

	for scenarioID := 1; scenarioID <= 500; scenarioID++ {
		growth := 0.035 + rng.Float64()*(0.095-0.035)
		shockIntensity := rng.Float64() * 24.0
		shockTiming := 20 + rng.Intn(26)

		for _, policy := range policies {
			finalState, maximumState, cumulativeStress, score := simulatePolicy(growth, shockIntensity, shockTiming, policy.PolicyStrength, policy.AdaptiveCapacity)

			writer.Write([]string{
				fmt.Sprintf("%d", scenarioID),
				policy.Name,
				fmt.Sprintf("%.6f", growth),
				fmt.Sprintf("%.6f", shockIntensity),
				fmt.Sprintf("%d", shockTiming),
				fmt.Sprintf("%.6f", finalState),
				fmt.Sprintf("%.6f", maximumState),
				fmt.Sprintf("%.6f", cumulativeStress),
				fmt.Sprintf("%.6f", score),
			})
		}
	}

	fmt.Println("Go uncertainty ensemble runner complete.")
	fmt.Println(path)
}
