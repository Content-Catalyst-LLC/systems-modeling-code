#include <math.h>
#include <stdio.h>

#define NODE_COUNT 90
#define MAX_STEPS 40

int deterministic_edge(int source, int target, double probability) {
    double raw = sin((double)((source + 1) * (target + 3)) * 12.9898) * 43758.5453;
    double value = fabs(raw - floor(raw));
    return value < probability;
}

void simulate(const char *scenario, double link_probability, double threshold, int seed_count) {
    int adjacency[NODE_COUNT][NODE_COUNT] = {0};
    int degree[NODE_COUNT] = {0};
    int affected[NODE_COUNT] = {0};

    for (int source = 0; source < NODE_COUNT; ++source) {
        for (int target = source + 1; target < NODE_COUNT; ++target) {
            if (deterministic_edge(source, target, link_probability)) {
                adjacency[source][target] = 1;
                adjacency[target][source] = 1;
                degree[source]++;
                degree[target]++;
            }
        }
    }

    for (int seed = 0; seed < seed_count; ++seed) {
        int best_node = -1;
        int best_degree = -1;

        for (int node = 0; node < NODE_COUNT; ++node) {
            if (!affected[node] && degree[node] > best_degree) {
                best_node = node;
                best_degree = degree[node];
            }
        }

        if (best_node >= 0) {
            affected[best_node] = 1;
        }
    }

    int affected_count = 0;
    for (int node = 0; node < NODE_COUNT; ++node) {
        affected_count += affected[node];
    }

    printf("%s,%d,%d,%.6f,%d\n", scenario, 0, affected_count, (double)affected_count / NODE_COUNT, seed_count);

    for (int step = 1; step <= MAX_STEPS; ++step) {
        int newly_affected[NODE_COUNT] = {0};
        int new_failures = 0;

        for (int node = 0; node < NODE_COUNT; ++node) {
            if (affected[node] || degree[node] == 0) {
                continue;
            }

            int affected_neighbors = 0;
            for (int neighbor = 0; neighbor < NODE_COUNT; ++neighbor) {
                if (adjacency[node][neighbor] && affected[neighbor]) {
                    affected_neighbors++;
                }
            }

            double exposure_share = (double)affected_neighbors / (double)degree[node];

            if (exposure_share >= threshold) {
                newly_affected[node] = 1;
                new_failures++;
            }
        }

        if (new_failures == 0) {
            break;
        }

        for (int node = 0; node < NODE_COUNT; ++node) {
            if (newly_affected[node]) {
                affected[node] = 1;
            }
        }

        affected_count += new_failures;

        printf("%s,%d,%d,%.6f,%d\n", scenario, step, affected_count, (double)affected_count / NODE_COUNT, new_failures);
    }
}

int main(void) {
    printf("scenario,step,affected_count,affected_share,new_failures\n");

    simulate("baseline_threshold", 0.055, 0.25, 4);
    simulate("lower_threshold", 0.055, 0.18, 4);
    simulate("higher_connectivity", 0.075, 0.25, 4);
    simulate("larger_initial_shock", 0.055, 0.25, 8);

    return 0;
}
