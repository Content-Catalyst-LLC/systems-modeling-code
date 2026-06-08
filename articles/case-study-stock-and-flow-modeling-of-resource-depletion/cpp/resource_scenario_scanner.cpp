#include <algorithm>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int periods;
    double carrying_capacity;
    double initial_stock;
    double regeneration_rate;
    double initial_demand;
    double demand_growth;
    double extraction_efficiency;
    double conservation_sensitivity;
    double max_conservation;
    double reference_stock_fraction;
    double critical_threshold_fraction;
};

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline",80,100,80,0.080,4.0,0.015,0.120,0.45,0.35,0.70,0.20},
        {"high_demand",80,100,80,0.080,4.0,0.035,0.120,0.45,0.35,0.70,0.20},
        {"conservation",80,100,80,0.080,4.0,0.015,0.120,0.85,0.55,0.70,0.20},
        {"technology_rebound",80,100,80,0.080,4.0,0.030,0.180,0.35,0.30,0.70,0.20},
        {"regeneration_stress",80,100,80,0.045,4.0,0.015,0.120,0.45,0.35,0.70,0.20},
        {"delayed_governance",80,100,80,0.080,4.0,0.025,0.120,0.20,0.20,0.70,0.20}
    };

    std::cout << "scenario,final_stock,minimum_stock,cumulative_extraction,cumulative_regeneration,overshoot_periods\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& s : scenarios) {
        double stock = s.initial_stock;
        double min_stock = stock;
        double cumulative_extraction = 0.0;
        double cumulative_regeneration = 0.0;
        int overshoot_periods = 0;

        for (int t = 0; t < s.periods; ++t) {
            double demand = s.initial_demand;
            for (int j = 0; j < t; ++j) demand *= (1.0 + s.demand_growth);

            double reference_stock = s.reference_stock_fraction * s.carrying_capacity;
            double scarcity = std::max(0.0, 1.0 - stock / reference_stock);
            double conservation = std::min(s.max_conservation, s.conservation_sensitivity * scarcity);
            double effective_demand = demand * (1.0 - conservation);
            double regeneration = s.regeneration_rate * stock * (1.0 - stock / s.carrying_capacity);
            regeneration = std::max(0.0, regeneration);
            double extraction = std::min(effective_demand, std::min(s.extraction_efficiency * stock, stock + regeneration));

            if (extraction > regeneration) overshoot_periods += 1;

            cumulative_extraction += extraction;
            cumulative_regeneration += regeneration;
            stock = std::max(0.0, stock + regeneration - extraction);
            min_stock = std::min(min_stock, stock);
        }

        std::cout << s.name << ","
                  << stock << ","
                  << min_stock << ","
                  << cumulative_extraction << ","
                  << cumulative_regeneration << ","
                  << overshoot_periods << "\n";
    }

    return 0;
}
