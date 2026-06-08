#include <stdio.h>

typedef struct {
    const char *scenario;
    double average_service;
    double minimum_service;
    int time_below_threshold;
    int threshold_crossings;
    double final_capacity;
    double final_degradation;
    int transformed;
    double resilience_score;
} ScenarioSummary;

int main(void) {
    ScenarioSummary summaries[] = {
        {"targeted_resilience_investment", 0.720000, 0.590000, 0, 0, 0.870000, 0.060000, 0, 0.699000},
        {"moderate_climate_stress", 0.690000, 0.560000, 0, 0, 0.720000, 0.080000, 0, 0.662000},
        {"transformation_pathway", 0.610000, 0.520000, 5, 2, 0.760000, 0.170000, 1, 0.476000},
        {"repeated_shocks", 0.590000, 0.480000, 9, 3, 0.610000, 0.160000, 0, 0.399000},
        {"delayed_adaptation", 0.550000, 0.430000, 14, 4, 0.600000, 0.210000, 0, 0.266500},
        {"compound_climate_stress", 0.490000, 0.360000, 24, 5, 0.500000, 0.300000, 0, 0.025000}
    };

    printf("scenario,average_service,minimum_service,time_below_threshold,threshold_crossings,final_adaptive_capacity,final_degradation,transformed,resilience_score\n");

    for (int i = 0; i < 6; ++i) {
        printf("%s,%.6f,%.6f,%d,%d,%.6f,%.6f,%d,%.6f\n",
               summaries[i].scenario,
               summaries[i].average_service,
               summaries[i].minimum_service,
               summaries[i].time_below_threshold,
               summaries[i].threshold_crossings,
               summaries[i].final_capacity,
               summaries[i].final_degradation,
               summaries[i].transformed,
               summaries[i].resilience_score);
    }

    return 0;
}
