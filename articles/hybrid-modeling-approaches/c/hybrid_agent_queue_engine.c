#include <stdint.h>
#include <stdio.h>

#define N_AGENTS 160
#define N_STEPS 80

static uint64_t rng_state = 60606;

static double lcg_rand(void) {
    rng_state = rng_state * 6364136223846793005ULL + 1ULL;
    return (double)(rng_state >> 33) / (double)(1ULL << 31);
}

static double clamp(double value) {
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
}

int main(void) {
    const int service_capacity = 28;
    const double pressure_sensitivity = 0.18;
    const double baseline_low = 0.10;
    const double baseline_high = 0.42;

    double propensities[N_AGENTS];

    for (int i = 0; i < N_AGENTS; ++i) {
        propensities[i] = baseline_low + lcg_rand() * (baseline_high - baseline_low);
    }

    int queue_length = 0;

    printf("time,arrivals,served,queue_length,queue_pressure,utilization,mean_effective_propensity\n");

    for (int time = 0; time < N_STEPS; ++time) {
        double pressure = (double)queue_length / (double)service_capacity;
        int arrivals = 0;
        double total_effective = 0.0;

        for (int i = 0; i < N_AGENTS; ++i) {
            double effective = clamp(propensities[i] - pressure_sensitivity * pressure);
            total_effective += effective;
            if (lcg_rand() < effective) {
                arrivals++;
            }
        }

        int available_work = queue_length + arrivals;
        int served = available_work < service_capacity ? available_work : service_capacity;
        queue_length = available_work - served;

        printf("%d,%d,%d,%d,%.6f,%.6f,%.6f\n",
               time,
               arrivals,
               served,
               queue_length,
               pressure,
               (double)served / (double)service_capacity,
               total_effective / (double)N_AGENTS);
    }

    return 0;
}
