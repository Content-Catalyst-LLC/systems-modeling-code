#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    double feedback_gain;
    double external_correction;
    double rule_threshold;
    double rule_feedback_gain;
    bool has_rule;
    double goal_weight;
};

struct Result {
    double initial_state;
    double final_state;
    double maximum_state;
    double mean_pressure;
    double final_resilience;
    double cumulative_intervention;
};

Result simulate(const Scenario& scenario, int steps) {
    double state = 70.0;
    double pressure = 50.0;
    double resilience = 30.0;
    double intervention = 0.0;
    double maximum_state = state;
    double pressure_total = 0.0;
    double intervention_total = 0.0;

    for (int time = 1; time <= steps; ++time) {
        maximum_state = std::max(maximum_state, state);
        pressure_total += pressure;
        intervention_total += intervention;

        double current_gain = scenario.feedback_gain;
        if (scenario.has_rule && state > scenario.rule_threshold) {
            current_gain = scenario.rule_feedback_gain;
        }

        double resilience_gap = std::max(0.0, 100.0 - resilience);
        double resilience_investment = scenario.goal_weight * resilience_gap;
        intervention = scenario.external_correction + 0.05 * std::max(0.0, state - 40.0) + resilience_investment;

        double next_pressure = std::max(0.0, 0.91 * pressure + 0.07 * state - 0.30 * intervention - 0.04 * resilience);
        double next_resilience = std::min(100.0, std::max(0.0, resilience + 0.18 * resilience_investment - 0.025 * pressure));
        double next_state = std::max(0.0, current_gain * state + 0.24 * next_pressure - 0.34 * intervention - 0.045 * next_resilience);

        pressure = next_pressure;
        resilience = next_resilience;
        state = next_state;
    }

    return {70.0, state, maximum_state, pressure_total / static_cast<double>(steps), resilience, intervention_total};
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline", 0.96, 2.0, 0.0, 0.96, false, 0.00},
        {"parameter_intervention", 0.96, 5.0, 0.0, 0.96, false, 0.00},
        {"feedback_intervention", 0.78, 2.0, 0.0, 0.78, false, 0.00},
        {"rule_intervention", 0.96, 2.0, 45.0, 0.70, true, 0.00},
        {"goal_intervention", 0.90, 2.0, 45.0, 0.72, true, 0.10}
    };

    std::vector<Result> results;
    for (const Scenario& scenario : scenarios) {
        results.push_back(simulate(scenario, 96));
    }

    double baseline_final = results[0].final_state;

    std::cout << "scenario,initial_state,final_state,maximum_state,mean_pressure,final_resilience,cumulative_intervention,behavior_change_from_baseline,leverage_ratio\n";
    std::cout << std::fixed << std::setprecision(6);

    for (size_t i = 0; i < scenarios.size(); ++i) {
        double behavior_change = baseline_final - results[i].final_state;
        double leverage_ratio = results[i].cumulative_intervention > 0.0 ? behavior_change / results[i].cumulative_intervention : 0.0;

        std::cout
            << scenarios[i].name << ","
            << results[i].initial_state << ","
            << results[i].final_state << ","
            << results[i].maximum_state << ","
            << results[i].mean_pressure << ","
            << results[i].final_resilience << ","
            << results[i].cumulative_intervention << ","
            << behavior_change << ","
            << leverage_ratio << "\n";
    }

    return 0;
}
