#include <math.h>
#include <stdio.h>

#define STEPS 100

void simulate(
    const char *scenario,
    double population,
    double housing,
    double transport,
    double service_capacity,
    double growth_pressure,
    double accessibility_attraction,
    double congestion_penalty,
    double housing_constraint_penalty,
    double housing_build_rate,
    double transport_investment_rate,
    double service_investment_rate
) {
    for (int step = 1; step <= STEPS; ++step) {
        double accessibility = transport / (1.0 + 0.010 * population);
        double congestion = population / fmax(transport, 1.0);
        double housing_gap = fmax(population - housing, 0.0);
        double service_pressure = population / fmax(service_capacity, 1.0);
        double policy_investment = (step % 20 == 0) ? 8.0 : 0.0;

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               step,
               population,
               housing,
               transport,
               service_capacity,
               accessibility,
               congestion,
               housing_gap,
               service_pressure,
               policy_investment);

        double population_change =
            growth_pressure +
            accessibility_attraction * accessibility / 55.0 -
            congestion_penalty * fmax(congestion - 1.0, 0.0) -
            housing_constraint_penalty * housing_gap / 20.0 -
            0.70 * fmax(service_pressure - 1.0, 0.0);

        population = fmax(0.0, population + population_change);
        housing = fmax(0.0, housing + housing_build_rate + 0.020 * population - 0.004 * housing);
        transport = fmax(1.0, transport + transport_investment_rate + 0.010 * housing - 0.030 * fmax(congestion - 1.0, 0.0));
        service_capacity = fmax(1.0, service_capacity + service_investment_rate + policy_investment - 0.003 * service_capacity);
    }
}

int main(void) {
    printf("scenario,time,population,housing,transport,service_capacity,accessibility,congestion,housing_gap,service_pressure,policy_investment\n");

    simulate("baseline_neighborhood", 100.0, 112.0, 90.0, 120.0, 1.10, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35);
    simulate("strong_growth_pressure", 100.0, 112.0, 90.0, 120.0, 1.65, 1.25, 0.70, 0.45, 0.65, 0.45, 0.35);
    simulate("housing_constraint", 100.0, 106.0, 90.0, 120.0, 1.10, 1.25, 0.70, 0.55, 0.25, 0.45, 0.35);
    simulate("transport_investment", 100.0, 112.0, 90.0, 120.0, 1.10, 1.25, 0.70, 0.45, 0.65, 1.15, 0.85);

    return 0;
}
