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
	PolicyDrag       float64
	ResilienceBuffer float64
}

func resilienceScore(finalState float64, maximumState float64, cumulativeCost float64) float64 {
	score := 100.0 - 0.8*finalState - 0.3*maximumState - 0.2*cumulativeCost
	if score < 0.0 {
		return 0.0
	}
	if score > 100.0 {
		return 100.0
	}
	return score
}

func simulatePolicy(growth float64, policyDrag float64, externalShock float64, shockTime int, resilienceBuffer float64) (float64, float64, float64, float64) {
	state := 20.0
	maximumState := state
	cumulativeCost := 0.0

	for time := 1; time <= 60; time++ {
		state = state + growth*state - policyDrag*state

		if time == shockTime {
			state = state - externalShock/resilienceBuffer
			if state < 0.0 {
				state = 0.0
			}
		}

		policyCost := 4.0*policyDrag + 0.08*resilienceBuffer
		stressCost := 0.03
		if state > 35.0 {
			stressCost = 0.03 * (state - 35.0) * (state - 35.0)
		} else {
			stressCost = 0.0
		}
		cumulativeCost += policyCost + stressCost

		if state > maximumState {
			maximumState = state
		}
	}

	return state, maximumState, cumulativeCost, resilienceScore(state, maximumState, cumulativeCost)
}

func main() {
	rng := rand.New(rand.NewSource(4242))

	policies := []Policy{
		{"Policy_A_low_intervention", 0.010, 4.0},
		{"Policy_B_moderate_intervention", 0.025, 7.0},
		{"Policy_C_high_resilience", 0.020, 12.0},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_scenario_ensemble_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario_id", "policy", "growth", "external_shock", "shock_time", "final_state", "maximum_state", "cumulative_cost", "resilience_score"})

	for scenarioID := 1; scenarioID <= 300; scenarioID++ {
		growth := 0.030 + rng.Float64()*0.045
		externalShock := rng.Float64() * 18.0
		shockTime := 20 + rng.Intn(26)

		for _, policy := range policies {
			finalState, maximumState, cumulativeCost, score := simulatePolicy(growth, policy.PolicyDrag, externalShock, shockTime, policy.ResilienceBuffer)
			writer.Write([]string{
				fmt.Sprintf("%d", scenarioID),
				policy.Name,
				fmt.Sprintf("%.6f", growth),
				fmt.Sprintf("%.6f", externalShock),
				fmt.Sprintf("%d", shockTime),
				fmt.Sprintf("%.6f", finalState),
				fmt.Sprintf("%.6f", maximumState),
				fmt.Sprintf("%.6f", cumulativeCost),
				fmt.Sprintf("%.6f", score),
			})
		}
	}

	fmt.Println("Go scenario ensemble runner complete.")
	fmt.Println(path)
}
