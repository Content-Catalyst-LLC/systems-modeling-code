#include <stdio.h>

typedef struct {
    const char *result_id;
    const char *result_type;
    double lower_bound;
    double upper_bound;
    double assumption_disclosure;
    double uncertainty_disclosure;
    double boundary_disclosure;
    double misuse_warning;
} ModelResult;

double communication_quality(ModelResult r) {
    return 0.30 * r.assumption_disclosure +
           0.30 * r.uncertainty_disclosure +
           0.20 * r.boundary_disclosure +
           0.20 * r.misuse_warning;
}

const char *false_precision_label(ModelResult r) {
    double width = r.upper_bound - r.lower_bound;
    if (r.uncertainty_disclosure < 0.60 && width > 0.20) {
        return "high_false_precision_risk";
    }
    if (r.uncertainty_disclosure < 0.70) {
        return "moderate_false_precision_risk";
    }
    return "lower_false_precision_risk";
}

int main(void) {
    ModelResult results[] = {
        {"R1", "scenario", 0.55, 0.88, 0.80, 0.85, 0.70, 0.75},
        {"R2", "forecast", 9000.0, 16000.0, 0.60, 0.75, 0.55, 0.60},
        {"R3", "ranking", 0.75, 0.89, 0.70, 0.55, 0.65, 0.45},
        {"R4", "map", 0.40, 0.82, 0.45, 0.40, 0.50, 0.40},
        {"R5", "optimization", 0.80, 0.96, 0.65, 0.60, 0.60, 0.55},
        {"R6", "dashboard", 0.62, 0.86, 0.55, 0.50, 0.55, 0.35}
    };

    printf("result_id,result_type,uncertainty_width,communication_quality_score,false_precision_risk\n");

    for (int i = 0; i < 6; ++i) {
        double width = results[i].upper_bound - results[i].lower_bound;
        printf("%s,%s,%.6f,%.6f,%s\n",
               results[i].result_id,
               results[i].result_type,
               width,
               communication_quality(results[i]),
               false_precision_label(results[i]));
    }

    return 0;
}
