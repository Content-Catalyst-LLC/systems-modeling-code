#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    double initial_state;
    double persistence;
    double drift_amplitude;
    double process_noise;
    double observation_noise;
    double update_gain;
    double anomaly_threshold;
    double intervention_effect;
    double shock_magnitude;
};

struct Summary {
    double observed_mae;
    double twin_mae;
    double observed_rmse;
    double twin_rmse;
    int anomaly_count;
    int intervention_count;
    double improvement;
};

double deterministic_noise(int step, double scale) {
    return std::sin(static_cast<double>(step) * 1.61803398875) * scale;
}

bool shock_at(int step) {
    return step == 35 || step == 80 || step == 105;
}

Summary simulate(const Scenario& scenario) {
    std::vector<double> true_state(scenario.steps, 0.0);
    std::vector<double> observed_state(scenario.steps, 0.0);
    std::vector<double> twin_state(scenario.steps, 0.0);

    int anomaly_count = 0;
    int intervention_count = 0;

    true_state[0] = scenario.initial_state;
    observed_state[0] = true_state[0] + deterministic_noise(0, scenario.observation_noise);
    twin_state[0] = observed_state[0];

    for (int step = 1; step < scenario.steps; ++step) {
        double drift = scenario.drift_amplitude * std::sin(static_cast<double>(step) / 12.0);
        double shock = shock_at(step) ? scenario.shock_magnitude : 0.0;

        true_state[step] = scenario.persistence * true_state[step - 1] + drift + shock + deterministic_noise(step, scenario.process_noise);
        observed_state[step] = true_state[step] + deterministic_noise(step + 200, scenario.observation_noise);

        double prediction = scenario.persistence * twin_state[step - 1] + drift;
        double residual = observed_state[step] - prediction;

        if (std::abs(residual) > scenario.anomaly_threshold) {
            anomaly_count += 1;
        }

        if (residual > scenario.anomaly_threshold) {
            intervention_count += 1;
            prediction -= scenario.intervention_effect;
        }

        twin_state[step] = prediction + scenario.update_gain * residual;
    }

    double observed_abs = 0.0;
    double twin_abs = 0.0;
    double observed_squared = 0.0;
    double twin_squared = 0.0;

    for (int step = 0; step < scenario.steps; ++step) {
        double observed_error = observed_state[step] - true_state[step];
        double twin_error = twin_state[step] - true_state[step];

        observed_abs += std::abs(observed_error);
        twin_abs += std::abs(twin_error);
        observed_squared += observed_error * observed_error;
        twin_squared += twin_error * twin_error;
    }

    double n = static_cast<double>(scenario.steps);
    double observed_mae = observed_abs / n;
    double twin_mae = twin_abs / n;
    double observed_rmse = std::sqrt(observed_squared / n);
    double twin_rmse = std::sqrt(twin_squared / n);
    double improvement = (observed_rmse - twin_rmse) / std::max(observed_rmse, 1e-12);

    return {observed_mae, twin_mae, observed_rmse, twin_rmse, anomaly_count, intervention_count, improvement};
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_twin", 120, 50.0, 0.95, 0.15, 0.60, 1.80, 0.35, 3.50, 1.00, 4.0},
        {"high_noise_twin", 120, 50.0, 0.95, 0.15, 0.60, 3.20, 0.30, 4.80, 1.00, 4.0},
        {"slow_update_twin", 120, 50.0, 0.95, 0.15, 0.60, 1.80, 0.18, 3.50, 1.00, 4.0},
        {"resilient_twin", 120, 50.0, 0.95, 0.15, 0.45, 1.25, 0.45, 3.25, 1.25, 3.5}
    };

    std::cout << "scenario,MAE_observed,MAE_twin,RMSE_observed,RMSE_twin,anomaly_count,intervention_count,tracking_improvement_ratio,diagnostic_label\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.twin_rmse < result.observed_rmse
            ? "twin improved noisy observation"
            : "twin did not improve noisy observation";

        std::cout
            << scenario.name << ","
            << result.observed_mae << ","
            << result.twin_mae << ","
            << result.observed_rmse << ","
            << result.twin_rmse << ","
            << result.anomaly_count << ","
            << result.intervention_count << ","
            << result.improvement << ","
            << label << "\n";
    }

    return 0;
}
