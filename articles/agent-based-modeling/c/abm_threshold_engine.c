#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define N_AGENTS 180
#define N_STEPS 50
#define INITIAL_ADOPTERS 12
#define NEIGHBOR_RADIUS 2

static uint64_t state = 101;

static double lcg_rand(void) {
    state = state * 6364136223846793005ULL + 1ULL;
    return (double)(state >> 33) / (double)(1ULL << 31);
}

static double adoption_rate(bool adopted[]) {
    int count = 0;
    for (int i = 0; i < N_AGENTS; ++i) {
        if (adopted[i]) count++;
    }
    return (double)count / (double)N_AGENTS;
}

int main(void) {
    double thresholds[N_AGENTS];
    bool adopted[N_AGENTS] = {false};

    for (int i = 0; i < N_AGENTS; ++i) {
        thresholds[i] = 0.10 + lcg_rand() * (0.70 - 0.10);
    }

    for (int i = 0; i < INITIAL_ADOPTERS; ++i) {
        int idx = (int)(lcg_rand() * N_AGENTS) % N_AGENTS;
        adopted[idx] = true;
    }

    printf("time,adoption_rate,new_adopters,mean_threshold\n");

    double mean_threshold = 0.0;
    for (int i = 0; i < N_AGENTS; ++i) {
        mean_threshold += thresholds[i];
    }
    mean_threshold /= (double)N_AGENTS;

    for (int time = 1; time <= N_STEPS; ++time) {
        bool previous[N_AGENTS];
        for (int i = 0; i < N_AGENTS; ++i) {
            previous[i] = adopted[i];
        }

        for (int i = 0; i < N_AGENTS; ++i) {
            if (previous[i]) continue;

            int local_count = 0;
            int adopted_count = 0;

            for (int offset = 1; offset <= NEIGHBOR_RADIUS; ++offset) {
                int left = (i + N_AGENTS - offset) % N_AGENTS;
                int right = (i + offset) % N_AGENTS;

                local_count += 2;
                if (previous[left]) adopted_count++;
                if (previous[right]) adopted_count++;
            }

            double local_share = (double)adopted_count / (double)local_count;
            if (local_share >= thresholds[i]) {
                adopted[i] = true;
            }
        }

        int new_adopters = 0;
        for (int i = 0; i < N_AGENTS; ++i) {
            if (adopted[i] && !previous[i]) new_adopters++;
        }

        printf("%d,%.6f,%d,%.6f\n", time, adoption_rate(adopted), new_adopters, mean_threshold);
    }

    return 0;
}
