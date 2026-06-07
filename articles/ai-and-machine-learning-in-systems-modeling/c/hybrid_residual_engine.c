#include <math.h>
#include <stdio.h>

double deterministic_noise(int index, double scale) {
    return sin((double)index * 1.61803398875) * scale;
}

double structural_baseline(double a, double b, double c, double structural_weight) {
    return structural_weight * (1.8 * sin(a) + 0.6 * b - 0.4 * c);
}

void run_scenario(
    const char *scenario,
    int n,
    double noise_scale,
    double structural_weight,
    double residual_strength,
    double interaction_strength,
    double drift_strength
) {
    double baseline_squared = 0.0;
    double hybrid_squared = 0.0;
    double baseline_abs = 0.0;
    double hybrid_abs = 0.0;

    for (int i = 0; i < n; ++i) {
        double share = (double)i / fmax((double)(n - 1), 1.0);
        double a = fmod((double)i * 0.137, 10.0);
        double b = sin((double)i * 0.071) * 3.0;
        double c = 1.0 + fmod((double)i * 0.173, 7.0);

        double baseline = structural_baseline(a, b, c, structural_weight);
        double true_residual = residual_strength * b * b +
                               interaction_strength * a * b +
                               drift_strength * share * b +
                               deterministic_noise(i, noise_scale);

        double true_response = baseline + true_residual;
        double learned_residual = residual_strength * b * b +
                                  interaction_strength * a * b +
                                  drift_strength * share * b;
        double hybrid_prediction = baseline + learned_residual;

        double baseline_error = true_response - baseline;
        double hybrid_error = true_response - hybrid_prediction;

        baseline_squared += baseline_error * baseline_error;
        hybrid_squared += hybrid_error * hybrid_error;
        baseline_abs += fabs(baseline_error);
        hybrid_abs += fabs(hybrid_error);
    }

    double count = (double)n;
    double baseline_rmse = sqrt(baseline_squared / count);
    double hybrid_rmse = sqrt(hybrid_squared / count);
    double baseline_mae = baseline_abs / count;
    double hybrid_mae = hybrid_abs / count;
    double improvement = (baseline_rmse - hybrid_rmse) / fmax(baseline_rmse, 1e-12);

    printf("%s,%.6f,%.6f,%.6f,%.6f,%.6f,%s\n",
           scenario,
           baseline_rmse,
           hybrid_rmse,
           baseline_mae,
           hybrid_mae,
           improvement,
           hybrid_rmse < baseline_rmse ? "hybrid improved baseline" : "hybrid did not improve baseline");
}

int main(void) {
    printf("scenario,baseline_rmse,hybrid_rmse,baseline_mae,hybrid_mae,hybrid_improvement_ratio,diagnostic_label\n");
    run_scenario("baseline_hybrid", 1000, 0.50, 1.00, 0.70, 0.25, 0.00);
    run_scenario("high_noise_system", 1000, 0.95, 1.00, 0.70, 0.25, 0.00);
    run_scenario("strong_residual_system", 1000, 0.50, 1.00, 1.10, 0.38, 0.00);
    run_scenario("drifting_system", 1000, 0.55, 1.00, 0.70, 0.25, 0.45);
    return 0;
}
