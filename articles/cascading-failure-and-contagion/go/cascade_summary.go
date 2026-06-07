package main

import "fmt"

type Node struct {
	Sector    string
	Capacity  float64
	Load      float64
	Threshold float64
}

func main() {
	nodes := []Node{
		{"energy", 100, 62, 0.75},
		{"water", 85, 70, 0.70},
		{"telecom", 90, 58, 0.72},
		{"health", 95, 82, 0.78},
	}

	fmt.Println("Cascade capacity diagnostics")

	for _, node := range nodes {
		loadRatio := node.Load / node.Capacity
		status := "within threshold"
		if loadRatio >= node.Threshold {
			status = "failure risk"
		}
		fmt.Printf("%s load_ratio=%.3f threshold=%.3f status=%s\n", node.Sector, loadRatio, node.Threshold, status)
	}
}
