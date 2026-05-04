# Systems Modeling:
# Interacting stocks with reinforcing and balancing feedback in R.
# Educational example only.

library(tidyverse)

simulate_interacting_stocks <- function(initial_stock_a, initial_stock_b, growth_a_rate, growth_b_rate,
                                        b_to_a_pressure, a_to_b_support, b_balancing_rate, target_b, steps) {
  stock_a <- numeric(steps)
  stock_b <- numeric(steps)

  stock_a[1] <- initial_stock_a
  stock_b[1] <- initial_stock_b

  for (t in 2:steps) {
    reinforcing_a <- growth_a_rate * stock_a[t - 1]
    pressure_from_b <- -b_to_a_pressure * stock_b[t - 1]

    reinforcing_b <- growth_b_rate * stock_b[t - 1]
    support_from_a <- a_to_b_support * stock_a[t - 1]
    balancing_b <- b_balancing_rate * max(stock_b[t - 1] - target_b, 0)

    stock_a[t] <- stock_a[t - 1] + reinforcing_a + pressure_from_b
    stock_b[t] <- stock_b[t - 1] + reinforcing_b + support_from_a - balancing_b
  }

  tibble(
    time = 1:steps,
    stock_a = stock_a,
    stock_b = stock_b
  )
}

parameters <- read_csv("../data/stock_flow_parameters.csv", show_col_types = FALSE)

results <- parameters |>
  mutate(
    simulation = pmap(
      list(initial_stock_a, initial_stock_b, growth_a_rate, growth_b_rate,
           b_to_a_pressure, a_to_b_support, b_balancing_rate, target_b, steps),
      simulate_interacting_stocks
    )
  ) |>
  select(scenario_id, simulation) |>
  unnest(simulation)

summary_results <- results |>
  group_by(scenario_id) |>
  summarise(
    final_stock_a = last(stock_a),
    final_stock_b = last(stock_b),
    max_stock_a = max(stock_a),
    max_stock_b = max(stock_b),
    time_of_max_stock_b = time[which.max(stock_b)],
    .groups = "drop"
  )

dir.create("../outputs", showWarnings = FALSE, recursive = TRUE)

write_csv(results, "../outputs/r_stock_flow_feedback_results.csv")
write_csv(summary_results, "../outputs/r_stock_flow_feedback_summary.csv")

print(summary_results)
