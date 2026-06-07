#include <math.h>
#include <stdio.h>

#define STEPS 100

void simulate(const char *scenario, int delay, double correction_strength, double counterresponse_strength, double perception_smoothing) {
    double target = 50.0;
    double state[STEPS];
    double perceived[STEPS];
    double intervention[STEPS];
    double counterresponse[STEPS];

    state[0] = 80.0;
    perceived[0] = 80.0;
    intervention[0] = 0.0;
    counterresponse[0] = 0.0;

    for (int t = 1; t < STEPS; ++t) {
        perceived[t] = perception_smoothing * state[t - 1] + (1.0 - perception_smoothing) * perceived[t - 1];

        int observed_index = t - delay;
        if (observed_index < 0) {
            observed_index = 0;
        }

        double observed_gap = perceived[observed_index] - target;
        double action = correction_strength * fmax(0.0, observed_gap);
        double response = counterresponse_strength * action;
        double natural_pressure = 2.0 + 0.025 * state[t - 1];

        intervention[t] = action;
        counterresponse[t] = response;
        state[t] = fmax(0.0, state[t - 1] + natural_pressure + response - action);
    }

    for (int t = 0; t < STEPS; ++t) {
        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               t + 1,
               state[t],
               perceived[t],
               target,
               intervention[t],
               counterresponse[t]);
    }
}

int main(void) {
    printf("scenario,time,state,perceived_state,target,intervention,counterresponse\n");

    simulate("timely_moderate_response", 1, 0.18, 0.00, 0.75);
    simulate("delayed_response", 6, 0.18, 0.00, 0.55);
    simulate("overcorrection", 6, 0.34, 0.00, 0.55);
    simulate("policy_resistance", 6, 0.24, 0.42, 0.55);
    simulate("slow_recognition_high_resistance", 10, 0.24, 0.55, 0.35);

    return 0;
}
