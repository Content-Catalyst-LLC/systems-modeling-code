package main

import (
	"encoding/csv"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
)

type Strategy struct {
	Name             string
	Redundancy       float64
	AdaptiveResponse float64
}

func simulateStrategy(demandGrowth float64, capacityLoss float64, shockDuration int, recoveryDrag float64, redundancy float64, adaptiveResponse float64) (float64, float64, float64, float64) {
	baselineCapacity := 100.0
	demand := 55.0
	capacity := baselineCapacity * (1.0 + redundancy)
	minimumService := 1.0
	cumulativeUnmet := 0.0
	failureCount := 0
	steps := 72
	shockStart := 28

	for time := 1; time <= steps; time++ {
		demand *= 1.0 + demandGrowth
		shockActive := time >= shockStart && time < shockStart+shockDuration

		if time == shockStart {
			capacity -= capacityLoss
			if capacity < 0.0 {
				capacity = 0.0
			}
		}

		if shockActive {
			demand *= 1.010
		} else {
			recoveryRate := 0.12 + adaptiveResponse - recoveryDrag
			if recoveryRate < 0.0 {
				recoveryRate = 0.0
			}
			targetCapacity := baselineCapacity * (1.0 + redundancy)
			capacity += recoveryRate * (targetCapacity - capacity)
		}

		serviceRatio := 1.0
		if demand > 0.0 {
			serviceRatio = capacity / demand
			if serviceRatio > 1.0 {
				serviceRatio = 1.0
			}
		}

		unmet := demand - capacity
		if unmet < 0.0 {
			unmet = 0.0
		}

		if serviceRatio < minimumService {
			minimumService = serviceRatio
		}

		cumulativeUnmet += unmet

		if serviceRatio < 0.85 {
			failureCount++
		}
	}

	score := 100.0 - 70.0*(1.0-minimumService) - 0.05*cumulativeUnmet - 0.40*float64(failureCount)
	if score < 0.0 {
		score = 0.0
	}
	if score > 100.0 {
		score = 100.0
	}

	return minimumService, cumulativeUnmet, float64(failureCount) / float64(steps), score
}

func main() {
	rng := rand.New(rand.NewSource(42))

	strategies := []Strategy{
		{"Strategy_A_efficiency", 0.02, 0.02},
		{"Strategy_B_balanced_resilience", 0.12, 0.06},
		{"Strategy_C_high_redundancy", 0.25, 0.03},
		{"Strategy_D_adaptive_pathway", 0.08, 0.11},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_stress_robustness_ensemble.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario_id", "strategy", "demand_growth", "capacity_loss", "shock_duration", "recovery_drag", "minimum_service_ratio", "cumulative_unmet_demand", "failure_frequency", "resilience_score"})

	for scenarioID := 1; scenarioID <= 600; scenarioID++ {
		demandGrowth := 0.008 + rng.Float64()*(0.035-0.008)
		capacityLoss := rng.Float64() * 45.0
		shockDuration := 1 + rng.Intn(20)
		recoveryDrag := rng.Float64() * 0.09

		for _, strategy := range strategies {
			minimumService, cumulativeUnmet, failureFrequency, score := simulateStrategy(
				demandGrowth,
				capacityLoss,
				shockDuration,
				recoveryDrag,
				strategy.Redundancy,
				strategy.AdaptiveResponse,
			)

			writer.Write([]string{
				fmt.Sprintf("%d", scenarioID),
				strategy.Name,
				fmt.Sprintf("%.6f", demandGrowth),
				fmt.Sprintf("%.6f", capacityLoss),
				fmt.Sprintf("%d", shockDuration),
				fmt.Sprintf("%.6f", recoveryDrag),
				fmt.Sprintf("%.6f", minimumService),
				fmt.Sprintf("%.6f", cumulativeUnmet),
				fmt.Sprintf("%.6f", failureFrequency),
				fmt.Sprintf("%.6f", score),
			})
		}
	}

	fmt.Println("Go stress robustness runner complete.")
	fmt.Println(path)
}
