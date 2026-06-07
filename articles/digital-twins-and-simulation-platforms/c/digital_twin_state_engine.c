#include <math.h>
#include <stdio.h>

double deterministic_noise(int step, double scale) {
    return sin((double)step * 1.61803398875) * scale;
}

int shock_at(int step) {
    return step == 35 || step == 80 || step == 105;
}

void simulate(
    const char *scenario,
    int steps,
    double initial_state,
    double persistence,
    double drift_amplitude,
    double process_noise,
    double observation_noise,
    double update_gain,
    double anomaly_threshold,
    double intervention_effect,
    double shock_magnitude
) {
    double true_state = initial_state;
    double observed_state = true_state + deterministic_noise(0, observation_noise);
    double twin_state = observed_state;

    printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%d,%d\n",
           scenario, 0, true_state, observed_state, twin_state, 0.0, 0, 0);

    for (int step = 1; step < steps; ++step) {
        double drift = drift_amplitude * sin((double)step / 12.0);
        double shock = shock_at(step) ? shock_magnitude : 0.0;

        true_state = persistence * true_state + drift + shock + deterministic_noise(step, process_noise);
        observed_state = true_state + deterministic_noise(step + 200, observation_noise);

        double prediction = persistence * twin_state + drift;
        double residual = observed_state - prediction;
        int anomaly_flag = fabs(residual) > anomaly_threshold ? 1 : 0;
        int intervention_flag = 0;

        if (residual > anomaly_threshold) {
            intervention_flag = 1;
            prediction -= intervention_effect;
        }

        twin_state = prediction + update_gain * residual;

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%d,%d\n",
               scenario,
               step,
               true_state,
               observed_state,
               twin_state,
               residual,
               anomaly_flag,
               intervention_flag);
    }
}

int main(void) {
    printf("scenario,time,true_state,observed_state,twin_state,residual,anomaly_flag,intervention_flag\n");
    simulate("baseline_twin", 120, 50.0, 0.95, 0.15, 0.60, 1.80, 0.35, 3.50, 1.00, 4.0);
    simulate("high_noise_twin", 120, 50.0, 0.95, 0.15, 0.60, 3.20, 0.30, 4.80, 1.00, 4.0);
    simulate("slow_update_twin", 120, 50.0, 0.95, 0.15, 0.60, 1.80, 0.18, 3.50, 1.00, 4.0);
    simulate("resilient_twin", 120, 50.0, 0.95, 0.15, 0.45, 1.25, 0.45, 3.25, 1.25, 3.5);
    return 0;
}
