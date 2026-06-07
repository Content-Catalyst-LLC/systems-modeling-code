#include <math.h>
#include <stdio.h>

#define STEPS 100

double bounded(double value, double low, double high) {
    return fmax(low, fmin(high, value));
}

void simulate(
    const char *scenario,
    double capacity,
    double workload,
    double trust,
    double demand_growth,
    double hiring_rate,
    double learning_rate,
    double burnout_sensitivity,
    double recovery_rate,
    double attrition_sensitivity,
    double coordination_burden_rate,
    double trust_loss_rate,
    double trust_gain_rate
) {
    double initial_workload = workload;
    double backlog = 0.0;
    double burnout = 0.10;

    for (int time = 0; time < STEPS; ++time) {
        double pressure = workload / fmax(capacity, 1.0);
        double slack = fmax(1.0 - pressure, 0.0);
        double learning = learning_rate * capacity * slack * trust;
        double coordination_burden = coordination_burden_rate * fmax(pressure - 1.0, 0.0) * capacity;

        burnout = fmax(0.0, burnout + burnout_sensitivity * fmax(pressure - 1.0, 0.0) - recovery_rate * slack);
        double attrition = attrition_sensitivity * burnout * capacity;
        double effective_capacity = fmax(0.0, capacity + hiring_rate + learning - attrition - coordination_burden);
        double delivery = fmin(workload, effective_capacity);
        backlog = fmax(0.0, backlog + workload - delivery);
        trust = bounded(trust + trust_gain_rate * slack - trust_loss_rate * fmax(pressure - 1.0, 0.0) - 0.005 * burnout, 0.0, 1.0);

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               time,
               capacity,
               workload,
               pressure,
               slack,
               learning,
               coordination_burden,
               burnout,
               attrition,
               trust,
               backlog);

        capacity = effective_capacity;
        workload = initial_workload + demand_growth * (time + 1) + 0.10 * backlog;
    }
}

int main(void) {
    printf("scenario,time,capacity,workload,pressure,slack,learning,coordination_burden,burnout,attrition,trust,backlog\n");

    simulate("baseline_organization", 100.0, 95.0, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010);
    simulate("high_demand_growth", 100.0, 95.0, 0.62, 0.85, 0.65, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010);
    simulate("faster_hiring", 100.0, 95.0, 0.62, 0.45, 1.25, 0.035, 0.090, 0.040, 0.035, 0.10, 0.030, 0.010);
    simulate("high_coordination_burden", 100.0, 95.0, 0.62, 0.45, 0.65, 0.035, 0.090, 0.040, 0.035, 0.22, 0.030, 0.010);

    return 0;
}
