#include <math.h>
#include <stdio.h>

#define STEPS 120

int main(void) {
    const double r = 3.9;
    double trajectory_1 = 0.4000;
    double trajectory_2 = 0.4001;

    printf("time,trajectory_1,trajectory_2,absolute_difference\n");

    for (int time = 1; time <= STEPS; ++time) {
        if (time > 1) {
            trajectory_1 = r * trajectory_1 * (1.0 - trajectory_1);
            trajectory_2 = r * trajectory_2 * (1.0 - trajectory_2);
        }

        printf("%d,%.8f,%.8f,%.8f\n",
               time,
               trajectory_1,
               trajectory_2,
               fabs(trajectory_1 - trajectory_2));
    }

    return 0;
}
