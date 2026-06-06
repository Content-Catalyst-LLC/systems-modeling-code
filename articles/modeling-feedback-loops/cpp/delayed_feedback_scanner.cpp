#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <vector>

std::vector<double> simulate_delayed_balancing(double initial, double target, double correction, int delay, int steps) {
    std::vector<double> values(steps, 0.0);
    values[0] = initial;

    for (int t = 1; t < steps; ++t) {
        int delayed_index = std::max(0, t - delay);
        values[t] = values[t - 1] + correction * (target - values[delayed_index]);
    }

    return values;
}

int target_crossings(const std::vector<double>& values, double target) {
    int changes = 0;

    for (size_t i = 1; i < values.size(); ++i) {
        double left = values[i - 1] - target;
        double right = values[i] - target;

        if (left == 0.0 || right == 0.0) {
            continue;
        }

        if ((left < 0.0 && right > 0.0) || (left > 0.0 && right < 0.0)) {
            changes++;
        }
    }

    return changes;
}

double mean_absolute_gap(const std::vector<double>& values, double target) {
    double total = 0.0;
    for (double value : values) {
        total += std::abs(value - target);
    }
    return total / static_cast<double>(values.size());
}

int main() {
    const double target = 20.0;
    const int steps = 90;

    std::cout << "scenario_id,delay,correction_strength,final_state,maximum_state,minimum_state,overshoot_above_target,target_crossings,mean_absolute_target_gap\n";
    std::cout << std::fixed << std::setprecision(6);

    int scenario_id = 0;

    for (int delay : {1, 3, 5, 8, 12}) {
        for (double correction : {0.12, 0.20, 0.28, 0.36}) {
            scenario_id++;

            std::vector<double> values = simulate_delayed_balancing(5.0, target, correction, delay, steps);
            double maximum = *std::max_element(values.begin(), values.end());
            double minimum = *std::min_element(values.begin(), values.end());
            double overshoot = std::max(0.0, maximum - target);

            std::cout
                << scenario_id << ","
                << delay << ","
                << correction << ","
                << values.back() << ","
                << maximum << ","
                << minimum << ","
                << overshoot << ","
                << target_crossings(values, target) << ","
                << mean_absolute_gap(values, target) << "\n";
        }
    }

    return 0;
}
