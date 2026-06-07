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
    double workload;
    double trust;
    double demand_growth;
    double hiring_rate;
    double learning_rate;
    double burnout_sensitivity;
    double recovery_rate;
    double attrition_sensitivity;
    double coordination_burden_rate;
    double trust_loss_rate;
    double trust_gain_rate;
};

struct Summary {
    std::string scenario;
    double final_capacity;
    double final_workload;
    double final_backlog;
    double final_trust;
    double maximum_pressure;
    double maximum_burnout;
    double total_attrition;
    double average_delivery;
    double minimum_trust;
};

double bounded(double value, double low, double high) {
    return std::max(low, std::min(high, value));
}

Summary simulate(const Scenario& scenario) {
    double capacity = scenario.capacity;
    double workload = scenario.workload;
    double initial_workload = scenario.workload;
    double trust = scenario.trust;
    double backlog = 0.0;
    double burnout = 0.10;

    double maximum_pressure = 0.0;
    double maximum_burnout = burnout;
    double total_attrition = 0.0;
    double total_delivery = 0.0;
    double minimum_trust = trust;

    for (int time = 0; time < scenario.steps; ++time) {
        double pressure = workload / std::max(capacity, 1.0);
        double slack = std::max(1.0 - pressure, 0.0);
        double learning = scenario.learning_rate * capacity * slack * trust;
        double coordination_burden = scenario.coordination_burden_rate * std::max(pressure - 1.0, 0.0) * capacity;

        burnout = std::max(0.0, burnout + scenario.burnout_sensitivity * std::max(pressure - 1.0, 0.0) - scenario.recovery_rate * slack);
        double attrition = scenario.attrition_sensitivity * burnout * capacity;
        double effective_capacity = std::max(0.0, capacity + scenario.hiring_rate + learning - attrition - coordination_burden);
        double delivery = std::min(workload, effective_capacity);
        backlog = std::max(0.0, backlog + workload - delivery);
        trust = bounded(trust + scenario.trust_gain_rate * slack - scenario.trust_loss_rate * std::max(pressure - 1.0, 0.0) - 0.005 * burnout, 0.0, 1.0);

        maximum_pressure = std::max(maximum_pressure, pressure);
        maximum_burnout = std::max(maximum_burnout, burnout);
        total_attrition += attrition;
        total_delivery += delivery;
        minimum_trust = std::min(minimum_trust, trust);

        capacity = effective_capacity;
        workload = initial_workload + scenario.demand_growth * static_cast<double>(time + 1) + 0.10 * backlog;
    }

    return {
        scenario.name,
        capacity,
        workload,
        backlog,
        trust,
        maximum_pressure,
        maximum_burnout,
        total_attrition,
        total_delivery / static_cast<double>(scenario.steps),
        minimum_trust
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_organization", 100, 100, 95, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010},
        {"high_demand_growth", 100, 100, 95, 0.62, 0.85, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010},
        {"faster_hiring", 100, 100, 95, 0.62, 0.45, 1.25, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010},
        {"high_coordination_burden", 100, 100, 95, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.22, 0.030, 0.010}
    };

    std::cout
        << "scenario,final_capacity,final_workload,final_backlog,final_trust,"
        << "maximum_pressure,maximum_burnout,total_attrition,average_delivery,minimum_trust,diagnostic_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.maximum_pressure > 1.25 || result.maximum_burnout > 0.60 || result.minimum_trust < 0.30
            ? "unsustainable operating pathway"
            : "manageable operating pathway";

        std::cout
            << result.scenario << ","
            << result.final_capacity << ","
            << result.final_workload << ","
            << result.final_backlog << ","
            << result.final_trust << ","
            << result.maximum_pressure << ","
            << result.maximum_burnout << ","
            << result.total_attrition << ","
            << result.average_delivery << ","
            << result.minimum_trust << ","
            << label << "\n";
    }

    return 0;
}
