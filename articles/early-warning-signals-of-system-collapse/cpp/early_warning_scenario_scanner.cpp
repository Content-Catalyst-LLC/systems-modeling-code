#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    double stability_start;
    double stability_end;
    double noise_sd;
    int window;
};

struct Summary {
    std::string scenario;
    double final_stability;
    double final_state;
    double maximum_abs_state;
    double final_rolling_variance;
};

double linear_value(double start, double stop, int index, int count) {
    double step = (stop - start) / static_cast<double>(count - 1);
    return start + static_cast<double>(index) * step;
}

double deterministic_noise(int index, double scale) {
    return std::sin(static_cast<double>(index) * 1.61803398875) * scale;
}

double rolling_variance(const std::vector<double>& values) {
    if (values.size() < 2) {
        return 0.0;
    }

    double mean_value = std::accumulate(values.begin(), values.end(), 0.0) / static_cast<double>(values.size());
    double ss = 0.0;

    for (double value : values) {
        double delta = value - mean_value;
        ss += delta * delta;
    }

    return ss / static_cast<double>(values.size() - 1);
}

Summary simulate(const Scenario& scenario) {
    double state = 0.0;
    double max_abs_state = 0.0;
    double final_variance = 0.0;
    std::vector<double> history;

    for (int index = 0; index < scenario.steps; ++index) {
        double stability = linear_value(scenario.stability_start, scenario.stability_end, index, scenario.steps);

        if (index > 0) {
            state = stability * state + deterministic_noise(index, scenario.noise_sd);
        }

        history.push_back(state);
        max_abs_state = std::max(max_abs_state, std::abs(state));

        if (static_cast<int>(history.size()) >= scenario.window) {
            std::vector<double> recent(history.end() - scenario.window, history.end());
            final_variance = rolling_variance(recent);
        }
    }

    return {
        scenario.name,
        scenario.stability_end,
        state,
        max_abs_state,
        final_variance
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_destabilization", 320, 0.55, 0.985, 1.00, 25},
        {"moderate_destabilization", 320, 0.45, 0.900, 1.00, 25},
        {"high_noise_destabilization", 320, 0.55, 0.985, 1.40, 25},
        {"low_noise_destabilization", 320, 0.55, 0.985, 0.65, 25}
    };

    std::cout << "scenario,final_stability,final_state,maximum_abs_state,final_rolling_variance\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::cout
            << result.scenario << ","
            << result.final_stability << ","
            << result.final_state << ","
            << result.maximum_abs_state << ","
            << result.final_rolling_variance << "\n";
    }

    return 0;
}
