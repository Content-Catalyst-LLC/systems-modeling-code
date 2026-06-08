#include <stdio.h>

typedef struct {
    const char *policy;
    double average_score;
    double worst_case_score;
    double best_case_score;
    double maximum_regret;
    double acceptable_share;
    double robustness_score;
} PolicySummary;

int main(void) {
    PolicySummary summaries[] = {
        {"adaptive_pathway", 0.617, 0.557, 0.684, 0.000, 1.000, 0.591},
        {"targeted_intervention", 0.550, 0.493, 0.622, 0.093, 0.833, 0.502},
        {"universal_program", 0.545, 0.473, 0.628, 0.112, 0.667, 0.485},
        {"status_quo_maintenance", 0.380, 0.338, 0.423, 0.275, 0.000, 0.292}
    };

    printf("policy,average_score,worst_case_score,best_case_score,maximum_regret,acceptable_scenario_share,robustness_score\n");

    for (int i = 0; i < 4; ++i) {
        printf("%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               summaries[i].policy,
               summaries[i].average_score,
               summaries[i].worst_case_score,
               summaries[i].best_case_score,
               summaries[i].maximum_regret,
               summaries[i].acceptable_share,
               summaries[i].robustness_score);
    }

    return 0;
}
