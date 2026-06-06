#include <math.h>
#include <stdio.h>

static double clamp_low(double value, double low) {
    return value < low ? low : value;
}

int main(void) {
    const int n_steps = 180;

    double stock_a = 24.0;
    double stock_b = 18.0;
    double pressure = 30.0;

    const double growth_a = 0.045;
    const double growth_b = 0.032;
    const double coupling_ab = 0.018;
    const double coupling_ba = 0.041;
    const double balancing_b = 0.026;
    const double target_b = 55.0;

    printf("time,stock_a,stock_b,pressure,total_state\n");

    for (int time = 1; time <= n_steps; ++time) {
        printf("%d,%.6f,%.6f,%.6f,%.6f\n", time, stock_a, stock_b, pressure, stock_a + stock_b);

        const double shock = (time == 75) ? -12.0 : 0.0;

        const double reinforcing_a = growth_a * stock_a;
        const double pressure_from_b = -coupling_ab * stock_b;
        const double reinforcing_b = growth_b * stock_b;
        const double support_from_a = coupling_ba * stock_a;
        const double correction_b = balancing_b * fmax(stock_b - target_b, 0.0);
        const double pressure_feedback =
            0.018 * fmax(stock_b - target_b, 0.0) +
            0.012 * fmax(stock_a - 70.0, 0.0);

        const double next_a = stock_a + reinforcing_a + pressure_from_b + shock - 0.018 * pressure;
        const double next_b = stock_b + reinforcing_b + support_from_a - correction_b - 0.010 * pressure;
        const double next_pressure = pressure + pressure_feedback - 0.045 * pressure;

        stock_a = clamp_low(next_a, 0.0);
        stock_b = clamp_low(next_b, 0.0);
        pressure = clamp_low(next_pressure, 0.0);
    }

    return 0;
}
