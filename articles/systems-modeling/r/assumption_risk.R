# Systems Modeling:
# Assumption risk scoring in R.
# Educational example only.

library(tidyverse)

assumptions <- read_csv("../data/model_assumptions.csv", show_col_types = FALSE)

scored <- assumptions |>
  mutate(
    assumption_risk_score = (1 - confidence) * impact_if_wrong,
    priority = case_when(
      assumption_risk_score >= 0.30 ~ "High",
      assumption_risk_score >= 0.18 ~ "Medium",
      TRUE ~ "Lower"
    )
  ) |>
  arrange(desc(assumption_risk_score))

dir.create("../outputs", showWarnings = FALSE, recursive = TRUE)

write_csv(scored, "../outputs/r_systems_modeling_assumption_risk.csv")

print(scored)
