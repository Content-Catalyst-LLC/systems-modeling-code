# feedback_loop_dynamics_diagnostics.R
# Base R workflow:
# simulating reinforcing, balancing, logistic, and delayed feedback loops.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) > 0) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE)
  article_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  article_root <- normalizePath(getwd(), mustWork = TRUE)
}

tables_dir <- file.path(article_root, "outputs", "tables")
figures_dir <- file.path(article_root, "outputs", "figures")

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

n_steps <- 80
time <- seq_len(n_steps)

reinforcing <- numeric(n_steps)
balancing <- numeric(n_steps)
logistic <- numeric(n_steps)
delayed_balancing <- numeric(n_steps)
stock_flow <- numeric(n_steps)

reinforcing[1] <- 2
balancing[1] <- 2
logistic[1] <- 2
delayed_balancing[1] <- 5
stock_flow[1] <- 40

target <- 20
correction_strength <- 0.15
reinforcing_rate <- 0.12
capacity <- 25
delay <- 5

for (t in 2:n_steps) {
  reinforcing[t] <- (1 + reinforcing_rate) * reinforcing[t - 1]

  balancing[t] <- balancing[t - 1] +
    correction_strength * (target - balancing[t - 1])

  logistic[t] <- logistic[t - 1] +
    reinforcing_rate * logistic[t - 1] * (1 - logistic[t - 1] / capacity)

  delayed_index <- max(1, t - delay)

  delayed_balancing[t] <- delayed_balancing[t - 1] +
    0.28 * (target - delayed_balancing[delayed_index])

  inflow <- 4.0 + 0.08 * max(0, 60 - stock_flow[t - 1])
  outflow <- 0.07 * stock_flow[t - 1]
  stock_flow[t] <- max(0, stock_flow[t - 1] + inflow - outflow)
}

trajectory_df <- data.frame(
  time = time,
  reinforcing = reinforcing,
  balancing = balancing,
  logistic = logistic,
  delayed_balancing = delayed_balancing,
  stock_flow = stock_flow,
  target = target
)

target_crossings <- function(values, target_value) {
  centered <- values - target_value
  crossings <- 0

  for (i in 2:length(centered)) {
    if (centered[i - 1] == 0 || centered[i] == 0) {
      next
    }

    if ((centered[i - 1] < 0 && centered[i] > 0) ||
        (centered[i - 1] > 0 && centered[i] < 0)) {
      crossings <- crossings + 1
    }
  }

  crossings
}

diagnostic_df <- data.frame(
  process = c(
    "reinforcing",
    "balancing",
    "logistic",
    "delayed_balancing",
    "stock_flow"
  ),
  initial_value = c(
    reinforcing[1],
    balancing[1],
    logistic[1],
    delayed_balancing[1],
    stock_flow[1]
  ),
  final_value = c(
    reinforcing[n_steps],
    balancing[n_steps],
    logistic[n_steps],
    delayed_balancing[n_steps],
    stock_flow[n_steps]
  ),
  maximum_value = c(
    max(reinforcing),
    max(balancing),
    max(logistic),
    max(delayed_balancing),
    max(stock_flow)
  ),
  minimum_value = c(
    min(reinforcing),
    min(balancing),
    min(logistic),
    min(delayed_balancing),
    min(stock_flow)
  ),
  target_crossings = c(
    NA,
    target_crossings(balancing, target),
    NA,
    target_crossings(delayed_balancing, target),
    target_crossings(stock_flow, 60)
  ),
  interpretation = c(
    "self-amplifying compounding process",
    "target-seeking stabilizing process",
    "reinforcing growth constrained by balancing capacity limit",
    "balancing feedback with delay that can generate oscillation",
    "stock-flow accumulation governed by corrective inflow and fractional outflow"
  )
)

write.csv(
  trajectory_df,
  file.path(tables_dir, "r_feedback_loop_trajectories.csv"),
  row.names = FALSE
)

write.csv(
  diagnostic_df,
  file.path(tables_dir, "r_feedback_loop_diagnostics.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_feedback_loop_trajectories.png"), width = 1200, height = 700)
plot(
  trajectory_df$time,
  trajectory_df$reinforcing,
  type = "l",
  lwd = 2,
  xlab = "Time",
  ylab = "System State",
  main = "Reinforcing, Balancing, Logistic, Delayed, and Stock-Flow Feedback"
)
lines(trajectory_df$time, trajectory_df$balancing, lwd = 2, lty = 2)
lines(trajectory_df$time, trajectory_df$logistic, lwd = 2, lty = 3)
lines(trajectory_df$time, trajectory_df$delayed_balancing, lwd = 2, lty = 4)
lines(trajectory_df$time, trajectory_df$stock_flow, lwd = 2, lty = 5)
abline(h = target, lty = 6)
legend(
  "topleft",
  legend = c("Reinforcing", "Balancing", "Logistic", "Delayed balancing", "Stock-flow", "Target"),
  lwd = c(2, 2, 2, 2, 2, 1),
  lty = c(1, 2, 3, 4, 5, 6),
  bty = "n",
  cex = 0.75
)
grid()
dev.off()

print(diagnostic_df)
cat("R feedback loop dynamics diagnostics complete.\n")
