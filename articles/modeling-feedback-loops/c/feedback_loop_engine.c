#include <math.h>
#include <stdio.h>

#define STEPS 90

int main(void) {
    double reinforcing = 2.0;
    double balancing = 2.0;
    double logistic = 2.0;
    double delayed[STEPS];

    const double target = 20.0;
    const double reinforcing_rate = 0.10;
    const double correction = 0.15;
    const double logistic_rate = 0.12;
    const double capacity = 25.0;
    const int delay = 5;

    delayed[0] = 5.0;

    printf("time,reinforcing,balancing,logistic,delayed_balancing\n");

    for (int time = 1; time <= STEPS; ++time) {
        if (time > 1) {
            reinforcing = (1.0 + reinforcing_rate) * reinforcing;
            balancing = balancing + correction * (target - balancing);
            logistic = logistic + logistic_rate * logistic * (1.0 - logistic / capacity);

            int delayed_index = (time - 1) - delay;
            if (delayed_index < 0) {
                delayed_index = 0;
            }

            delayed[time - 1] = delayed[time - 2] + 0.28 * (target - delayed[delayed_index]);
        }

        printf("%d,%.6f,%.6f,%.6f,%.6f\n",
               time,
               reinforcing,
               balancing,
               logistic,
               delayed[time - 1]);
    }

    return 0;
}
