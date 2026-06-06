#include <math.h>
#include <stdio.h>

int main(void) {
    const int steps = 80;
    const double growth_rate = 0.08;
    const double carrying_capacity = 100.0;
    const double extraction_pressure = 0.025;
    const int recovery_delay = 5;
    const double feedback_strength = 0.020;
    const double shock_intensity = 8.0;
    const int shock_time = steps / 2;

    double state[80];
    state[0] = 10.0;

    printf("time,state,growth_rate,carrying_capacity,extraction_pressure,recovery_delay,feedback_strength,shock_intensity\n");

    for (int time = 1; time < steps; ++time) {
        int delayed_index = time - recovery_delay;
        if (delayed_index < 0) delayed_index = 0;

        double delayed_recovery = feedback_strength * state[delayed_index];
        double shock_effect = (time == shock_time) ? shock_intensity : 0.0;
        double previous = state[time - 1];

        double next_state =
            previous +
            growth_rate * previous * (1.0 - previous / carrying_capacity) -
            extraction_pressure * previous +
            delayed_recovery -
            shock_effect;

        state[time] = fmax(0.0, next_state);
    }

    for (int time = 0; time < steps; ++time) {
        printf("%d,%.6f,%.6f,%.6f,%.6f,%d,%.6f,%.6f\n",
               time + 1,
               state[time],
               growth_rate,
               carrying_capacity,
               extraction_pressure,
               recovery_delay,
               feedback_strength,
               shock_intensity);
    }

    return 0;
}
