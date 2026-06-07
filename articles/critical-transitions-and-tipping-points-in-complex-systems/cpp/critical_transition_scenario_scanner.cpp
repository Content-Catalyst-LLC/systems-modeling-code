#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    double forward_start;
    double forward_end;
    int steps;
    double initial_state;
    double dt;
    double jump_threshold;
};

struct Summary {
    std::string scenario;
    std::string path;
    double initial_state;
    double final_state;
    double minimum_state;
    double maximum_state;
    double maximum_jump_size;
    int transition_flags;
};

double update_state(double x, double r, double dt) {
    return x + dt * (r + x - x * x * x);
}

std::vector<double> linear_space(double start, double stop, int count) {
    std::vector<double> values;
    values.reserve(count);
    double step = (stop - start) / static_cast<double>(count - 1);

    for (int i = 0; i < count; ++i) {
        values.push_back(start + static_cast<double>(i) * step);
    }

    return values;
}

Summary simulate_path(const Scenario& scenario, const std::string& path_name, const std::vector<double>& values, double initial_state) {
    double x = initial_state;
    double minimum_state = x;
    double maximum_state = x;
    double maximum_jump_size = 0.0;
    int transition_flags = 0;

    for (size_t index = 0; index < values.size(); ++index) {
        double previous_x = x;

        if (index > 0) {
            x = update_state(x, values[index], scenario.dt);
        }

        double jump_size = std::abs(x - previous_x);

        if (jump_size > scenario.jump_threshold) {
            transition_flags++;
        }

        minimum_state = std::min(minimum_state, x);
        maximum_state = std::max(maximum_state, x);
        maximum_jump_size = std::max(maximum_jump_size, jump_size);
    }

    return {
        scenario.name,
        path_name,
        initial_state,
        x,
        minimum_state,
        maximum_state,
        maximum_jump_size,
        transition_flags
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_hysteresis", -1.20, 1.20, 300, -1.00, 0.050, 0.150},
        {"slow_forcing", -1.20, 1.20, 500, -1.00, 0.035, 0.120},
        {"fast_forcing", -1.20, 1.20, 150, -1.00, 0.075, 0.220},
        {"wide_forcing", -1.45, 1.45, 360, -1.10, 0.050, 0.150}
    };

    std::cout << "scenario,path,initial_state,final_state,minimum_state,maximum_state,maximum_jump_size,transition_flags\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        std::vector<double> forward = linear_space(scenario.forward_start, scenario.forward_end, scenario.steps);
        Summary forward_summary = simulate_path(scenario, "forward_forcing", forward, scenario.initial_state);

        std::vector<double> backward = linear_space(scenario.forward_end, scenario.forward_start, scenario.steps);
        Summary backward_summary = simulate_path(scenario, "backward_forcing", backward, forward_summary.final_state);

        for (const Summary& result : {forward_summary, backward_summary}) {
            std::cout
                << result.scenario << ","
                << result.path << ","
                << result.initial_state << ","
                << result.final_state << ","
                << result.minimum_state << ","
                << result.maximum_state << ","
                << result.maximum_jump_size << ","
                << result.transition_flags << "\n";
        }
    }

    return 0;
}
