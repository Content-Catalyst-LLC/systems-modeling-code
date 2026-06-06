#include <stdio.h>

int main(void) {
    const int steps = 80;
    const double growth = 0.045;
    const double policy_drag = 0.012;
    const int shock_time = 42;
    const double shock_size = 22.0;
    const double resilience_investment = 8.0;

    double state = 20.0;
    double capacity_buffer = 5.0 + resilience_investment;
    double stress_index = state / capacity_buffer;

    printf("time,state,capacity_buffer,stress_index,growth,policy_drag,shock_size\n");

    for (int time = 1; time <= steps; ++time) {
        double shock_effect = 0.0;

        if (time == shock_time) {
            shock_effect = shock_size / capacity_buffer;
        }

        state = state + growth * state - policy_drag * state - shock_effect;
        if (state < 0.0) state = 0.0;

        capacity_buffer = capacity_buffer + 0.04 * resilience_investment;
        if (state > 40.0) {
            capacity_buffer = capacity_buffer - 0.01 * (state - 40.0);
        }
        if (capacity_buffer < 1.0) capacity_buffer = 1.0;

        stress_index = state / capacity_buffer;

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               time,
               state,
               capacity_buffer,
               stress_index,
               growth,
               policy_drag,
               shock_size);
    }

    return 0;
}
