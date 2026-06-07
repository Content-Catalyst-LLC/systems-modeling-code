#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    double population;
    double housing;
    double transport;
    double service_capacity;
    double growth_pressure;
    double accessibility_attraction;
    double congestion_penalty;
    double housing_constraint_penalty;
    double housing_build_rate;
    double transport_investment_rate;
    double service_investment_rate;
    double periodic_policy_investment;
    int policy_interval;
    double pressure_penalty;
};

struct Summary {
    std::string scenario;
    double final_population;
    double final_housing;
    double final_transport;
    double final_service_capacity;
    double final_accessibility;
    double maximum_service_pressure;
    double maximum_housing_gap;
};

Summary simulate(const Scenario& scenario) {
    double population = scenario.population;
    double housing = scenario.housing;
    double transport = scenario.transport;
    double service_capacity = scenario.service_capacity;

    double maximum_service_pressure = 0.0;
    double maximum_housing_gap = 0.0;
    double final_accessibility = 0.0;

    for (int step = 1; step <= scenario.steps; ++step) {
        double accessibility = transport / (1.0 + 0.010 * population);
        double congestion = population / std::max(transport, 1.0);
        double housing_gap = std::max(population - housing, 0.0);
        double service_pressure = population / std::max(service_capacity, 1.0);
        double policy_investment = step % scenario.policy_interval == 0
            ? scenario.periodic_policy_investment
            : 0.0;

        maximum_service_pressure = std::max(maximum_service_pressure, service_pressure);
        maximum_housing_gap = std::max(maximum_housing_gap, housing_gap);
        final_accessibility = accessibility;

        double pressure_drag = scenario.pressure_penalty * std::max(service_pressure - 1.0, 0.0);
        double congestion_drag = scenario.congestion_penalty * std::max(congestion - 1.0, 0.0);
        double housing_drag = scenario.housing_constraint_penalty * housing_gap / 20.0;

        double population_change =
            scenario.growth_pressure +
            scenario.accessibility_attraction * accessibility / 55.0 -
            congestion_drag -
            housing_drag -
            pressure_drag;

        population = std::max(0.0, population + population_change);
        housing = std::max(0.0, housing + scenario.housing_build_rate + 0.020 * population - 0.004 * housing);
        transport = std::max(1.0, transport + scenario.transport_investment_rate + 0.010 * housing - 0.030 * std::max(congestion - 1.0, 0.0));
        service_capacity = std::max(1.0, service_capacity + scenario.service_investment_rate + policy_investment - 0.003 * service_capacity);
    }

    return {
        scenario.name,
        population,
        housing,
        transport,
        service_capacity,
        final_accessibility,
        maximum_service_pressure,
        maximum_housing_gap
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_neighborhood", 100, 100, 112, 90, 120, 1.10, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35, 8, 20, 0.70},
        {"strong_growth_pressure", 100, 100, 112, 90, 120, 1.65, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35, 8, 20, 0.70},
        {"housing_constraint", 100, 100, 106, 90, 120, 1.10, 1.25, 0.70, 0.55, 0.25, 0.45, 0.35, 8, 20, 0.70},
        {"transport_investment", 100, 100, 112, 90, 120, 1.10, 1.25, 0.70, 0.45, 0.65, 1.15, 0.85, 10, 20, 0.70}
    };

    std::cout
        << "scenario,final_population,final_housing,final_transport,final_service_capacity,"
        << "final_accessibility,maximum_service_pressure,maximum_housing_gap,diagnostic_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.maximum_service_pressure > 1.0 || result.maximum_housing_gap > 10.0
            ? "capacity constrained pathway"
            : "managed growth pathway";

        std::cout
            << result.scenario << ","
            << result.final_population << ","
            << result.final_housing << ","
            << result.final_transport << ","
            << result.final_service_capacity << ","
            << result.final_accessibility << ","
            << result.maximum_service_pressure << ","
            << result.maximum_housing_gap << ","
            << label << "\n";
    }

    return 0;
}
