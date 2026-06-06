#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

std::vector<double> simulate_managed(double growth, double capacity, double extraction, int steps, double initial) {
    std::vector<double> values(steps, 0.0);
    values[0] = initial;

    for (int i = 1; i < steps; ++i) {
        double previous = values[i - 1];
        double next_value = previous + growth * previous * (1.0 - previous / capacity) - extraction * previous;
        values[i] = std::max(0.0, next_value);
    }

    return values;
}

double rmse(const std::vector<double>& actual, const std::vector<double>& predicted, int start, int end) {
    double total = 0.0;
    int count = 0;

    for (int i = start; i < end; ++i) {
        double diff = actual[i] - predicted[i];
        total += diff * diff;
        count++;
    }

    return std::sqrt(total / static_cast<double>(count));
}

int main() {
    const int steps = 90;
    const int train_cutoff = 60;

    std::mt19937 rng(42);
    std::normal_distribution<double> noise(0.0, 1.1);

    std::vector<double> true_state = simulate_managed(0.085, 130.0, 0.012, steps, 12.0);
    std::vector<double> observed(steps, 0.0);

    for (int i = 0; i < steps; ++i) {
        observed[i] = std::max(0.0, true_state[i] + noise(rng));
    }

    std::cout << "candidate_id,growth,capacity,extraction,calibration_rmse,validation_rmse,generalization_gap\n";
    std::cout << std::fixed << std::setprecision(6);

    int candidate_id = 0;

    for (int gi = 0; gi <= 34; ++gi) {
        double growth = 0.040 + static_cast<double>(gi) * (0.140 - 0.040) / 34.0;

        for (int ci = 0; ci <= 34; ++ci) {
            double capacity = 80.0 + static_cast<double>(ci) * (180.0 - 80.0) / 34.0;

            for (int ei = 0; ei <= 14; ++ei) {
                double extraction = static_cast<double>(ei) * 0.035 / 14.0;
                candidate_id++;

                std::vector<double> prediction = simulate_managed(growth, capacity, extraction, steps, observed[0]);
                double calibration_rmse = rmse(observed, prediction, 0, train_cutoff);
                double validation_rmse = rmse(observed, prediction, train_cutoff, steps);

                std::cout
                    << candidate_id << ","
                    << growth << ","
                    << capacity << ","
                    << extraction << ","
                    << calibration_rmse << ","
                    << validation_rmse << ","
                    << validation_rmse - calibration_rmse << "\n";
            }
        }
    }

    return 0;
}
