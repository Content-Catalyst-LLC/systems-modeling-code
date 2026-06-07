#include <iostream>
#include <string>
#include <vector>

struct Node {
    std::string sector;
    double capacity;
    double load;
    double threshold;
};

int main() {
    std::vector<Node> nodes = {
        {"energy", 100.0, 62.0, 0.75},
        {"water", 85.0, 70.0, 0.70},
        {"telecom", 90.0, 58.0, 0.72},
        {"health", 95.0, 82.0, 0.78}
    };

    std::cout << "Cascade capacity diagnostics\n";

    for (const auto& node : nodes) {
        double load_ratio = node.load / node.capacity;
        std::string status = load_ratio >= node.threshold ? "failure risk" : "within threshold";
        std::cout << node.sector << " load_ratio=" << load_ratio << " threshold=" << node.threshold << " status=" << status << "\n";
    }

    return 0;
}
