#include <math.h>
#include <stdio.h>

#define STEPS 80

void simulate(
    const char *scenario,
    int shock_start,
    int shock_end,
    double power_loss_rate,
    double power_recovery_rate,
    double communications_dependency,
    double water_power_dependency,
    double water_comms_dependency,
    double transport_power_dependency,
    double transport_comms_dependency
) {
    double power = 1.0;
    double communications = 1.0;
    double water = 1.0;
    double transport = 1.0;

    for (int time = 0; time < STEPS; ++time) {
        if (time >= shock_start && time <= shock_end) {
            power = fmax(0.45, power - power_loss_rate);
        } else if (time > shock_end) {
            power = fmin(1.0, power + power_recovery_rate);
        } else {
            power = 1.0;
        }

        communications = fmax(
            0.40,
            communications_dependency * power +
            (1.0 - communications_dependency) * communications
        );

        water = fmax(
            0.35,
            water_power_dependency * power +
            water_comms_dependency * communications +
            (1.0 - water_power_dependency - water_comms_dependency) * water
        );

        transport = fmax(
            0.35,
            transport_power_dependency * power +
            transport_comms_dependency * communications +
            (1.0 - transport_power_dependency - transport_comms_dependency) * transport
        );

        double composite_service = (power + communications + water + transport) / 4.0;
        double unmet_service = 1.0 - composite_service;

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%d\n",
               scenario,
               time,
               power,
               communications,
               water,
               transport,
               composite_service,
               unmet_service,
               (time >= shock_start && time <= shock_end) ? 1 : 0);
    }
}

int main(void) {
    printf("scenario,time,power,communications,water,transport,composite_service,unmet_service,shock_active\n");

    simulate("baseline_cascade", 20, 36, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25);
    simulate("larger_power_loss", 20, 36, 0.055, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25);
    simulate("faster_recovery", 20, 36, 0.035, 0.045, 0.72, 0.55, 0.25, 0.30, 0.25);
    simulate("longer_shock", 20, 48, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25);

    return 0;
}
