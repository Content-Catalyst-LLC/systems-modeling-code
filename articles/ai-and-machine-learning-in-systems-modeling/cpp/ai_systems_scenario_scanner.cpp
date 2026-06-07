#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int n;
    double noise_scale;
    double structural_weight;
    double residual_strength;
    double interaction_strength;
    double drift_strength;
};

struct Summary {
    double baseline_rmse;
    double hybrid_rmse;
    double baseline_mae;
    double hybrid_mae;
    double improvement;
};

double deterministic_noise(int index, double scale) {
    return std::sin(static_cast<double>(index) * 1.61803398875) * scale;
}

double baseline(double a, double b, double c, double structural_weight) {
    return structural_weight * (1.8 * std::sin(a) + 0.6 * b - 0.4 * c);
}

Summary simulate(const Scenario& s) {
    double baseline_squared = 0.0;
    double hybrid_squared = 0.0;
    double baseline_abs = 0.0;
    double hybrid_abs = 0.0;

    for (int i = 0; i < s.n; ++i) {
        double share = static_cast<double>(i) / std::max(static_cast<double>(s.n - 1), 1.0);
        double a = std::fmod(static_cast<double>(i) * 0.137, 10.0);
        double b = std::sin(static_cast<double>(i) * 0.071) * 3.0;
        double c = 1.0 + std::fmod(static_cast<double>(i) * 0.173, 7.0);

        double structural_baseline = baseline(a, b, c, s.structural_weight);
        double true_residual = s.residual_strength * b * b +
                               s.interaction_strength * a * b +
                               s.drift_strength * share * b +
                               deterministic_noise(i, s.noise_scale);

        double true_response = structural_baseline + true_residual;
        double learned_residual = s.residual_strength * b * b +
                                  s.interaction_strength * a * b +
                                  s.drift_strength * share * b;

        double hybrid_prediction = structural_baseline + learned_residual;

        double baseline_error = true_response - structural_baseline;
        double hybrid_error = true_response - hybrid_prediction;

        baseline_squared += baseline_error * baseline_error;
        hybrid_squared += hybrid_error * hybrid_error;
        baseline_abs += std::abs(baseline_error);
        hybrid_abs += std::abs(hybrid_error);
    }

    double count = static_cast<double>(s.n);
    double baseline_rmse = std::sqrt(baseline_squared / count);
    double hybrid_rmse = std::sqrt(hybrid_squared / count);
    double baseline_mae = baseline_abs / count;
    double hybrid_mae = hybrid_abs / count;
    double improvement = (baseline_rmse - hybrid_rmse) / std::max(baseline_rmse, 1e-12);

    return {baseline_rmse, hybrid_rmse, baseline_mae, hybrid_mae, improvement};
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_hybrid", 1000, 0.50, 1.00, 0.70, 0.25, 0.00},
        {"high_noise_system", 1000, 0.95, 1.00, 0.70, 0.25, 0.00},
        {"strong_residual_system", 1000, 0.50, 1.00, 1.10, 0.38, 0.00},
        {"drifting_system", 1000, 0.55, 1.00, 0.70, 0.25, 0.45}
    };

    std::cout << "scenario,baseline_rmse,hybrid_rmse,baseline_mae,hybrid_mae,hybrid_improvement_ratio,diagnostic_label\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.hybrid_rmse < result.baseline_rmse
            ? "hybrid improved baseline"
            : "hybrid did not improve baseline";

        std::cout
            << scenario.name << ","
            << result.baseline_rmse << ","
            << result.hybrid_rmse << ","
            << result.baseline_mae << ","
            << result.hybrid_mae << ","
            << result.improvement << ","
            << label << "\n";
    }

    return 0;
}
