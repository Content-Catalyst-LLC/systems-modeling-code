#include <math.h>
#include <stdio.h>
#include <string.h>

#define STEPS 140

void simulate(const char *scenario, double collapse_threshold, double recovery_threshold, int intervention_time, double pressure_growth, double recovery_effort) {
    double system_state = 82.0;
    double pressure = 20.0;
    char regime[16] = "stable";

    for (int time = 1; time <= STEPS; ++time) {
        double damage_flow = 0.0;
        double recovery_flow = 0.0;
        double net_flow = 0.0;

        if (time > 1) {
            pressure += pressure_growth;

            if (time >= intervention_time) {
                pressure = fmax(0.0, pressure - recovery_effort);
            }

            if (strcmp(regime, "stable") == 0 && pressure >= collapse_threshold) {
                strcpy(regime, "degraded");
            } else if (strcmp(regime, "degraded") == 0 && pressure <= recovery_threshold) {
                strcpy(regime, "stable");
            }

            if (strcmp(regime, "stable") == 0) {
                damage_flow = 0.05 * pressure + 0.002 * pressure * pressure;
                recovery_flow = 2.6;
            } else {
                damage_flow = 0.09 * pressure + 0.006 * pressure * pressure + 1.8;
                recovery_flow = 0.8 + 0.03 * system_state;
            }

            net_flow = recovery_flow - damage_flow;
            system_state = fmin(100.0, fmax(0.0, system_state + net_flow));
        }

        printf("%s,%d,%.6f,%.6f,%s,%.6f,%.6f,%.6f\n",
               scenario,
               time,
               system_state,
               pressure,
               regime,
               damage_flow,
               recovery_flow,
               net_flow);
    }
}

int main(void) {
    printf("scenario,time,system_state,pressure,regime,damage_flow,recovery_flow,net_flow\n");

    simulate("early_intervention", 70.0, 45.0, 55, 0.85, 1.20);
    simulate("late_intervention", 70.0, 45.0, 85, 0.85, 1.20);
    simulate("strong_recovery", 70.0, 45.0, 85, 0.85, 2.00);
    simulate("lower_threshold_stress", 58.0, 38.0, 70, 0.95, 1.20);
    simulate("hysteresis_trap", 66.0, 30.0, 88, 0.90, 1.30);
    simulate("rapid_prevention", 70.0, 45.0, 40, 0.85, 1.80);

    return 0;
}
