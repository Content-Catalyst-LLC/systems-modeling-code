#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int node_count;
    double link_probability;
    double threshold;
    int seed_count;
    int max_steps;
};

struct Summary {
    std::string scenario;
    int final_affected_count;
    double final_affected_share;
    int cascade_duration;
    int maximum_new_failures;
};

bool deterministic_edge(int source, int target, double probability) {
    double raw = std::sin(static_cast<double>((source + 1) * (target + 3)) * 12.9898) * 43758.5453;
    double value = std::abs(raw - std::floor(raw));
    return value < probability;
}

std::vector<std::vector<int>> build_network(int node_count, double probability) {
    std::vector<std::vector<int>> graph(node_count);

    for (int source = 0; source < node_count; ++source) {
        for (int target = source + 1; target < node_count; ++target) {
            if (deterministic_edge(source, target, probability)) {
                graph[source].push_back(target);
                graph[target].push_back(source);
            }
        }
    }

    return graph;
}

Summary simulate(const Scenario& scenario) {
    auto graph = build_network(scenario.node_count, scenario.link_probability);
    std::vector<int> degree(scenario.node_count, 0);

    for (int node = 0; node < scenario.node_count; ++node) {
        degree[node] = static_cast<int>(graph[node].size());
    }

    std::vector<int> affected(scenario.node_count, 0);

    for (int seed = 0; seed < scenario.seed_count; ++seed) {
        int best_node = -1;
        int best_degree = -1;

        for (int node = 0; node < scenario.node_count; ++node) {
            if (!affected[node] && degree[node] > best_degree) {
                best_node = node;
                best_degree = degree[node];
            }
        }

        if (best_node >= 0) {
            affected[best_node] = 1;
        }
    }

    int affected_count = std::count(affected.begin(), affected.end(), 1);
    int maximum_new_failures = affected_count;
    int cascade_duration = 0;

    for (int step = 1; step <= scenario.max_steps; ++step) {
        std::vector<int> newly_affected;

        for (int node = 0; node < scenario.node_count; ++node) {
            if (affected[node] || degree[node] == 0) {
                continue;
            }

            int affected_neighbors = 0;
            for (int neighbor : graph[node]) {
                if (affected[neighbor]) {
                    affected_neighbors++;
                }
            }

            double exposure_share = static_cast<double>(affected_neighbors) / static_cast<double>(degree[node]);

            if (exposure_share >= scenario.threshold) {
                newly_affected.push_back(node);
            }
        }

        if (newly_affected.empty()) {
            break;
        }

        for (int node : newly_affected) {
            affected[node] = 1;
        }

        affected_count += static_cast<int>(newly_affected.size());
        maximum_new_failures = std::max(maximum_new_failures, static_cast<int>(newly_affected.size()));
        cascade_duration = step;
    }

    return {
        scenario.name,
        affected_count,
        static_cast<double>(affected_count) / static_cast<double>(scenario.node_count),
        cascade_duration,
        maximum_new_failures
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_threshold", 90, 0.055, 0.25, 4, 40},
        {"lower_threshold", 90, 0.055, 0.18, 4, 40},
        {"higher_connectivity", 90, 0.075, 0.25, 4, 40},
        {"larger_initial_shock", 90, 0.055, 0.25, 8, 40}
    };

    std::cout << "scenario,final_affected_count,final_affected_share,cascade_duration,maximum_new_failures,diagnostic_label\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.final_affected_share >= 0.5 ? "systemic cascade" : "contained cascade";

        std::cout
            << result.scenario << ","
            << result.final_affected_count << ","
            << result.final_affected_share << ","
            << result.cascade_duration << ","
            << result.maximum_new_failures << ","
            << label << "\n";
    }

    return 0;
}
