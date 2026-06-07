#include <math.h>
#include <stdio.h>

double linear_value(double start, double stop, int index, int count) {
    double step = (stop - start) / (double)(count - 1);
    return start + (double)index * step;
}

int main(void) {
    int count = 301;

    printf("step,control_parameter,stable_state_positive,stable_state_negative,neutral_state,order_parameter_magnitude,phase_label\n");

    for (int index = 0; index < count; ++index) {
        double control = linear_value(-1.5, 1.5, index, count);
        double positive = 0.0;
        double negative = 0.0;
        double magnitude = 0.0;
        const char *label = "single neutral phase";

        if (control > 0.0) {
            positive = sqrt(control);
            negative = -sqrt(control);
            magnitude = positive;
            label = "two ordered phases";
        }

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%s\n",
               index + 1,
               control,
               positive,
               negative,
               0.0,
               magnitude,
               label);
    }

    return 0;
}
