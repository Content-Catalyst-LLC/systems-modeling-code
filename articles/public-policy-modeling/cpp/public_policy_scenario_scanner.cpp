#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    double target_state;
    double system_state;
    double capacity;
    double trust;
    double burden;
    double policy;
    double max_policy;
    double min_policy;
    double policy_increase_rate;
    double policy_decrease_rate;
    double policy_effect;
    double capacity_learning_rate;
    double burden_growth;
    double burden_relief;
    double side_effect_rate;
};

struct Summary {
    std::string scenario;
    double final_system_state;
    double final_policy_intensity;
    double final_capacity;
    double final_trust;
    double maximum_burden;
    double maximum_side_effect;
    double average_uptake;
    double average_policy_intensity;
};

double bounded(double value, double low, double high) {
    return std::max(low, std::min(high, value));
}

Summary simulate(const Scenario& scenario) {
    double system_state = scenario.system_state;
    double capacity = scenario.capacity;
    double trust = scenario.trust;
    double burden = scenario.burden;
    double policy = scenario.policy;
    double side_effect = 0.0;

    double maximum_burden = burden;
    double maximum_side_effect = side_effect;
    double total_uptake = 0.0;
    double total_policy = 0.0;

    for (int time = 0; time < scenario.steps; ++time) {
        double uptake = bounded(
            0.42 + 0.30 * trust + 0.035 * capacity - 0.45 * burden,
            0.0,
            1.0
        );

        double performance_gap = scenario.target_state - system_state;

        if (performance_gap > 0.0) {
            policy = std::min(scenario.max_policy, policy + scenario.policy_increase_rate);
        } else {
            policy = std::max(scenario.min_policy, policy - scenario.policy_decrease_rate);
        }

        double next_state =
            system_state +
            scenario.policy_effect * policy * uptake -
            0.12 * system_state +
            0.05 * capacity;

        double next_capacity = capacity + scenario.capacity_learning_rate * (system_state - capacity);
        double next_burden = std::max(0.0, burden + scenario.burden_growth * policy - scenario.burden_relief * capacity);
        double next_side_effect = std::max(0.0, side_effect + scenario.side_effect_rate * policy - 0.06 * side_effect);
        double next_trust = bounded(trust + 0.015 * uptake - 0.018 * next_burden - 0.010 * next_side_effect, 0.0, 1.0);

        maximum_burden = std::max(maximum_burden, burden);
        maximum_side_effect = std::max(maximum_side_effect, side_effect);
        total_uptake += uptake;
        total_policy += policy;

        system_state = std::max(0.0, next_state);
        capacity = std::max(0.0, next_capacity);
        burden = next_burden;
        side_effect = next_side_effect;
        trust = next_trust;
    }

    return {
        scenario.name,
        system_state,
        policy,
        capacity,
        trust,
        maximum_burden,
        maximum_side_effect,
        total_uptake / static_cast<double>(scenario.steps),
        total_policy / static_cast<double>(scenario.steps)
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_adaptive_policy", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08},
        {"aggressive_policy_rule", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.4, 0.25, 0.14, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08},
        {"low_capacity_learning", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.035, 0.05, 0.025, 0.08},
        {"high_burden_design", 100, 16, 12, 7, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.10, 0.025, 0.08}
    };

    std::cout
        << "scenario,final_system_state,final_policy_intensity,final_capacity,final_trust,"
        << "maximum_burden,maximum_side_effect,average_uptake,average_policy_intensity,diagnostic_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.maximum_burden > 1.0 || result.maximum_side_effect > 1.0
            ? "high burden policy pathway"
            : "manageable policy pathway";

        std::cout
            << result.scenario << ","
            << result.final_system_state << ","
            << result.final_policy_intensity << ","
            << result.final_capacity << ","
            << result.final_trust << ","
            << result.maximum_burden << ","
            << result.maximum_side_effect << ","
            << result.average_uptake << ","
            << result.average_policy_intensity << ","
            << label << "\n";
    }

    return 0;
}
