#include <math.h>
#include <stdio.h>

#define STEPS 120

void simulate(
    const char *scenario,
    double initial_stock,
    double carrying_capacity,
    double growth_rate,
    double extraction_rate,
    double restoration_rate,
    int disturbance_step,
    double disturbance_size
) {
    double stock = initial_stock;

    for (int step = 1; step <= STEPS; ++step) {
        double regeneration = growth_rate * stock * (1.0 - stock / carrying_capacity);
        double extraction = extraction_rate * stock;
        double restoration = restoration_rate * (carrying_capacity - stock);
        double disturbance = (step == disturbance_step) ? disturbance_size : 0.0;

        stock = fmax(
            0.0,
            fmin(carrying_capacity, stock + regeneration - extraction + restoration - disturbance)
        );

        double resilience_index = stock / carrying_capacity;

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               step,
               stock,
               regeneration,
               extraction,
               restoration,
               disturbance,
               resilience_index);
    }
}

int main(void) {
    printf("scenario,time,stock,regeneration,extraction,restoration,disturbance,resilience_index\n");

    simulate("baseline_pressure", 70.0, 100.0, 0.065, 0.040, 0.010, 65, 12.0);
    simulate("high_extraction", 70.0, 100.0, 0.065, 0.065, 0.010, 65, 12.0);
    simulate("restoration_investment", 70.0, 100.0, 0.065, 0.040, 0.035, 65, 12.0);
    simulate("larger_disturbance", 70.0, 100.0, 0.065, 0.040, 0.010, 65, 24.0);

    return 0;
}
