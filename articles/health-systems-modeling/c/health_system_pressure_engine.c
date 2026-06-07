#include <math.h>
#include <stdio.h>

#define STEPS 120

double bounded(double value, double low, double high) {
    return fmax(low, fmin(high, value));
}

void simulate(
    const char *scenario,
    double capacity,
    double demand,
    double trust,
    double demand_growth,
    double prevention_effect,
    double workforce_recovery,
    double burnout_sensitivity,
    double attrition_sensitivity,
    double hiring_rate,
    double access_barrier,
    double trust_loss_rate,
    double trust_gain_rate,
    int surge_start,
    int surge_end,
    double surge_intensity
) {
    double initial_demand = demand;
    double backlog = 0.0;
    double burnout = 0.12;

    for (int time = 0; time < STEPS; ++time) {
        double pressure = demand / fmax(capacity, 1.0);
        double slack = fmax(1.0 - pressure, 0.0);
        burnout = fmax(0.0, burnout + burnout_sensitivity * fmax(pressure - 1.0, 0.0) - workforce_recovery * slack);
        double attrition = attrition_sensitivity * burnout * capacity;
        double surge = (time >= surge_start && time <= surge_end) ? surge_intensity : 0.0;
        double effective_capacity = fmax(0.0, capacity + hiring_rate - attrition - 0.10 * fmax(pressure - 1.0, 0.0) * capacity);
        double served = fmin(demand, effective_capacity);
        double unmet_need = fmax(demand - served, 0.0);
        double access_gap = access_barrier * demand + unmet_need;
        backlog = fmax(0.0, backlog + demand - served);
        trust = bounded(trust + trust_gain_rate * slack - trust_loss_rate * fmax(pressure - 1.0, 0.0) - 0.004 * access_gap / fmax(demand, 1.0), 0.0, 1.0);

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%d\n",
               scenario,
               time,
               demand,
               capacity,
               effective_capacity,
               pressure,
               slack,
               burnout,
               attrition,
               served,
               unmet_need,
               backlog,
               trust,
               surge > 0.0 ? 1 : 0);

        capacity = effective_capacity;
        double prevention_reduction = prevention_effect * (time + 1);
        demand = fmax(0.0, initial_demand + demand_growth * (time + 1) + surge - prevention_reduction + 0.08 * backlog);
    }
}

int main(void) {
    printf("scenario,time,demand,capacity,effective_capacity,pressure,slack,burnout,attrition,served,unmet_need,backlog,trust,surge_active\n");

    simulate("baseline_health_system", 100.0, 92.0, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18.0);
    simulate("higher_demand_growth", 100.0, 92.0, 0.64, 0.65, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 18.0);
    simulate("stronger_prevention", 100.0, 92.0, 0.70, 0.35, 0.060, 0.035, 0.085, 0.030, 0.50, 0.16, 0.018, 0.018, 45, 65, 18.0);
    simulate("larger_surge", 100.0, 92.0, 0.64, 0.35, 0.015, 0.035, 0.085, 0.030, 0.50, 0.18, 0.020, 0.012, 45, 65, 32.0);

    return 0;
}
