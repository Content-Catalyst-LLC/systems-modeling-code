#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int delay;
    double correction_strength;
    double counterresponse_strength;
    double perception_smoothing;
};

int target_crossings(const std::vector<double>& values, double target) {
    int crossings = 0;
    for (size_t i = 1; i < values.size(); ++i) {
        double left_gap = values[i - 1] - target;
        double right_gap = values[i] - target;

        if (left_gap == 0.0 || right_gap == 0.0) {
            continue;
        }

        if ((left_gap < 0.0 && right_gap > 0.0) || (left_gap > 0.0 && right_gap < 0.0)) {
            crossings++;
        }
    }
    return crossings;
}

int main() {
    std::vector<Scenario> scenarios = {
        {"timely_moderate_response", 1, 0.18, 0.00, 0.75},
        {"delayed_response", 6, 0.18, 0.00, 0.55},
        {"overcorrection", 6, 0.34, 0.00, 0.55},
        {"undercorrection", 6, 0.09, 0.00, 0.55},
        {"policy_resistance", 6, 0.24, 0.42, 0.55},
        {"slow_recognition_high_resistance", 10, 0.24, 0.55, 0.35}
    };

    const int steps = 100;
    const double target = 50.0;

    std::cout << "scenario,initial_state,final_state,minimum_state,maximum_state,target_crossings,maximum_overshoot_above_target,mean_absolute_target_gap,cumulative_intervention,cumulative_counterresponse,resistance_ratio\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        std::vector<double> state(steps, 0.0);
        std::vector<double> perceived(steps, 0.0);
        std::vector<double> intervention(steps, 0.0);
        std::vector<double> counterresponse(steps, 0.0);

        state[0] = 80.0;
        perceived[0] = 80.0;

        for (int t = 1; t < steps; ++t) {
            perceived[t] = scenario.perception_smoothing * state[t - 1] + (1.0 - scenario.perception_smoothing) * perceived[t - 1];

            int observed_index = std::max(0, t - scenario.delay);
            double observed_gap = perceived[observed_index] - target;

            double action = scenario.correction_strength * std::max(0.0, observed_gap);
            double response = scenario.counterresponse_strength * action;
            double natural_pressure = 2.0 + 0.025 * state[t - 1];

            intervention[t] = action;
            counterresponse[t] = response;
            state[t] = std::max(0.0, state[t - 1] + natural_pressure + response - action);
        }

        double minimum = *std::min_element(state.begin(), state.end());
        double maximum = *std::max_element(state.begin(), state.end());
        double gap_total = 0.0;
        double intervention_total = 0.0;
        double counterresponse_total = 0.0;

        for (int t = 0; t < steps; ++t) {
            gap_total += std::abs(state[t] - target);
            intervention_total += intervention[t];
            counterresponse_total += counterresponse[t];
        }

        double resistance_ratio = intervention_total > 0.0 ? counterresponse_total / intervention_total : 0.0;

        std::cout
            << scenario.name << ","
            << state.front() << ","
            << state.back() << ","
            << minimum << ","
            << maximum << ","
            << target_crossings(state, target) << ","
            << std::max(0.0, maximum - target) << ","
            << gap_total / static_cast<double>(steps) << ","
            << intervention_total << ","
            << counterresponse_total << ","
            << resistance_ratio << "\n";
    }

    return 0;
}
