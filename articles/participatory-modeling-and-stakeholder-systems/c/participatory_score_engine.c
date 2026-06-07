#include <math.h>
#include <stdio.h>

typedef struct {
    const char *name;
    double access;
    double cost;
    double resilience;
    double equity;
    double feasibility;
} Stakeholder;

typedef struct {
    const char *name;
    double access;
    double cost;
    double resilience;
    double equity;
    double feasibility;
} Scenario;

double score(Stakeholder stakeholder, Scenario scenario) {
    return stakeholder.access * scenario.access +
           stakeholder.cost * scenario.cost +
           stakeholder.resilience * scenario.resilience +
           stakeholder.equity * scenario.equity +
           stakeholder.feasibility * scenario.feasibility;
}

int main(void) {
    Stakeholder stakeholders[] = {
        {"community_residents", 0.30, 0.10, 0.20, 0.30, 0.10},
        {"frontline_staff", 0.20, 0.15, 0.25, 0.20, 0.20},
        {"technical_experts", 0.15, 0.20, 0.30, 0.15, 0.20},
        {"public_agency", 0.20, 0.25, 0.25, 0.15, 0.15},
        {"service_users", 0.35, 0.10, 0.15, 0.30, 0.10},
        {"resource_managers", 0.15, 0.20, 0.30, 0.15, 0.20}
    };

    Scenario scenarios[] = {
        {"targeted_service_expansion", 0.85, 0.55, 0.65, 0.90, 0.60},
        {"infrastructure_repair_priority", 0.55, 0.65, 0.85, 0.50, 0.75},
        {"digital_monitoring_platform", 0.60, 0.50, 0.70, 0.45, 0.70},
        {"community_led_resilience", 0.75, 0.70, 0.80, 0.85, 0.55},
        {"baseline_policy_continuation", 0.40, 0.90, 0.35, 0.30, 0.85}
    };

    int stakeholder_count = 6;
    int scenario_count = 5;

    printf("stakeholder_group,scenario,score\n");

    for (int i = 0; i < stakeholder_count; ++i) {
        for (int j = 0; j < scenario_count; ++j) {
            printf("%s,%s,%.6f\n", stakeholders[i].name, scenarios[j].name, score(stakeholders[i], scenarios[j]));
        }
    }

    return 0;
}
