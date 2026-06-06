#include <math.h>
#include <stdio.h>

#define N_STEPS 80
#define TRAIN_CUTOFF 52

int main(void) {
    const double growth_rate = 0.095;
    const double carrying_capacity = 120.0;
    double state[N_STEPS];

    state[0] = 10.0;

    for (int i = 1; i < N_STEPS; ++i) {
        double previous = state[i - 1];
        double next_value = previous + growth_rate * previous * (1.0 - previous / carrying_capacity);
        state[i] = fmax(0.0, next_value);
    }

    printf("time,dataset,state,growth_rate,carrying_capacity\n");

    for (int i = 0; i < N_STEPS; ++i) {
        const char *dataset = (i + 1 <= TRAIN_CUTOFF) ? "calibration" : "validation";
        printf("%d,%s,%.6f,%.6f,%.6f\n", i + 1, dataset, state[i], growth_rate, carrying_capacity);
    }

    return 0;
}
