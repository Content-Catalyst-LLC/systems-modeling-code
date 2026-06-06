#include <math.h>
#include <stdio.h>

#define STEPS 96

void simulate(const char *scenario, double feedback_gain, double external_correction, double rule_threshold, double rule_feedback_gain, int has_rule, double goal_weight) {
    double state = 70.0;
    double pressure = 50.0;
    double resilience = 30.0;
    double intervention = 0.0;

    for (int time = 1; time <= STEPS; ++time) {
        printf("%s,%d,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               time,
               state,
               pressure,
               resilience,
               intervention);

        double current_gain = feedback_gain;
        if (has_rule && state > rule_threshold) {
            current_gain = rule_feedback_gain;
        }

        double resilience_gap = fmax(0.0, 100.0 - resilience);
        double resilience_investment = goal_weight * resilience_gap;
        intervention = external_correction + 0.05 * fmax(0.0, state - 40.0) + resilience_investment;

        double next_pressure = fmax(0.0, 0.91 * pressure + 0.07 * state - 0.30 * intervention - 0.04 * resilience);
        double next_resilience = fmin(100.0, fmax(0.0, resilience + 0.18 * resilience_investment - 0.025 * pressure));
        double next_state = fmax(0.0, current_gain * state + 0.24 * next_pressure - 0.34 * intervention - 0.045 * next_resilience);

        pressure = next_pressure;
        resilience = next_resilience;
        state = next_state;
    }
}

int main(void) {
    printf("scenario,time,state,pressure,resilience,intervention\n");
    simulate("baseline", 0.96, 2.0, 0.0, 0.96, 0, 0.00);
    simulate("parameter_intervention", 0.96, 5.0, 0.0, 0.96, 0, 0.00);
    simulate("feedback_intervention", 0.78, 2.0, 0.0, 0.78, 0, 0.00);
    simulate("rule_intervention", 0.96, 2.0, 45.0, 0.70, 1, 0.00);
    simulate("goal_intervention", 0.90, 2.0, 45.0, 0.72, 1, 0.10);

    return 0;
}
