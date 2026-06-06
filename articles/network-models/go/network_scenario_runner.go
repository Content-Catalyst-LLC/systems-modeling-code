package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"sort"
)

type Graph map[int]map[int]bool

func addEdge(g Graph, a int, b int) {
	if g[a] == nil {
		g[a] = make(map[int]bool)
	}
	if g[b] == nil {
		g[b] = make(map[int]bool)
	}
	g[a][b] = true
	g[b][a] = true
}

func buildGraph() Graph {
	g := make(Graph)
	for i := 0; i < 48; i++ {
		g[i] = make(map[int]bool)
	}

	edges := [][2]int{
		{0, 1}, {0, 2}, {1, 3}, {2, 3}, {2, 4}, {3, 5}, {4, 6}, {5, 7},
		{6, 8}, {7, 9}, {8, 10}, {9, 11}, {10, 12}, {11, 13}, {12, 14}, {13, 15},
		{16, 17}, {16, 18}, {17, 19}, {18, 19}, {18, 20}, {19, 21}, {20, 22}, {21, 23},
		{22, 24}, {23, 25}, {24, 26}, {25, 27}, {26, 28}, {27, 29}, {28, 30}, {29, 31},
		{32, 33}, {32, 34}, {33, 35}, {34, 35}, {34, 36}, {35, 37}, {36, 38}, {37, 39},
		{38, 40}, {39, 41}, {40, 42}, {41, 43}, {42, 44}, {43, 45}, {44, 46}, {45, 47},
		{3, 19}, {7, 25}, {21, 35}, {29, 42}, {12, 37}, {2, 18}, {18, 34}, {2, 34},
	}

	for _, edge := range edges {
		addEdge(g, edge[0], edge[1])
	}

	return g
}

func components(g Graph) []int {
	seen := make(map[int]bool)
	sizes := []int{}

	for node := range g {
		if seen[node] {
			continue
		}

		queue := []int{node}
		seen[node] = true
		size := 0

		for len(queue) > 0 {
			current := queue[0]
			queue = queue[1:]
			size++

			for neighbor := range g[current] {
				if !seen[neighbor] {
					seen[neighbor] = true
					queue = append(queue, neighbor)
				}
			}
		}

		sizes = append(sizes, size)
	}

	return sizes
}

func removeNodes(g Graph, removed map[int]bool) Graph {
	revised := make(Graph)

	for node, neighbors := range g {
		if removed[node] {
			continue
		}
		revised[node] = make(map[int]bool)
		for neighbor := range neighbors {
			if !removed[neighbor] {
				revised[node][neighbor] = true
			}
		}
	}

	return revised
}

func main() {
	g := buildGraph()

	degrees := []int{}
	nodes := []int{}
	for node, neighbors := range g {
		nodes = append(nodes, node)
		degrees = append(degrees, len(neighbors))
	}

	sort.Slice(nodes, func(i int, j int) bool {
		return len(g[nodes[i]]) > len(g[nodes[j]])
	})

	outputDir := filepath.Join("outputs", "tables")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		panic(err)
	}

	path := filepath.Join(outputDir, "go_network_robustness_summary.csv")
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"strategy", "nodes_removed", "remaining_nodes", "component_count", "largest_component_size", "largest_component_share"})

	for _, k := range []int{0, 2, 5, 7, 10, 12} {
		removed := make(map[int]bool)
		for i := 0; i < k && i < len(nodes); i++ {
			removed[nodes[i]] = true
		}

		revised := removeNodes(g, removed)
		sizes := components(revised)
		largest := 0
		for _, size := range sizes {
			if size > largest {
				largest = size
			}
		}

		share := 0.0
		if len(revised) > 0 {
			share = float64(largest) / float64(len(revised))
		}

		writer.Write([]string{
			"targeted_high_degree_removal",
			fmt.Sprintf("%d", k),
			fmt.Sprintf("%d", len(revised)),
			fmt.Sprintf("%d", len(sizes)),
			fmt.Sprintf("%d", largest),
			fmt.Sprintf("%.6f", share),
		})
	}

	fmt.Println("Go network scenario runner complete.")
	fmt.Println(path)
}
