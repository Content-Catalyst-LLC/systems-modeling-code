#include <math.h>
#include <stdio.h>

#define PERIODS 160
#define HISTORY_SIZE 200

static double clamp(double value, double low, double high) {
    if (value < low) return low;
    if (value > high) return high;
    return value;
}

int main(void) {
    double state[HISTORY_SIZE] = {0.0};

    const double growth_rate = 0.080;
    const double balancing_strength = 0.060;
    const double target = 50.0;
    const int delay = 7;
    const double threshold = 85.0;
    const double threshold_correction = 0.035;
    const int shock_time = 70;
    const double shock_size = -10.0;

    state[0] = 12.0;

    printf("time,state,delayed_state,inflow,balancing_outflow,threshold_penalty,shock,next_state\n");

    for (int time = 0; time <= PERIODS; ++time) {
        double current = state[time];
        int delayed_index = time - delay;
        if (delayed_index < 0) delayed_index = 0;

        double delayed_state = state[delayed_index];
        double inflow = growth_rate * current;
        double balancing_outflow = balancing_strength * fmax(delayed_state - target, 0.0);

        double threshold_penalty = 0.0;
        if (current >= threshold) {
            threshold_penalty = threshold_correction * (current - threshold);
        }

        double shock = (time == shock_time) ? shock_size : 0.0;
        double next_state = clamp(current + inflow - balancing_outflow - threshold_penalty + shock, 0.0, 250.0);

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               time, current, delayed_state, inflow, balancing_outflow, threshold_penalty, shock, next_state);

        if (time + 1 < HISTORY_SIZE) {
            state[time + 1] = next_state;
        }
    }

    return 0;
}
