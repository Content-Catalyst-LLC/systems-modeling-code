package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"math/rand"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name        string
	ArrivalRate float64
	ServiceRate float64
	Entities    int
	Seed        int64
}

func exponential(rng *rand.Rand, rate float64) float64 {
	return -math.Log(1.0-rng.Float64()) / rate
}

func simulate(s Scenario) []string {
	rng := rand.New(rand.NewSource(s.Seed))

	arrivalTime := make([]float64, s.Entities)
	serviceTime := make([]float64, s.Entities)
	serviceStart := make([]float64, s.Entities)
	departureTime := make([]float64, s.Entities)
	waitingTime := make([]float64, s.Entities)

	for i := 0; i < s.Entities; i++ {
		if i == 0 {
			arrivalTime[i] = exponential(rng, s.ArrivalRate)
		} else {
			arrivalTime[i] = arrivalTime[i-1] + exponential(rng, s.ArrivalRate)
		}
		serviceTime[i] = exponential(rng, s.ServiceRate)
	}

	serviceStart[0] = arrivalTime[0]
	departureTime[0] = serviceStart[0] + serviceTime[0]

	for i := 1; i < s.Entities; i++ {
		if arrivalTime[i] > departureTime[i-1] {
			serviceStart[i] = arrivalTime[i]
		} else {
			serviceStart[i] = departureTime[i-1]
		}
		departureTime[i] = serviceStart[i] + serviceTime[i]
		waitingTime[i] = serviceStart[i] - arrivalTime[i]
	}

	totalWait := 0.0
	maxWait := 0.0
	serviceLevelCount := 0

	for i := 0; i < s.Entities; i++ {
		totalWait += waitingTime[i]
		if waitingTime[i] > maxWait {
			maxWait = waitingTime[i]
		}
		if waitingTime[i] <= 12.0 {
			serviceLevelCount++
		}
	}

	return []string{
		s.Name,
		fmt.Sprintf("%d", s.Entities),
		fmt.Sprintf("%.6f", totalWait/float64(s.Entities)),
		fmt.Sprintf("%.6f", maxWait),
		fmt.Sprintf("%.6f", s.ArrivalRate/s.ServiceRate),
		fmt.Sprintf("%.6f", float64(serviceLevelCount)/float64(s.Entities)),
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_single_server", 0.18, 0.22, 240, 42},
		{"higher_arrival_pressure", 0.21, 0.22, 240, 43},
		{"faster_service", 0.18, 0.30, 240, 44},
		{"stress_surge", 0.25, 0.22, 240, 45},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_des_queue_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "completed_entities", "average_waiting_time", "maximum_waiting_time", "implied_utilization", "service_level_share"})
	for _, scenario := range scenarios {
		writer.Write(simulate(scenario))
	}

	fmt.Println("Go DES scenario runner complete.")
	fmt.Println(path)
}
