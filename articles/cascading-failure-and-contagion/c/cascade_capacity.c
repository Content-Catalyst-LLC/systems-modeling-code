#include <stdio.h>

int main(void) {
    const char *sectors[] = {"energy", "water", "telecom", "health"};
    double capacity[] = {100.0, 85.0, 90.0, 95.0};
    double load[] = {62.0, 70.0, 58.0, 82.0};
    double threshold[] = {0.75, 0.70, 0.72, 0.78};

    printf("Cascade capacity diagnostics\n");

    for (int i = 0; i < 4; i++) {
        double load_ratio = load[i] / capacity[i];
        const char *status = load_ratio >= threshold[i] ? "failure risk" : "within threshold";
        printf("%s load_ratio=%.3f threshold=%.3f status=%s\n", sectors[i], load_ratio, threshold[i], status);
    }

    return 0;
}
