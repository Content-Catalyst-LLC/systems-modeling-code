package main

import (
	"encoding/csv"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name            string
	NAgents         int
	NSteps          int
	InitialAdopters int
	ThresholdLow    float64
	ThresholdHigh   float64
	NeighborRadius  int
	Seed            int64
}

func meanBool(values []bool) float64 {
	count := 0
	for _, value := range values {
		if value {
			count++
		}
	}
	return float64(count) / float64(len(values))
}

func simulate(s Scenario) []string {
	rng := rand.New(rand.NewSource(s.Seed))

	thresholds := make([]float64, s.NAgents)
	for i := 0; i < s.NAgents; i++ {
		thresholds[i] = s.ThresholdLow + rng.Float64()*(s.ThresholdHigh-s.ThresholdLow)
	}

	adopted := make([]bool, s.NAgents)
	perm := rng.Perm(s.NAgents)
	for i := 0; i < s.InitialAdopters && i < s.NAgents; i++ {
		adopted[perm[i]] = true
	}

	finalRate := meanBool(adopted)
	peakNew := 0
	timeToHalf := 0

	for time := 1; time <= s.NSteps; time++ {
		previous := make([]bool, s.NAgents)
		copy(previous, adopted)

		for i := 0; i < s.NAgents; i++ {
			if previous[i] {
				continue
			}

			localCount := 0
			adoptedCount := 0

			for offset := -s.NeighborRadius; offset <= s.NeighborRadius; offset++ {
				if offset == 0 {
					continue
				}

				neighbor := (i + offset + s.NAgents) % s.NAgents
				localCount++
				if previous[neighbor] {
					adoptedCount++
				}
			}

			localShare := float64(adoptedCount) / float64(localCount)
			if localShare >= thresholds[i] {
				adopted[i] = true
			}
		}

		newAdopters := 0
		for i := 0; i < s.NAgents; i++ {
			if adopted[i] && !previous[i] {
				newAdopters++
			}
		}

		if newAdopters > peakNew {
			peakNew = newAdopters
		}

		finalRate = meanBool(adopted)
		if timeToHalf == 0 && finalRate >= 0.5 {
			timeToHalf = time
		}
	}

	return []string{
		s.Name,
		fmt.Sprintf("%.6f", float64(s.InitialAdopters)/float64(s.NAgents)),
		fmt.Sprintf("%.6f", finalRate),
		fmt.Sprintf("%d", peakNew),
		fmt.Sprintf("%d", timeToHalf),
		fmt.Sprintf("%.6f", (s.ThresholdLow+s.ThresholdHigh)/2.0),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_threshold_adoption", 180, 50, 12, 0.10, 0.70, 2, 101},
		{"low_threshold_population", 180, 50, 12, 0.05, 0.45, 2, 102},
		{"high_threshold_population", 180, 50, 12, 0.35, 0.85, 2, 103},
		{"wider_neighborhood", 180, 50, 12, 0.10, 0.70, 4, 104},
		{"more_initial_adopters", 180, 50, 28, 0.10, 0.70, 2, 105},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_abm_threshold_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "initial_adoption_rate", "final_adoption_rate", "peak_new_adopters", "time_to_half_adoption", "mean_threshold"})
	for _, scenario := range scenarios {
		writer.Write(simulate(scenario))
	}

	fmt.Println("Go ABM scenario runner complete.")
	fmt.Println(path)
}
