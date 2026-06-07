# Integrated Assessment Models

Companion code for **Integrated Assessment Models**.

This folder contains synthetic, reproducible examples for IAM-style systems modeling: emissions pathways, mitigation rates, emissions intensity decline, atmospheric pressure proxies, temperature response proxies, damages, mitigation cost, consumption proxies, welfare proxies, sensitivity diagnostics, scenario comparison, validation checks, and responsible-use documentation.

## Run

```bash
./run_all.sh
```

Core workflows:

```bash
python3 python/integrated_assessment_models_workflow.py
Rscript r/iam_stylized_scenario_comparison.R
sqlite3 outputs/tables/integrated_assessment_models.sqlite < sql/integrated_assessment_models_schema.sql
```

## Interpretation warning

These are synthetic teaching models. They are not calibrated IAMs and do not reproduce DICE, GCAM, IMAGE, MESSAGEix, REMIND, AIM, or any official model. Use them to understand structure, assumptions, scenario comparison, sensitivity, validation, and responsible interpretation.
