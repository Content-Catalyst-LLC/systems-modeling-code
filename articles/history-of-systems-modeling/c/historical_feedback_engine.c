#include <math.h>
#include <stdio.h>

#define N_STEPS 160
#define HISTORY_SIZE 200

static double clamp(double value, double low, double high) {
    if (value < low) return low;
    if (value > high) return high;
    return value;
}

int main(void) {
    double exponential[HISTORY_SIZE] = {0.0};
    double logistic[HISTORY_SIZE] = {0.0};
    double delayed_feedback[HISTORY_SIZE] = {0.0};

    const double growth_rate = 0.080;
    const double carrying_capacity = 80.0;
    const double balancing_strength = 0.060;
    const double target = 55.0;
    const int delay = 7;
    const int shock_time = 90;
    const double shock_size = -8.0;

    exponential[0] = 10.0;
    logistic[0] = 10.0;
    delayed_feedback[0] = 10.0;

    printf("time,exponential,logistic,delayed_feedback,delayed_state,inflow,outflow,shock\n");

    for (int time = 0; time <= N_STEPS; ++time) {
        double current_exponential = exponential[time];
        double current_logistic = logistic[time];
        double current_delayed = delayed_feedback[time];

        int delayed_index = time - delay;
        if (delayed_index < 0) delayed_index = 0;

        double delayed_state = delayed_feedback[delayed_index];
        double inflow = growth_rate * current_delayed;
        double outflow = balancing_strength * fmax(delayed_state - target, 0.0);
        double shock = (time == shock_time) ? shock_size : 0.0;

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               time, current_exponential, current_logistic, current_delayed, delayed_state, inflow, outflow, shock);

        if (time + 1 < HISTORY_SIZE) {
            exponential[time + 1] = clamp(current_exponential + growth_rate * current_exponential, 0.0, 250.0);
            logistic[time + 1] = clamp(current_logistic + growth_rate * current_logistic * (1.0 - current_logistic / carrying_capacity), 0.0, 250.0);
            delayed_feedback[time + 1] = clamp(current_delayed + inflow - outflow + shock, 0.0, 250.0);
        }
    }

    return 0;
}
