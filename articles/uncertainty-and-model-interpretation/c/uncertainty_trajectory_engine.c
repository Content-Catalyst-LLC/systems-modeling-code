#include <math.h>
#include <stdio.h>

int main(void) {
    const int steps = 80;
    const double growth_rate = 0.075;
    const double carrying_capacity = 115.0;
    const double extraction_pressure = 0.020;
    const double shock_intensity = 14.0;
    const int shock_time = 42;

    double state = 10.0;

    printf("time,state,growth_rate,carrying_capacity,extraction_pressure,shock_intensity,shock_time\n");

    for (int time = 1; time <= steps; ++time) {
        if (time > 1) {
            double shock_effect = (time == shock_time) ? shock_intensity : 0.0;
            state = state +
                growth_rate * state * (1.0 - state / carrying_capacity) -
                extraction_pressure * state -
                shock_effect;
            state = fmax(0.0, state);
        }

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%d\n",
               time,
               state,
               growth_rate,
               carrying_capacity,
               extraction_pressure,
               shock_intensity,
               shock_time);
    }

    return 0;
}
