# Hybrid Model Architecture

This companion folder contains two simplified hybrid model structures.

## Structure A: Agent demand and queue pressure

- Agent module generates service demand.
- Operational queue module processes demand under limited capacity.
- Queue pressure feeds back into future agent demand propensity.

## Structure B: Aggregate feedback and heterogeneous adoption

- Aggregate demand evolves over time.
- Heterogeneous agents adopt when demand exceeds thresholds.
- Adoption feeds back into aggregate demand.

## Purpose

The workflows demonstrate hybrid coupling, not empirical prediction. The examples are intentionally compact so that module boundaries, interfaces, and validation checks remain visible.
