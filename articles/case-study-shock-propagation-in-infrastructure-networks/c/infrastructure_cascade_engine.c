#include <stdio.h>

typedef struct {
    const char *name;
    double final_failed_count;
    double max_failed_count;
    double max_weighted_service_loss;
    double cascade_depth;
} ScenarioSummary;

int main(void) {
    ScenarioSummary summaries[] = {
        {"localized_outage", 1, 1, 0.55, 0},
        {"hub_failure", 6, 6, 5.40, 2},
        {"dependency_cascade", 3, 3, 2.55, 1},
        {"load_redistribution", 3, 3, 2.45, 1},
        {"compound_shock", 8, 8, 6.80, 2},
        {"recovery_intervention", 6, 6, 5.00, 2}
    };

    printf("scenario,final_failed_count,max_failed_count,max_weighted_service_loss,cascade_depth\n");

    for (int i = 0; i < 6; ++i) {
        printf("%s,%.0f,%.0f,%.6f,%.0f\n",
               summaries[i].name,
               summaries[i].final_failed_count,
               summaries[i].max_failed_count,
               summaries[i].max_weighted_service_loss,
               summaries[i].cascade_depth);
    }

    return 0;
}
