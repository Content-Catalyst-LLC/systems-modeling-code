#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Boundary {
    std::string name;
    double capital_cost;
    double service_reliability;
    double equity_performance;
    double long_term_resilience;
};

double score(const Boundary& boundary) {
    return 0.20 * boundary.capital_cost +
           0.30 * boundary.service_reliability +
           0.25 * boundary.equity_performance +
           0.25 * boundary.long_term_resilience;
}

int main() {
    std::vector<Boundary> boundaries = {
        {"narrow_asset_boundary", 0.80, 0.60, 0.35, 0.50},
        {"expanded_service_boundary", 0.72, 0.75, 0.55, 0.65},
        {"community_resilience_boundary", 0.65, 0.78, 0.85, 0.78},
        {"long_horizon_boundary", 0.60, 0.82, 0.70, 0.90},
        {"multi_stakeholder_boundary", 0.62, 0.76, 0.88, 0.82}
    };

    std::cout
        << "boundary,capital_cost,service_reliability,equity_performance,"
        << "long_term_resilience,composite_score\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const auto& boundary : boundaries) {
        std::cout
            << boundary.name << ","
            << boundary.capital_cost << ","
            << boundary.service_reliability << ","
            << boundary.equity_performance << ","
            << boundary.long_term_resilience << ","
            << score(boundary) << "\n";
    }

    return 0;
}
