#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

std::vector<double> logistic_map(double r, double initial_state, int steps) {
    std::vector<double> values(steps, 0.0);
    values[0] = initial_state;

    for (int i = 1; i < steps; ++i) {
        values[i] = r * values[i - 1] * (1.0 - values[i - 1]);
    }

    return values;
}

double mean_value(const std::vector<double>& values) {
    double total = 0.0;
    for (double value : values) {
        total += value;
    }
    return total / static_cast<double>(values.size());
}

double sd_value(const std::vector<double>& values) {
    double avg = mean_value(values);
    double total = 0.0;

    for (double value : values) {
        double diff = value - avg;
        total += diff * diff;
    }

    return std::sqrt(total / static_cast<double>(values.size()));
}

int main() {
    const int steps = 300;

    std::cout << "r,tail_mean,tail_sd,tail_minimum,tail_maximum\n";
    std::cout << std::fixed << std::setprecision(8);

    for (int index = 0; index <= 120; ++index) {
        double r = 2.8 + static_cast<double>(index) * (4.0 - 2.8) / 120.0;
        std::vector<double> trajectory = logistic_map(r, 0.41, steps);
        std::vector<double> tail(trajectory.begin() + 200, trajectory.end());

        double tail_min = *std::min_element(tail.begin(), tail.end());
        double tail_max = *std::max_element(tail.begin(), tail.end());

        std::cout
            << r << ","
            << mean_value(tail) << ","
            << sd_value(tail) << ","
            << tail_min << ","
            << tail_max << "\n";
    }

    return 0;
}
