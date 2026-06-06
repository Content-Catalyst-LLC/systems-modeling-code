#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

std::vector<double> simulate_model(double growth_rate, double carrying_capacity, int n_steps, double initial_state) {
    std::vector<double> values(n_steps, 0.0);
    values[0] = initial_state;

    for (int i = 1; i < n_steps; ++i) {
        double previous = values[i - 1];
        double next_value = previous + growth_rate * previous * (1.0 - previous / carrying_capacity);
        values[i] = std::max(0.0, next_value);
    }

    return values;
}

double rmse(const std::vector<double>& actual, const std::vector<double>& predicted) {
    double total = 0.0;

    for (std::size_t i = 0; i < actual.size(); ++i) {
        double diff = actual[i] - predicted[i];
        total += diff * diff;
    }

    return std::sqrt(total / static_cast<double>(actual.size()));
}

int main() {
    const int n_steps = 80;
    const int train_cutoff = 52;
    const double true_growth = 0.095;
    const double true_capacity = 120.0;

    std::mt19937 rng(42);
    std::normal_distribution<double> noise(0.0, 0.85);

    std::vector<double> true_state = simulate_model(true_growth, true_capacity, n_steps, 10.0);
    std::vector<double> observed(n_steps, 0.0);

    for (int i = 0; i < n_steps; ++i) {
        observed[i] = std::max(0.0, true_state[i] + noise(rng));
    }

    std::vector<double> train_observed(observed.begin(), observed.begin() + train_cutoff);
    std::vector<double> valid_observed(observed.begin() + train_cutoff, observed.end());

    std::cout << "candidate_id,growth_rate,carrying_capacity,calibration_rmse,validation_rmse,generalization_gap\n";
    std::cout << std::fixed << std::setprecision(6);

    int candidate_id = 0;

    for (int gi = 0; gi <= 64; ++gi) {
        double growth_rate = 0.040 + static_cast<double>(gi) * (0.200 - 0.040) / 64.0;

        for (int ci = 0; ci <= 44; ++ci) {
            double carrying_capacity = 70.0 + static_cast<double>(ci) * (180.0 - 70.0) / 44.0;
            candidate_id++;

            std::vector<double> train_predicted = simulate_model(growth_rate, carrying_capacity, static_cast<int>(train_observed.size()), train_observed[0]);
            std::vector<double> valid_all = simulate_model(growth_rate, carrying_capacity, static_cast<int>(valid_observed.size()) + 1, train_observed.back());
            std::vector<double> valid_predicted(valid_all.begin() + 1, valid_all.end());

            double calibration_rmse = rmse(train_observed, train_predicted);
            double validation_rmse = rmse(valid_observed, valid_predicted);

            std::cout
                << candidate_id << ","
                << growth_rate << ","
                << carrying_capacity << ","
                << calibration_rmse << ","
                << validation_rmse << ","
                << validation_rmse - calibration_rmse << "\n";
        }
    }

    return 0;
}
