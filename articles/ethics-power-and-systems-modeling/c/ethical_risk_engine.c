#include <stdio.h>

typedef struct {
    const char *risk_id;
    const char *risk_type;
    double uncertainty;
    double consequence;
    double representation_gap;
    double misuse_potential;
} ModelUseRisk;

double ethical_risk_score(ModelUseRisk risk) {
    return risk.uncertainty *
           risk.consequence *
           (1.0 + 0.50 * risk.representation_gap) *
           (1.0 + 0.50 * risk.misuse_potential);
}

int main(void) {
    ModelUseRisk risks[] = {
        {"R1", "boundary_power", 0.75, 0.85, 0.60, 0.70},
        {"R2", "data_power", 0.65, 0.80, 0.50, 0.65},
        {"R3", "proxy_bias", 0.70, 0.75, 0.70, 0.60},
        {"R4", "false_certainty", 0.60, 0.70, 0.45, 0.80},
        {"R5", "authority_transfer", 0.80, 0.90, 0.65, 0.85},
        {"R6", "optimization_narrowing", 0.70, 0.80, 0.55, 0.75},
        {"R7", "participation_tokenism", 0.75, 0.78, 0.80, 0.70},
        {"R8", "surveillance_asymmetry", 0.68, 0.82, 0.72, 0.78}
    };

    printf("risk_id,risk_type,uncertainty,consequence,representation_gap,misuse_potential,ethical_risk_score\n");

    for (int i = 0; i < 8; ++i) {
        printf("%s,%s,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               risks[i].risk_id,
               risks[i].risk_type,
               risks[i].uncertainty,
               risks[i].consequence,
               risks[i].representation_gap,
               risks[i].misuse_potential,
               ethical_risk_score(risks[i]));
    }

    return 0;
}
