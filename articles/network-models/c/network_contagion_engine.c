#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define N 48
#define STEPS 24
#define MAX_EDGES 64

static uint64_t rng_state = 80808;

static double lcg_rand(void) {
    rng_state = rng_state * 6364136223846793005ULL + 1ULL;
    return (double)(rng_state >> 33) / (double)(1ULL << 31);
}

int main(void) {
    int A[N][N] = {0};
    int edges[][2] = {
        {0,1},{0,2},{1,3},{2,3},{2,4},{3,5},{4,6},{5,7},
        {6,8},{7,9},{8,10},{9,11},{10,12},{11,13},{12,14},{13,15},
        {16,17},{16,18},{17,19},{18,19},{18,20},{19,21},{20,22},{21,23},
        {22,24},{23,25},{24,26},{25,27},{26,28},{27,29},{28,30},{29,31},
        {32,33},{32,34},{33,35},{34,35},{34,36},{35,37},{36,38},{37,39},
        {38,40},{39,41},{40,42},{41,43},{42,44},{43,45},{44,46},{45,47},
        {3,19},{7,25},{21,35},{29,42},{12,37},{2,18},{18,34},{2,34}
    };

    int edge_count = sizeof(edges) / sizeof(edges[0]);

    for (int e = 0; e < edge_count; ++e) {
        int a = edges[e][0];
        int b = edges[e][1];
        A[a][b] = 1;
        A[b][a] = 1;
    }

    bool infected[N] = {false};
    infected[2] = true;

    double probability = 0.18;

    printf("step,infected_count,infected_share,probability\n");

    for (int step = 0; step <= STEPS; ++step) {
        int infected_count = 0;
        for (int i = 0; i < N; ++i) {
            if (infected[i]) infected_count++;
        }

        printf("%d,%d,%.6f,%.6f\n", step, infected_count, (double)infected_count / (double)N, probability);

        bool next_infected[N];
        for (int i = 0; i < N; ++i) {
            next_infected[i] = infected[i];
        }

        for (int i = 0; i < N; ++i) {
            if (!infected[i]) continue;

            for (int j = 0; j < N; ++j) {
                if (A[i][j] == 1 && !infected[j] && lcg_rand() < probability) {
                    next_infected[j] = true;
                }
            }
        }

        for (int i = 0; i < N; ++i) {
            infected[i] = next_infected[i];
        }
    }

    return 0;
}
