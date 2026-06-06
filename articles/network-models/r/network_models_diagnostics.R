# network_models_diagnostics.R
# Base R workflow:
# network metrics, components, robustness, and fragmentation diagnostics.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) > 0) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE)
  article_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  article_root <- normalizePath(getwd(), mustWork = TRUE)
}

data_dir <- file.path(article_root, "data")
tables_dir <- file.path(article_root, "outputs", "tables")
figures_dir <- file.path(article_root, "outputs", "figures")

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

nodes <- read.csv(file.path(data_dir, "node_attributes.csv"), stringsAsFactors = FALSE)
edges <- read.csv(file.path(data_dir, "synthetic_network_edges.csv"), stringsAsFactors = FALSE)

n <- nrow(nodes)
A <- matrix(0, nrow = n, ncol = n)

for (row_index in seq_len(nrow(edges))) {
  i <- edges$source[row_index] + 1
  j <- edges$target[row_index] + 1
  A[i, j] <- 1
  A[j, i] <- 1
}

degree <- rowSums(A)
density <- sum(A) / (n * (n - 1))

bfs_distances <- function(A, source) {
  n <- nrow(A)
  distances <- rep(Inf, n)
  distances[source] <- 0
  queue <- c(source)

  while (length(queue) > 0) {
    current <- queue[1]
    queue <- queue[-1]

    neighbors <- which(A[current, ] == 1)

    for (neighbor in neighbors) {
      if (is.infinite(distances[neighbor])) {
        distances[neighbor] <- distances[current] + 1
        queue <- c(queue, neighbor)
      }
    }
  }

  distances
}

component_labels <- function(A) {
  n <- nrow(A)
  labels <- rep(0, n)
  component_id <- 0

  for (node in seq_len(n)) {
    if (labels[node] == 0) {
      component_id <- component_id + 1
      queue <- c(node)
      labels[node] <- component_id

      while (length(queue) > 0) {
        current <- queue[1]
        queue <- queue[-1]

        neighbors <- which(A[current, ] == 1)

        for (neighbor in neighbors) {
          if (labels[neighbor] == 0) {
            labels[neighbor] <- component_id
            queue <- c(queue, neighbor)
          }
        }
      }
    }
  }

  labels
}

all_distances <- c()

for (source in seq_len(n)) {
  distances <- bfs_distances(A, source)
  all_distances <- c(all_distances, distances[is.finite(distances) & distances > 0])
}

labels <- component_labels(A)
component_sizes <- table(labels)

node_metrics <- data.frame(
  node = nodes$node_id,
  node_label = nodes$node_label,
  layer = nodes$layer,
  region = nodes$region,
  criticality = nodes$criticality,
  degree = degree,
  degree_centrality = degree / (n - 1),
  component = labels
)

summary_metrics <- data.frame(
  scenario = "baseline_network",
  nodes = n,
  edges = sum(A) / 2,
  density = density,
  average_degree = mean(degree),
  maximum_degree = max(degree),
  component_count = length(component_sizes),
  largest_component_size = max(component_sizes),
  largest_component_share = max(component_sizes) / n,
  average_path_length_reachable = mean(all_distances)
)

remove_nodes <- function(A, nodes_to_remove) {
  if (length(nodes_to_remove) == 0) {
    return(A)
  }

  keep <- setdiff(seq_len(nrow(A)), nodes_to_remove)
  A[keep, keep, drop = FALSE]
}

robustness_rows <- data.frame()
degree_ranked <- order(degree, decreasing = TRUE)
set.seed(70707)

for (fraction in c(0, 0.05, 0.10, 0.15, 0.20, 0.25)) {
  k <- round(n * fraction)

  random_removed <- if (k > 0) sample(seq_len(n), k) else integer(0)
  targeted_removed <- if (k > 0) degree_ranked[seq_len(k)] else integer(0)

  for (strategy in c("random_removal", "targeted_high_degree_removal")) {
    removed <- if (strategy == "random_removal") random_removed else targeted_removed
    revised <- remove_nodes(A, removed)

    if (nrow(revised) > 0) {
      revised_labels <- component_labels(revised)
      revised_sizes <- table(revised_labels)
      largest <- max(revised_sizes)
      component_count <- length(revised_sizes)
    } else {
      largest <- 0
      component_count <- 0
    }

    robustness_rows <- rbind(robustness_rows, data.frame(
      strategy = strategy,
      removal_fraction = fraction,
      nodes_removed = k,
      remaining_nodes = nrow(revised),
      component_count = component_count,
      largest_component_size = largest,
      largest_component_share = largest / max(1, nrow(revised))
    ))
  }
}

write.csv(node_metrics, file.path(tables_dir, "r_network_node_metrics.csv"), row.names = FALSE)
write.csv(summary_metrics, file.path(tables_dir, "r_network_summary.csv"), row.names = FALSE)
write.csv(robustness_rows, file.path(tables_dir, "r_network_robustness.csv"), row.names = FALSE)

png(file.path(figures_dir, "r_network_degree_distribution.png"), width = 1000, height = 700)
hist(
  degree,
  breaks = seq(-0.5, max(degree) + 0.5, by = 1),
  main = "Synthetic Network Degree Distribution",
  xlab = "Degree",
  ylab = "Node Count"
)
grid()
dev.off()

png(file.path(figures_dir, "r_network_robustness.png"), width = 1000, height = 700)
plot(
  robustness_rows$removal_fraction[robustness_rows$strategy == "random_removal"],
  robustness_rows$largest_component_share[robustness_rows$strategy == "random_removal"],
  type = "b",
  ylim = c(0, 1),
  xlab = "Removal Fraction",
  ylab = "Largest Component Share",
  main = "Network Robustness Under Node Removal"
)
lines(
  robustness_rows$removal_fraction[robustness_rows$strategy == "targeted_high_degree_removal"],
  robustness_rows$largest_component_share[robustness_rows$strategy == "targeted_high_degree_removal"],
  type = "b",
  lty = 2
)
legend(
  "bottomleft",
  legend = c("Random removal", "Targeted high-degree removal"),
  lty = c(1, 2),
  pch = c(1, 1),
  bty = "n"
)
grid()
dev.off()

print(summary_metrics)
cat("R network modeling diagnostics complete.\n")
