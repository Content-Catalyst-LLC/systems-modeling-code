#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct ScenarioSummary {
    std::string scenario;
    double average_service;
    double minimum_service;
    int time_below_threshold;
    int threshold_crossings;
    double final_capacity;
    double final_degradation;
    int transformed;
    double resilience_score;
};

int main() {
    std::vector<ScenarioSummary> summaries = {
        {"targeted_resilience_investment", 0.720000, 0.590000, 0, 0, 0.870000, 0.060000, 0, 0.699000},
        {"moderate_climate_stress", 0.690000, 0.560000, 0, 0, 0.720000, 0.080000, 0, 0.662000},
        {"transformation_pathway", 0.610000, 0.520000, 5, 2, 0.760000, 0.170000, 1, 0.476000},
        {"repeated_shocks", 0.590000, 0.480000, 9, 3, 0.610000, 0.160000, 0, 0.399000},
        {"delayed_adaptation", 0.550000, 0.430000, 14, 4, 0.600000, 0.210000, 0, 0.266500},
        {"compound_climate_stress", 0.490000, 0.360000, 24, 5, 0.500000, 0.300000, 0, 0.025000}
    };

    std::cout << "scenario,average_service,minimum_service,time_below_threshold,threshold_crossings,final_adaptive_capacity,final_degradation,transformed,resilience_score\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& item : summaries) {
        std::cout
            << item.scenario << ","
            << item.average_service << ","
            << item.minimum_service << ","
            << item.time_below_threshold << ","
            << item.threshold_crossings << ","
            << item.final_capacity << ","
            << item.final_degradation << ","
            << item.transformed << ","
            << item.resilience_score << "\n";
    }

    return 0;
}
