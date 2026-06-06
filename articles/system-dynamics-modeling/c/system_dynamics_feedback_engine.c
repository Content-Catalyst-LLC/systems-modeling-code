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
    double stock[HISTORY_SIZE] = {0.0};

    const double growth_rate = 0.090;
    const double balancing_strength = 0.055;
    const double target = 62.0;
    const int delay = 7;
    const double capacity = 100.0;
    const double threshold = 82.0;
    const double threshold_correction = 0.040;
    const int shock_time = 95;
    const double shock_size = -10.0;

    stock[0] = 20.0;

    printf("time,stock,delayed_stock,inflow,outflow,threshold_penalty,shock,next_stock\n");

    for (int time = 0; time <= PERIODS; ++time) {
        double current = stock[time];
        int delayed_index = time - delay;
        if (delayed_index < 0) delayed_index = 0;

        double delayed_stock = stock[delayed_index];
        double inflow = growth_rate * current * (1.0 - current / capacity);
        double outflow = balancing_strength * fmax(delayed_stock - target, 0.0);

        double threshold_penalty = 0.0;
        if (current >= threshold) {
            threshold_penalty = threshold_correction * (current - threshold);
        }

        double shock = (time == shock_time) ? shock_size : 0.0;
        double next_stock = clamp(current + inflow - outflow - threshold_penalty + shock, 0.0, 250.0);

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               time, current, delayed_stock, inflow, outflow, threshold_penalty, shock, next_stock);

        if (time + 1 < HISTORY_SIZE) {
            stock[time + 1] = next_stock;
        }
    }

    return 0;
}
