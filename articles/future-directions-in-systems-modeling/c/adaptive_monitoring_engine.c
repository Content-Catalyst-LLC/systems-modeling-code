#include <math.h>
#include <stdio.h>

int main(void) {
    const int n = 24;
    double true_state = 12.0;
    double estimate = 12.0;
    double observed = 12.0;
    double drift = 0.0;

    printf("time,true_state,observed_state,estimated_state,residual,drift_indicator,intervention_flag\n");

    for (int t = 0; t < n; ++t) {
        double shock = (t == 8 || t == 16) ? 4.0 : 0.0;
        true_state = 0.93 * true_state + 0.3 * sin((double)t / 10.0) + shock;
        observed = true_state + 0.4 * sin((double)t / 3.0);

        double prediction = 0.93 * estimate + 0.3 * sin((double)t / 10.0);
        double residual = observed - prediction;
        int intervention = fabs(residual) > 3.0 ? 1 : 0;

        if (intervention) {
            prediction = prediction + 0.25 * residual;
        }

        estimate = 0.70 * prediction + 0.30 * observed;
        drift = 0.80 * drift + 0.20 * fabs(observed - estimate);

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%d\n",
               t, true_state, observed, estimate, residual, drift, intervention);
    }

    return 0;
}
