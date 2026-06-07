#include <math.h>
#include <stdio.h>

double distance_value(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x1 - x2, 2.0) + pow(y1 - y2, 2.0));
}

double service_access(double x, double y, double capacity_multiplier, int service_shift) {
    double services[4][3] = {
        {5.0 + service_shift, 6.0, 900.0 * capacity_multiplier},
        {9.0, 20.0 - service_shift, 650.0 * capacity_multiplier},
        {18.0 - service_shift, 10.0 + service_shift, 800.0 * capacity_multiplier},
        {22.0, 21.0, 500.0 * capacity_multiplier}
    };

    double access = 0.0;

    for (int i = 0; i < 4; ++i) {
        double d = distance_value(x, y, services[i][0], services[i][1]);
        access += services[i][2] * (1.0 / (1.0 + d * d));
    }

    return access;
}

void simulate(
    const char *scenario,
    int grid_size,
    double hazard_multiplier,
    double vulnerability_multiplier,
    double population_multiplier,
    double service_capacity_multiplier,
    int service_shift
) {
    double center = ((double)grid_size + 1.0) / 2.0;

    for (int x = 1; x <= grid_size; ++x) {
        for (int y = 1; y <= grid_size; ++y) {
            double d_center = distance_value((double)x, (double)y, center, center);
            double d_river = fabs((double)y - (0.45 * (double)x + 4.0));

            double population = fmax(0.0, (120.0 + 500.0 * exp(-d_center / 7.0) + sin((double)(x * y)) * 25.0) * population_multiplier);
            double hazard = fmin(1.0, (exp(-d_river / 3.0) + 0.06) * hazard_multiplier);
            double vulnerability = fmin(1.0, fmax(0.0, (0.25 + 0.45 * exp(-d_center / 9.0) + 0.03 * sin((double)(x + y))) * vulnerability_multiplier));
            double risk = hazard * population * vulnerability;
            double access = service_access((double)x, (double)y, service_capacity_multiplier, service_shift);
            double gap = population / (access + 1.0);

            printf("%s,%d,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
                   scenario, x, y, population, hazard, vulnerability, risk, access, gap);
        }
    }
}

int main(void) {
    printf("scenario,x,y,population,hazard,vulnerability,risk_score,accessibility,service_gap_score\n");

    simulate("baseline_spatial_system", 25, 1.00, 1.00, 1.00, 1.00, 0);
    simulate("higher_hazard_system", 25, 1.35, 1.00, 1.00, 1.00, 0);
    simulate("high_vulnerability_system", 25, 1.00, 1.35, 1.00, 1.00, 0);
    simulate("low_access_system", 25, 1.00, 1.00, 1.00, 0.65, 0);
    simulate("resilient_service_system", 25, 0.90, 0.90, 1.00, 1.30, 3);

    return 0;
}
