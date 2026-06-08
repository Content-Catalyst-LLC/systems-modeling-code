#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct ScenarioSummary {
    std::string scenario;
    int final_failed_count;
    int max_failed_count;
    double max_weighted_service_loss;
    int cascade_depth;
};

int main() {
    std::vector<ScenarioSummary> summaries = {
        {"localized_outage", 1, 1, 0.55, 0},
        {"hub_failure", 6, 6, 5.40, 2},
        {"dependency_cascade", 3, 3, 2.55, 1},
        {"load_redistribution", 3, 3, 2.45, 1},
        {"compound_shock", 8, 8, 6.80, 2},
        {"recovery_intervention", 6, 6, 5.00, 2}
    };

    std::cout << "scenario,final_failed_count,max_failed_count,max_weighted_service_loss,cascade_depth\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& item : summaries) {
        std::cout
            << item.scenario << ","
            << item.final_failed_count << ","
            << item.max_failed_count << ","
            << item.max_weighted_service_loss << ","
            << item.cascade_depth << "\n";
    }

    return 0;
}
