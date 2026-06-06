#include <math.h>
#include <stdint.h>
#include <stdio.h>

#define N_ENTITIES 240

static uint64_t rng_state = 42;

static double lcg_rand(void) {
    rng_state = rng_state * 6364136223846793005ULL + 1ULL;
    return (double)(rng_state >> 33) / (double)(1ULL << 31);
}

static double exponential_time(double rate) {
    double draw = 1.0 - lcg_rand();
    if (draw < 1e-12) draw = 1e-12;
    return -log(draw) / rate;
}

int main(void) {
    const double arrival_rate = 0.18;
    const double service_rate = 0.22;

    double arrival_time[N_ENTITIES];
    double service_time[N_ENTITIES];
    double service_start[N_ENTITIES];
    double departure_time[N_ENTITIES];
    double waiting_time[N_ENTITIES];

    printf("entity,arrival_time,service_time,service_start,departure_time,waiting_time,time_in_system\n");

    for (int i = 0; i < N_ENTITIES; ++i) {
        if (i == 0) {
            arrival_time[i] = exponential_time(arrival_rate);
        } else {
            arrival_time[i] = arrival_time[i - 1] + exponential_time(arrival_rate);
        }

        service_time[i] = exponential_time(service_rate);
    }

    service_start[0] = arrival_time[0];
    departure_time[0] = service_start[0] + service_time[0];
    waiting_time[0] = 0.0;

    for (int i = 1; i < N_ENTITIES; ++i) {
        service_start[i] = fmax(arrival_time[i], departure_time[i - 1]);
        departure_time[i] = service_start[i] + service_time[i];
        waiting_time[i] = service_start[i] - arrival_time[i];
    }

    for (int i = 0; i < N_ENTITIES; ++i) {
        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               i + 1,
               arrival_time[i],
               service_time[i],
               service_start[i],
               departure_time[i],
               waiting_time[i],
               departure_time[i] - arrival_time[i]);
    }

    return 0;
}
