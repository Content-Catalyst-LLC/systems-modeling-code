#include <stdio.h>

const char *risk_label(double score) {
    if (score >= 0.45) {
        return "high";
    }
    if (score >= 0.25) {
        return "moderate";
    }
    return "lower";
}

int main(void) {
    const char *ids[] = {"A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9"};
    const char *categories[] = {"boundary", "data", "parameter", "behavioral", "scenario", "normative", "scale", "causal", "measurement"};
    double uncertainty[] = {0.80, 0.55, 0.40, 0.70, 0.65, 0.75, 0.50, 0.45, 0.70};
    double sensitivity[] = {0.75, 0.60, 0.85, 0.50, 0.80, 0.90, 0.65, 0.80, 0.70};
    double consequence[] = {0.90, 0.70, 0.65, 0.60, 0.85, 0.95, 0.75, 0.80, 0.85};

    printf("assumption_id,category,uncertainty,sensitivity,consequence,risk_score,risk_label\n");

    for (int i = 0; i < 9; ++i) {
        double score = uncertainty[i] * sensitivity[i] * consequence[i];
        printf("%s,%s,%.6f,%.6f,%.6f,%.6f,%s\n",
               ids[i],
               categories[i],
               uncertainty[i],
               sensitivity[i],
               consequence[i],
               score,
               risk_label(score));
    }

    return 0;
}
