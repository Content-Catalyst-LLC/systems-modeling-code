#include <math.h>
#include <stdio.h>

#define STEPS 320
#define WINDOW 25

double linear_value(double start, double stop, int index, int count) {
    double step = (stop - start) / (double)(count - 1);
    return start + (double)index * step;
}

double deterministic_noise(int index, double scale) {
    return sin((double)index * 1.61803398875) * scale;
}

double rolling_variance(double values[], int start_index, int window) {
    double total = 0.0;
    double mean_value = 0.0;
    double ss = 0.0;

    for (int i = start_index; i < start_index + window; ++i) {
        total += values[i];
    }

    mean_value = total / (double)window;

    for (int i = start_index; i < start_index + window; ++i) {
        double delta = values[i] - mean_value;
        ss += delta * delta;
    }

    return ss / (double)(window - 1);
}

void simulate(const char *scenario, double stability_start, double stability_end, double noise_sd) {
    double state_values[STEPS];
    double state = 0.0;

    for (int index = 0; index < STEPS; ++index) {
        double stability = linear_value(stability_start, stability_end, index, STEPS);

        if (index > 0) {
            state = stability * state + deterministic_noise(index, noise_sd);
        }

        state_values[index] = state;

        double roll_var = -1.0;
        if (index + 1 >= WINDOW) {
            roll_var = rolling_variance(state_values, index + 1 - WINDOW, WINDOW);
        }

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               index + 1,
               state,
               fabs(state),
               stability,
               roll_var);
    }
}

int main(void) {
    printf("scenario,time,state,absolute_state,stability,rolling_variance\n");

    simulate("baseline_destabilization", 0.55, 0.985, 1.00);
    simulate("moderate_destabilization", 0.45, 0.900, 1.00);
    simulate("high_noise_destabilization", 0.55, 0.985, 1.40);
    simulate("low_noise_destabilization", 0.55, 0.985, 0.65);

    return 0;
}
