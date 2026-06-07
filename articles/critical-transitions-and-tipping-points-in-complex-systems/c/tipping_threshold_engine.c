#include <math.h>
#include <stdio.h>

double update_state(double x, double r, double dt) {
    return x + dt * (r + x - x * x * x);
}

double control_value(double start, double stop, int index, int count) {
    double step = (stop - start) / (double)(count - 1);
    return start + (double)index * step;
}

void simulate(const char *scenario, const char *path, double start_r, double end_r, int steps, double initial_state, double dt, double jump_threshold) {
    double x = initial_state;

    for (int index = 0; index < steps; ++index) {
        double r = control_value(start_r, end_r, index, steps);
        double previous_x = x;

        if (index > 0) {
            x = update_state(x, r, dt);
        }

        double jump_size = fabs(x - previous_x);
        int transition_flag = jump_size > jump_threshold ? 1 : 0;

        printf("%s,%s,%d,%.6f,%.6f,%.6f,%d\n",
               scenario,
               path,
               index + 1,
               r,
               x,
               jump_size,
               transition_flag);
    }
}

int main(void) {
    printf("scenario,path,step,control_parameter,system_state,jump_size,transition_flag\n");

    simulate("baseline_hysteresis", "forward_forcing", -1.20, 1.20, 300, -1.00, 0.050, 0.150);
    simulate("baseline_hysteresis", "backward_forcing", 1.20, -1.20, 300, 1.25, 0.050, 0.150);
    simulate("slow_forcing", "forward_forcing", -1.20, 1.20, 500, -1.00, 0.035, 0.120);
    simulate("fast_forcing", "forward_forcing", -1.20, 1.20, 150, -1.00, 0.075, 0.220);
    simulate("wide_forcing", "forward_forcing", -1.45, 1.45, 360, -1.10, 0.050, 0.150);

    return 0;
}
