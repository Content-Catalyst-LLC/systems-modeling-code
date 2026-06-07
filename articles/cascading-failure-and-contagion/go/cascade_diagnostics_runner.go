package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

type Scenario struct {
	Name            string
	NodeCount       int
	LinkProbability float64
	Threshold       float64
	SeedCount       int
	MaxSteps        int
}

type Summary struct {
	Scenario            string
	FinalAffectedCount  int
	FinalAffectedShare  float64
	CascadeDuration     int
	MaximumNewFailures  int
	MeanDegree          float64
	MaximumDegree       int
}

func deterministicEdge(source int, target int, probability float64) bool {
	value := math.Mod(math.Sin(float64((source+1)*(target+3))*12.9898)*43758.5453, 1.0)
	if value < 0 {
		value = -value
	}
	return value < probability
}

func buildNetwork(nodeCount int, probability float64) [][]int {
	graph := make([][]int, nodeCount)

	for source := 0; source < nodeCount; source++ {
		for target := source + 1; target < nodeCount; target++ {
			if deterministicEdge(source, target, probability) {
				graph[source] = append(graph[source], target)
				graph[target] = append(graph[target], source)
			}
		}
	}

	return graph
}

func simulate(s Scenario) Summary {
	graph := buildNetwork(s.NodeCount, s.LinkProbability)
	degrees := make([]int, s.NodeCount)
	maxDegree := 0
	totalDegree := 0

	for node, neighbors := range graph {
		degrees[node] = len(neighbors)
		totalDegree += degrees[node]
		if degrees[node] > maxDegree {
			maxDegree = degrees[node]
		}
	}

	affected := make([]bool, s.NodeCount)

	for seed := 0; seed < s.SeedCount && seed < s.NodeCount; seed++ {
		bestNode := -1
		bestDegree := -1

		for node := 0; node < s.NodeCount; node++ {
			if !affected[node] && degrees[node] > bestDegree {
				bestNode = node
				bestDegree = degrees[node]
			}
		}

		if bestNode >= 0 {
			affected[bestNode] = true
		}
	}

	affectedCount := s.SeedCount
	maxNewFailures := s.SeedCount
	duration := 0

	for step := 1; step <= s.MaxSteps; step++ {
		newlyAffected := []int{}

		for node := 0; node < s.NodeCount; node++ {
			if affected[node] || degrees[node] == 0 {
				continue
			}

			affectedNeighbors := 0
			for _, neighbor := range graph[node] {
				if affected[neighbor] {
					affectedNeighbors++
				}
			}

			exposure := float64(affectedNeighbors) / float64(degrees[node])
			if exposure >= s.Threshold {
				newlyAffected = append(newlyAffected, node)
			}
		}

		if len(newlyAffected) == 0 {
			break
		}

		for _, node := range newlyAffected {
			affected[node] = true
		}

		affectedCount += len(newlyAffected)
		if len(newlyAffected) > maxNewFailures {
			maxNewFailures = len(newlyAffected)
		}
		duration = step
	}

	return Summary{
		Scenario:           s.Name,
		FinalAffectedCount: affectedCount,
		FinalAffectedShare: float64(affectedCount) / float64(s.NodeCount),
		CascadeDuration:    duration,
		MaximumNewFailures: maxNewFailures,
		MeanDegree:         float64(totalDegree) / float64(s.NodeCount),
		MaximumDegree:      maxDegree,
	}
}

func main() {
	scenarios := []Scenario{
		{"baseline_threshold", 90, 0.055, 0.25, 4, 40},
		{"lower_threshold", 90, 0.055, 0.18, 4, 40},
		{"higher_connectivity", 90, 0.075, 0.25, 4, 40},
		{"larger_initial_shock", 90, 0.055, 0.25, 8, 40},
	}

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_threshold_cascade_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"scenario", "final_affected_count", "final_affected_share", "cascade_duration", "maximum_new_failures", "mean_degree", "maximum_degree", "diagnostic_label"})

	for _, scenario := range scenarios {
		result := simulate(scenario)
		label := "contained cascade"
		if result.FinalAffectedShare >= 0.5 {
			label = "systemic cascade"
		}

		writer.Write([]string{
			result.Scenario,
			fmt.Sprintf("%d", result.FinalAffectedCount),
			fmt.Sprintf("%.6f", result.FinalAffectedShare),
			fmt.Sprintf("%d", result.CascadeDuration),
			fmt.Sprintf("%d", result.MaximumNewFailures),
			fmt.Sprintf("%.6f", result.MeanDegree),
			fmt.Sprintf("%d", result.MaximumDegree),
			label,
		})
	}

	fmt.Println("Go cascade diagnostics runner complete.")
	fmt.Println(path)
}
