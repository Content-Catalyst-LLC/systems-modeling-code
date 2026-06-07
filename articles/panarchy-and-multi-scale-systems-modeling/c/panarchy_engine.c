#include <math.h>
#include <stdio.h>

#define STEPS 160

const char *classify_phase(double fast_cycle, int release_event) {
    if (release_event == 1) return "release";
    if (fast_cycle < 0.8) return "reorganization";
    if (fast_cycle < 2.0) return "growth";
    return "conservation";
}

void simulate(const char *scenario, double fast_growth, double fast_capacity, double slow_constraint, double release_threshold, double release_magnitude, double revolt_strength, double remember_strength, double slow_adjustment, double slow_target) {
    double fast_cycle = 0.5;
    double slow_memory = 1.0;

    for (int time = 1; time <= STEPS; ++time) {
        int release_event = 0;

        if (time > 1) {
            fast_cycle = fast_cycle + fast_growth * fast_cycle * (1.0 - fast_cycle / fast_capacity) - slow_constraint * slow_memory;

            if (fast_cycle > release_threshold) {
                fast_cycle = fmax(0.0, fast_cycle - release_magnitude);
                slow_memory += revolt_strength;
                release_event = 1;
            } else {
                slow_memory = slow_memory + slow_adjustment * (slow_target - slow_memory);
            }

            fast_cycle = fmax(0.0, fast_cycle + remember_strength * slow_memory);
        }

        printf("%s,%d,%.6f,%.6f,%d,%s,%.6f\n",
               scenario,
               time,
               fast_cycle,
               slow_memory,
               release_event,
               classify_phase(fast_cycle, release_event),
               fast_cycle * slow_memory);
    }
}

int main(void) {
    printf("scenario,time,fast_cycle,slow_memory,release_event,phase,cross_scale_coupling\n");

    simulate("baseline_panarchy", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.035, 0.010, 1.60);
    simulate("strong_revolt", 0.16, 3.20, 0.08, 2.35, 1.35, 0.24, 0.035, 0.010, 1.60);
    simulate("strong_remember", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.065, 0.014, 1.60);
    simulate("rigid_slow_structure", 0.16, 3.20, 0.13, 2.50, 1.35, 0.14, 0.020, 0.004, 1.60);
    simulate("weak_memory_high_volatility", 0.17, 3.10, 0.06, 2.30, 1.45, 0.20, 0.015, 0.008, 1.45);

    return 0;
}
