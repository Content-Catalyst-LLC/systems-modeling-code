#include <algorithm>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    double initial_stock;
    double carrying_capacity;
    double growth_rate;
    double extraction_rate;
    double restoration_rate;
    int disturbance_step;
    double disturbance_size;
};

struct Summary {
    std::string scenario;
    double final_stock;
    double minimum_stock;
    double maximum_stock;
    double final_resilience_index;
    double average_extraction;
    double average_restoration;
};

Summary simulate(const Scenario& scenario) {
    double stock = scenario.initial_stock;
    double minimum_stock = stock;
    double maximum_stock = stock;
    double total_extraction = 0.0;
    double total_restoration = 0.0;

    for (int step = 1; step <= scenario.steps; ++step) {
        double regeneration = scenario.growth_rate * stock * (1.0 - stock / scenario.carrying_capacity);
        double extraction = scenario.extraction_rate * stock;
        double restoration = scenario.restoration_rate * (scenario.carrying_capacity - stock);
        double disturbance = step == scenario.disturbance_step ? scenario.disturbance_size : 0.0;

        stock = std::max(
            0.0,
            std::min(
                scenario.carrying_capacity,
                stock + regeneration - extraction + restoration - disturbance
            )
        );

        minimum_stock = std::min(minimum_stock, stock);
        maximum_stock = std::max(maximum_stock, stock);
        total_extraction += extraction;
        total_restoration += restoration;
    }

    return {
        scenario.name,
        stock,
        minimum_stock,
        maximum_stock,
        stock / scenario.carrying_capacity,
        total_extraction / static_cast<double>(scenario.steps),
        total_restoration / static_cast<double>(scenario.steps)
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_pressure", 120, 70.0, 100.0, 0.065, 0.040, 0.010, 65, 12.0},
        {"high_extraction", 120, 70.0, 100.0, 0.065, 0.065, 0.010, 65, 12.0},
        {"restoration_investment", 120, 70.0, 100.0, 0.065, 0.040, 0.035, 65, 12.0},
        {"larger_disturbance", 120, 70.0, 100.0, 0.065, 0.040, 0.010, 65, 24.0}
    };

    std::cout
        << "scenario,final_stock,minimum_stock,maximum_stock,final_resilience_index,"
        << "average_extraction,average_restoration,diagnostic_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.final_resilience_index >= 0.70
            ? "recovering pathway"
            : "degraded pathway";

        std::cout
            << result.scenario << ","
            << result.final_stock << ","
            << result.minimum_stock << ","
            << result.maximum_stock << ","
            << result.final_resilience_index << ","
            << result.average_extraction << ","
            << result.average_restoration << ","
            << label << "\n";
    }

    return 0;
}
