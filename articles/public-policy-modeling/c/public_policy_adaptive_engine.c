#include <math.h>
#include <stdio.h>

#define STEPS 100

double bounded(double value, double low, double high) {
    return fmax(low, fmin(high, value));
}

void simulate(
    const char *scenario,
    double target_state,
    double system_state,
    double capacity,
    double trust,
    double burden,
    double policy,
    double max_policy,
    double min_policy,
    double policy_increase_rate,
    double policy_decrease_rate,
    double policy_effect,
    double capacity_learning_rate,
    double burden_growth,
    double burden_relief,
    double side_effect_rate
) {
    double side_effect = 0.0;

    for (int time = 0; time < STEPS; ++time) {
        double uptake = bounded(
            0.42 + 0.30 * trust + 0.035 * capacity - 0.45 * burden,
            0.0,
            1.0
        );

        double performance_gap = target_state - system_state;

        if (performance_gap > 0.0) {
            policy = fmin(max_policy, policy + policy_increase_rate);
        } else {
            policy = fmax(min_policy, policy - policy_decrease_rate);
        }

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               time,
               system_state,
               performance_gap,
               policy,
               capacity,
               trust,
               burden,
               uptake,
               side_effect);

        double next_state =
            system_state +
            policy_effect * policy * uptake -
            0.12 * system_state +
            0.05 * capacity;

        double next_capacity = capacity + capacity_learning_rate * (system_state - capacity);
        double next_burden = fmax(0.0, burden + burden_growth * policy - burden_relief * capacity);
        double next_side_effect = fmax(0.0, side_effect + side_effect_rate * policy - 0.06 * side_effect);
        double next_trust = bounded(trust + 0.015 * uptake - 0.018 * next_burden - 0.010 * next_side_effect, 0.0, 1.0);

        system_state = fmax(0.0, next_state);
        capacity = fmax(0.0, next_capacity);
        burden = next_burden;
        side_effect = next_side_effect;
        trust = next_trust;
    }
}

int main(void) {
    printf("scenario,time,system_state,performance_gap,policy_intensity,institutional_capacity,trust,administrative_burden,uptake,side_effect\n");

    simulate("baseline_adaptive_policy", 16.0, 12.0, 7.0, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08);
    simulate("aggressive_policy_rule", 16.0, 12.0, 7.0, 0.58, 0.25, 1.0, 2.4, 0.25, 0.14, 0.05, 0.55, 0.09, 0.05, 0.025, 0.08);
    simulate("high_burden_design", 16.0, 12.0, 7.0, 0.58, 0.25, 1.0, 2.0, 0.25, 0.08, 0.05, 0.55, 0.09, 0.10, 0.025, 0.08);
    simulate("capacity_first_policy", 16.0, 12.0, 9.0, 0.64, 0.20, 0.8, 1.8, 0.25, 0.06, 0.05, 0.50, 0.13, 0.030, 0.035, 0.055);

    return 0;
}
