# phase_transition_bifurcation_diagnostics.R
# Base R workflow:
# simulating a threshold-driven phase transition.

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

control_parameter <- seq(-1.5, 1.5, length.out = 301)

phase_rows <- data.frame(
  control_parameter = control_parameter,
  stable_state_positive = ifelse(control_parameter > 0, sqrt(control_parameter), 0),
  stable_state_negative = ifelse(control_parameter > 0, -sqrt(control_parameter), 0),
  neutral_state = 0,
  phase_label = ifelse(control_parameter <= 0, "single neutral phase", "two ordered phases"),
  order_parameter_magnitude = ifelse(control_parameter > 0, sqrt(control_parameter), 0)
)

summary_rows <- data.frame(
  metric = c(
    "minimum_control_parameter",
    "maximum_control_parameter",
    "critical_threshold",
    "maximum_order_parameter_magnitude",
    "ordered_phase_count"
  ),
  value = c(
    min(phase_rows$control_parameter),
    max(phase_rows$control_parameter),
    0,
    max(phase_rows$order_parameter_magnitude),
    sum(phase_rows$control_parameter > 0)
  )
)

write.csv(
  phase_rows,
  file.path(tables_dir, "r_phase_transition_bifurcation_branches.csv"),
  row.names = FALSE
)

write.csv(
  summary_rows,
  file.path(tables_dir, "r_phase_transition_bifurcation_summary.csv"),
  row.names = FALSE
)

png(file.path(figures_dir, "r_phase_transition_bifurcation.png"), width = 1200, height = 700)
plot(
  phase_rows$control_parameter,
  phase_rows$stable_state_positive,
  type = "l",
  lwd = 2,
  xlab = "Control Parameter",
  ylab = "System State / Order Parameter",
  main = "Threshold-Driven Phase Transition"
)

lines(
  phase_rows$control_parameter,
  phase_rows$stable_state_negative,
  lwd = 2
)

lines(
  phase_rows$control_parameter,
  phase_rows$neutral_state,
  lwd = 2,
  lty = 2
)

abline(v = 0, lty = 3)
grid()

legend(
  "topleft",
  legend = c("Positive ordered branch", "Negative ordered branch", "Neutral branch", "Critical threshold"),
  lwd = c(2, 2, 2, 1),
  lty = c(1, 1, 2, 3),
  bty = "n",
  cex = 0.8
)

dev.off()

print(summary_rows)
cat("R phase-transition bifurcation diagnostics complete.\n")
