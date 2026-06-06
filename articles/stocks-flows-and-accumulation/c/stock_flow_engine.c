#include <math.h>
#include <stdio.h>

#define STEPS 120

void simulate(const char *scenario, double arrival_multiplier, double completion_shift, double extraction_before, double extraction_after, int resource_policy_time, double maintenance_before, double maintenance_after, int maintenance_policy_time) {
    double backlog = 80.0;
    double resource = 600.0;
    double condition = 72.0;

    for (int time = 1; time <= STEPS; ++time) {
        double arrivals = 18.0 * arrival_multiplier;

        if ((time >= 50) && (arrival_multiplier < 1.0)) {
            arrivals = 18.0 * 0.72 * arrival_multiplier;
        }

        double extraction = (time >= resource_policy_time) ? extraction_after : extraction_before;
        double maintenance = (time >= maintenance_policy_time) ? maintenance_after : maintenance_before;

        double completions = fmin(backlog + arrivals, 12.0 + completion_shift + 0.08 * backlog);
        double backlog_net = arrivals - completions;
        backlog = fmax(0.0, backlog + backlog_net);

        double regeneration = 0.045 * resource * (1.0 - resource / 1000.0);
        double resource_net = regeneration - extraction;
        resource = fmax(0.0, resource + resource_net);

        double wear = 1.4 + 0.012 * fmax(0.0, 100.0 - condition);
        double condition_net = maintenance - wear;
        condition = fmin(100.0, fmax(0.0, condition + condition_net));

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               time,
               backlog,
               resource,
               condition,
               backlog_net,
               resource_net,
               condition_net);
    }
}

int main(void) {
    printf("scenario,time,backlog,resource,infrastructure_condition,backlog_net_flow,resource_net_flow,condition_net_flow\n");

    simulate("baseline", 1.00, 0.0, 24.0, 24.0, 999, 0.9, 0.9, 999);
    simulate("capacity_and_conservation", 0.85, 2.0, 22.0, 12.0, 70, 1.2, 2.8, 60);
    simulate("delayed_response", 1.00, 1.5, 24.0, 12.0, 85, 0.9, 2.8, 85);
    simulate("adaptive_recovery", 0.90, 3.0, 22.0, 10.0, 55, 1.4, 3.4, 50);

    return 0;
}
