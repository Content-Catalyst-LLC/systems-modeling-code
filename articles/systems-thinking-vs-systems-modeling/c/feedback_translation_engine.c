#include <math.h>
#include <stdio.h>

static double clamp(double value, double low, double high) {
    if (value < low) return low;
    if (value > high) return high;
    return value;
}

int main(void) {
    double demand = 80.0;
    double capacity = 70.0;
    double backlog = 22.0;
    double trust = 58.0;
    double rework = 8.0;
    double learning = 22.0;

    const double demand_growth = 0.018;
    const double capacity_growth = 0.014;
    const double rework_rate = 0.012;
    const double trust_loss_from_backlog = 0.005;
    const double trust_gain_from_service = 0.008;
    const double intervention_pressure = 0.28;
    const double systems_redesign_strength = 0.78;
    const double delay_factor = 0.25;
    const double uncertainty_humility = 0.82;

    printf("period,demand,capacity,backlog,trust,rework,learning,service_quality,conceptual_score,modeled_score,conceptual_model_gap\n");

    for (int period = 0; period <= 80; ++period) {
        double service_gap = fmax(demand + backlog - capacity, 0.0);
        double service_quality = clamp(100.0 - service_gap * 0.50 - rework * 0.35, 0.0, 100.0);

        double conceptual_score = clamp(
            50.0 + systems_redesign_strength * 24.0 + uncertainty_humility * 14.0 -
            intervention_pressure * 8.0 - service_gap * 0.08,
            0.0,
            100.0
        );

        double modeled_score = clamp(
            service_quality * 0.30 + trust * 0.25 + learning * 0.20 + capacity * 0.10 -
            backlog * 0.10 - rework * 0.15,
            0.0,
            100.0
        );

        printf("%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               period, demand, capacity, backlog, trust, rework, learning, service_quality,
               conceptual_score, modeled_score, conceptual_score - modeled_score);

        double pressure_gain = intervention_pressure * 4.0;
        double redesign_gain = systems_redesign_strength * 3.2;
        double delayed_learning_effect = learning * 0.03 * (1.0 - delay_factor);

        demand = demand + demand_growth * demand;
        capacity = capacity + capacity_growth * capacity + redesign_gain + delayed_learning_effect - rework * 0.015;
        backlog = backlog + demand * 0.10 + rework * 0.30 - capacity * 0.09 - redesign_gain * 0.80;
        rework = rework + service_gap * rework_rate + pressure_gain * 0.15 - redesign_gain * 0.45;
        trust = trust - backlog * trust_loss_from_backlog + service_quality * trust_gain_from_service + redesign_gain * 0.10;
        learning = learning + uncertainty_humility * 1.3 + systems_redesign_strength * 1.1 - intervention_pressure * 0.45;

        demand = clamp(demand, 0.0, 200.0);
        capacity = clamp(capacity, 0.0, 200.0);
        backlog = clamp(backlog, 0.0, 200.0);
        trust = clamp(trust, 0.0, 100.0);
        rework = clamp(rework, 0.0, 120.0);
        learning = clamp(learning, 0.0, 100.0);
    }

    return 0;
}
