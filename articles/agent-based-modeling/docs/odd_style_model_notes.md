# ODD-Style Model Notes

The ODD protocol stands for Overview, Design concepts, and Details. This file is not a full ODD protocol document, but it follows the same spirit.

## Purpose

Demonstrate how local agent rules generate macro-level patterns.

## Entities

- Spatial relocation model: grid cells and two agent types.
- Threshold adoption model: agents on a ring network.

## State variables

- Spatial model: agent type, location, satisfaction status.
- Threshold model: adopted status, individual threshold, neighborhood radius.

## Process overview

- Agents observe local neighborhood conditions.
- Agents update state or location based on rules.
- Macro-level metrics are recorded over time.

## Design concepts

- Emergence
- Heterogeneity
- Local interaction
- Stochastic initialization
- Scenario comparison
- Sensitivity to assumptions

## Initialization

Synthetic agent populations are created from documented scenario parameters.

## Outputs

- Satisfaction share
- Clustering index
- Final grid state
- Adoption rate
- New adopters
- Scenario summaries
