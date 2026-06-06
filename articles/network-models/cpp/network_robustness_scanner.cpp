#include <algorithm>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <queue>
#include <random>
#include <set>
#include <vector>

using Graph = std::vector<std::set<int>>;

Graph build_graph() {
    Graph graph(48);

    std::vector<std::pair<int, int>> edges = {
        {0,1},{0,2},{1,3},{2,3},{2,4},{3,5},{4,6},{5,7},
        {6,8},{7,9},{8,10},{9,11},{10,12},{11,13},{12,14},{13,15},
        {16,17},{16,18},{17,19},{18,19},{18,20},{19,21},{20,22},{21,23},
        {22,24},{23,25},{24,26},{25,27},{26,28},{27,29},{28,30},{29,31},
        {32,33},{32,34},{33,35},{34,35},{34,36},{35,37},{36,38},{37,39},
        {38,40},{39,41},{40,42},{41,43},{42,44},{43,45},{44,46},{45,47},
        {3,19},{7,25},{21,35},{29,42},{12,37},{2,18},{18,34},{2,34}
    };

    for (auto [a, b] : edges) {
        graph[a].insert(b);
        graph[b].insert(a);
    }

    return graph;
}

std::vector<int> component_sizes(const Graph& graph, const std::set<int>& removed) {
    std::vector<bool> seen(graph.size(), false);
    std::vector<int> sizes;

    for (int node = 0; node < static_cast<int>(graph.size()); ++node) {
        if (removed.count(node) || seen[node]) continue;

        std::queue<int> q;
        q.push(node);
        seen[node] = true;
        int size = 0;

        while (!q.empty()) {
            int current = q.front();
            q.pop();
            size++;

            for (int neighbor : graph[current]) {
                if (!removed.count(neighbor) && !seen[neighbor]) {
                    seen[neighbor] = true;
                    q.push(neighbor);
                }
            }
        }

        sizes.push_back(size);
    }

    return sizes;
}

int main() {
    Graph graph = build_graph();
    int n = static_cast<int>(graph.size());

    std::vector<int> nodes(n);
    std::iota(nodes.begin(), nodes.end(), 0);

    std::sort(nodes.begin(), nodes.end(), [&](int a, int b) {
        return graph[a].size() > graph[b].size();
    });

    std::mt19937 rng(60606);

    std::cout << "strategy,removal_fraction,nodes_removed,remaining_nodes,component_count,largest_component_size,largest_component_share\n";
    std::cout << std::fixed << std::setprecision(6);

    for (double fraction : {0.0, 0.05, 0.10, 0.15, 0.20, 0.25}) {
        int k = static_cast<int>(std::round(n * fraction));

        std::vector<int> shuffled = nodes;
        std::shuffle(shuffled.begin(), shuffled.end(), rng);

        for (std::string strategy : {"random_removal", "targeted_high_degree_removal"}) {
            std::set<int> removed;

            for (int i = 0; i < k; ++i) {
                if (strategy == "random_removal") {
                    removed.insert(shuffled[i]);
                } else {
                    removed.insert(nodes[i]);
                }
            }

            std::vector<int> sizes = component_sizes(graph, removed);
            int largest = sizes.empty() ? 0 : *std::max_element(sizes.begin(), sizes.end());
            int remaining = n - static_cast<int>(removed.size());
            double share = remaining > 0 ? static_cast<double>(largest) / static_cast<double>(remaining) : 0.0;

            std::cout
                << strategy << ","
                << fraction << ","
                << k << ","
                << remaining << ","
                << sizes.size() << ","
                << largest << ","
                << share << "\n";
        }
    }

    return 0;
}
