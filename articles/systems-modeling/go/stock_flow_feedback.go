package main

import (
	"fmt"
	"math"
)

func main() {
	steps := 140
	stockA := make([]float64, steps)
	stockB := make([]float64, steps)

	stockA[0] = 20.0
	stockB[0] = 10.0

	growthARate := 0.06
	growthBRate := 0.04
	bToAPressure := 0.02
	aToBSupport := 0.04
	bBalancingRate := 0.03
	targetB := 45.0

	for t := 1; t < steps; t++ {
		reinforcingA := growthARate * stockA[t-1]
		pressureFromB := -bToAPressure * stockB[t-1]

		reinforcingB := growthBRate * stockB[t-1]
		supportFromA := aToBSupport * stockA[t-1]
		balancingB := bBalancingRate * math.Max(stockB[t-1]-targetB, 0)

		stockA[t] = stockA[t-1] + reinforcingA + pressureFromB
		stockB[t] = stockB[t-1] + reinforcingB + supportFromA - balancingB
	}

	fmt.Printf("Final stock A: %.6f\n", stockA[steps-1])
	fmt.Printf("Final stock B: %.6f\n", stockB[steps-1])
}
