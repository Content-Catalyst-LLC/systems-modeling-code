#include <math.h>
#include <stdio.h>

#define STEPS 90

double next_logistic(double previous, double growth, double capacity) {
    return fmax(0.0, previous + growth * previous * (1.0 - previous / capacity));
}

double next_managed(double previous, double growth, double capacity, double extraction) {
    return fmax(0.0, previous + growth * previous * (1.0 - previous / capacity) - extraction * previous);
}

int main(void) {
    double logistic = 12.0;
    double managed = 12.0;
    double exponential = 12.0;

    printf("time,exponential,logistic,managed_logistic\n");

    for (int time = 1; time <= STEPS; ++time) {
        if (time > 1) {
            exponential = fmax(0.0, exponential + 0.060 * exponential);
            logistic = next_logistic(logistic, 0.085, 130.0);
            managed = next_managed(managed, 0.085, 130.0, 0.012);
        }

        printf("%d,%.6f,%.6f,%.6f\n", time, exponential, logistic, managed);
    }

    return 0;
}
