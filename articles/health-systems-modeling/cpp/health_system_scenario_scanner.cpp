#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    double capacity;
    double demand;
    double trust;
    double demand_growth;
    double prevention_effect;
    double workforce_recovery;
    double burnout_sensitivity;
    double attrition_sensitivity;
    double hiring_rate;
    double access_barrier;
    double trust_loss_rate;
    double trust_gain_rate;
    int surge_start;
    int surge_end;
    double surge_intensity;
};

struct Summary {
    std::string scenario;
    double final_capacity;
    double final_backlog;
    double final_trust;
    double maximum_pressure;
    double maximum_burnout;
    double total_unmet_need;
    double average_access_gap;
    double minimum_trust;
};

double bounded(double value, double low, double high) {
    return std::max(low, std::min(high, value));
}

Summary simulate(const Scenario& scenario) {
    double capacity = scenario.capacity;
    double demand = scenario.demand;
    double initial_demand = scenario.demand;
    double trust = scenario.trust;
    double backlog = 0.0;
    double burnout = 0.12;

    double maximum_pressure = 0.0;
    double maximum_burnout = burnout;
    double total_unmet_need = 0.0;
    double total_access_gap = 0.0;
    double minimum_trust = trust;

    for (int time = 0; time < scenario.steps; ++time) {
        double pressure = demand / std::max(capacity, 1.0);
        double slack = std::max(1.0 - pressure, 0.0);
        burnout = std::max(0.0, burnout + scenario.burnout_sensitivity * std::max(pressure - 1.0, 0.0) - scenario.workforce_recovery * slack);
        double attrition = scenario.attrition_sensitivity * burnout * capacity;
        double surge = (time >= scenario.surge_start && time <= scenario.surge_end) ? scenario.surge_intensity : 0.0;
        double effective_capacity = std::max(0.0, capacity + scenario.hiring_rate - attrition - 0.10 * std::max(pressure - 1.0, 0.0) * capacity);
        double served = std::min(demand, effective_capacity);
        double unmet_need = std::max(demand - served, 0.0);
        double access_gap = scenario.access_barrier * demand + unmet_need;
        backlog = std::max(0.0, backlog + demand - served);
        trust = bounded(trust + scenario.trust_gain_rate * slack - scenario.trust_loss_rate * std::max(pressure - 1.0, 0.0) - 0.004 * access_gap / std::max(demand, 1.0), 0.0, 1.0);

        maximum_pressure = std::max(maximum_pressure, pressure);
        maximum_burnout = std::max(maximum_burnout, burnout);
        total_unmet_need += unmet_need;
        total_access_gap += access_gap;
        minimum_trust = std::min(minimum_trust, trust);

        capacity = effective_capacity;
        double prevention_reduction = scenario.prevention_effect * static_cast<double>(time + 1);
        demand = std::max(0.0, initial_demand + scenario.demand_growth * static_cast<double>(time + 1) + surge - prevention_reduction + 0.08 * backlog);
    }

    return {
        scenario.name,
        capacity,
        backlog,
        trust,
        maximum_pressure,
        maximum_burnout,
        total_unmet_need,
        total_access_gap / static_cast<double>(scenario.steps),
        minimum_trust
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_health_system", 120, 100, 92, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18},
        {"higher_demand_growth", 120, 100, 92, 0.64, 0.65, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18},
        {"stronger_prevention", 120, 100, 92, 0.70, 0.35, 0.060, 0.035, 0.085, 0.030, 0.50, 0.16, 0.018, 0.018, 45, 65, 18},
        {"larger_surge", 120, 100, 92, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 32}
    };

    std::cout
        << "scenario,final_capacity,final_backlog,final_trust,maximum_pressure,"
        << "maximum_burnout,total_unmet_need,average_access_gap,minimum_trust,diagnostic_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.maximum_pressure > 1.25 || result.total_unmet_need > 1000 || result.minimum_trust < 0.35
            ? "high strain health system pathway"
            : "manageable health system pathway";

        std::cout
            << result.scenario << ","
            << result.final_capacity << ","
            << result.final_backlog << ","
            << result.final_trust << ","
            << result.maximum_pressure << ","
            << result.maximum_burnout << ","
            << result.total_unmet_need << ","
            << result.average_access_gap << ","
            << result.minimum_trust << ","
            << label << "\n";
    }

    return 0;
}
