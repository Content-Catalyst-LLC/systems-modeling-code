#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct PathwaySummary {
    std::string pathway;
    double final_clean_energy_share;
    double cumulative_emissions;
    double average_climate_damages;
    double average_transition_cost;
    double average_land_pressure;
    double average_water_stress;
    double average_equity_score;
    double final_adaptation_capacity;
    int constraint_breach_count;
    double average_sustainability_score;
};

int main() {
    std::vector<PathwaySummary> summaries = {
        {"equity_centered_transition", 0.998000, 9.800000, 0.010000, 0.081120, 0.535000, 0.440000, 0.720000, 0.810000, 0, 0.285000},
        {"ecological_constraint", 0.978000, 10.400000, 0.011500, 0.064400, 0.430000, 0.420000, 0.630000, 0.770000, 0, 0.270000},
        {"rapid_decarbonization", 1.000000, 8.900000, 0.010800, 0.101600, 0.580000, 0.450000, 0.590000, 0.700000, 0, 0.255000},
        {"adaptation_heavy", 0.846000, 12.100000, 0.009200, 0.045600, 0.560000, 0.410000, 0.580000, 0.920000, 0, 0.240000},
        {"delayed_transition", 0.946000, 13.600000, 0.016000, 0.059600, 0.585000, 0.480000, 0.515000, 0.545000, 3, 0.180000},
        {"baseline_continuation", 0.710000, 17.400000, 0.022000, 0.015840, 0.620000, 0.540000, 0.470000, 0.360000, 12, 0.120000}
    };

    std::cout << "pathway,final_clean_energy_share,cumulative_emissions,average_climate_damages,average_transition_cost,average_land_pressure,average_water_stress,average_equity_score,final_adaptation_capacity,constraint_breach_count,average_sustainability_score\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& item : summaries) {
        std::cout
            << item.pathway << ","
            << item.final_clean_energy_share << ","
            << item.cumulative_emissions << ","
            << item.average_climate_damages << ","
            << item.average_transition_cost << ","
            << item.average_land_pressure << ","
            << item.average_water_stress << ","
            << item.average_equity_score << ","
            << item.final_adaptation_capacity << ","
            << item.constraint_breach_count << ","
            << item.average_sustainability_score << "\n";
    }

    return 0;
}
