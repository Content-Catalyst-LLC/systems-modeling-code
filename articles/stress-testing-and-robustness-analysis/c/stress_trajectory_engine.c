#include <math.h>
#include <stdio.h>

#define STEPS 80

int main(void) {
    const double demand_growth = 0.025;
    const double initial_capacity = 100.0;
    const double capacity_loss = 35.0;
    const double recovery_rate = 0.12;
    const int shock_time = 32;
    const int stress_duration = 14;

    double demand = 55.0;
    double capacity = initial_capacity;

    printf("time,demand,capacity,unmet_demand,service_ratio,failed\n");

    for (int time = 1; time <= STEPS; ++time) {
        if (time > 1) {
            int stress_active = time >= shock_time && time < shock_time + stress_duration;

            demand *= (1.0 + demand_growth);

            if (time == shock_time) {
                capacity = fmax(0.0, capacity - capacity_loss);
            }

            if (!stress_active && capacity < initial_capacity) {
                capacity += recovery_rate * (initial_capacity - capacity);
            }

            capacity = fmax(0.0, capacity);
        }

        double unmet = fmax(0.0, demand - capacity);
        double service_ratio = demand <= 0.0 ? 1.0 : fmin(capacity / demand, 1.0);
        int failed = service_ratio < 0.85 ? 1 : 0;

        printf("%d,%.6f,%.6f,%.6f,%.6f,%d\n",
               time,
               demand,
               capacity,
               unmet,
               service_ratio,
               failed);
    }

    return 0;
}
