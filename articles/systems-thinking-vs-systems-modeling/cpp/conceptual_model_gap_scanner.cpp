#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>

static double clamp(double value, double low, double high) {
    return std::max(low, std::min(high, value));
}

struct Parameters {
    int run_id;
    double demand_growth;
    double capacity_growth;
    double rework_rate;
    double intervention_pressure;
    double systems_redesign_strength;
    double delay_factor;
    double uncertainty_humility;
};

struct Result {
    double final_conceptual_score;
    double final_modeled_score;
    double conceptual_model_gap;
    double maximum_backlog;
    double minimum_trust;
};

Result simulate(const Parameters& p) {
    double demand = 80.0;
    double capacity = 70.0;
    double backlog = 22.0;
    double trust = 58.0;
    double rework = 8.0;
    double learning = 22.0;

    double final_conceptual_score = 0.0;
    double final_modeled_score = 0.0;
    double maximum_backlog = backlog;
    double minimum_trust = trust;

    for (int period = 0; period <= 80; ++period) {
        double service_gap = std::max(demand + backlog - capacity, 0.0);
        double service_quality = clamp(100.0 - service_gap * 0.50 - rework * 0.35, 0.0, 100.0);

        double conceptual_score = clamp(
            50.0 + p.systems_redesign_strength * 24.0 + p.uncertainty_humility * 14.0 -
            p.intervention_pressure * 8.0 - service_gap * 0.08,
            0.0,
            100.0
        );

        double modeled_score = clamp(
            service_quality * 0.30 + trust * 0.25 + learning * 0.20 + capacity * 0.10 -
            backlog * 0.10 - rework * 0.15,
            0.0,
            100.0
        );

        final_conceptual_score = conceptual_score;
        final_modeled_score = modeled_score;
        maximum_backlog = std::max(maximum_backlog, backlog);
        minimum_trust = std::min(minimum_trust, trust);

        double pressure_gain = p.intervention_pressure * 4.0;
        double redesign_gain = p.systems_redesign_strength * 3.2;
        double delayed_learning_effect = learning * 0.03 * (1.0 - p.delay_factor);

        demand = demand + p.demand_growth * demand;
        capacity = capacity + p.capacity_growth * capacity + redesign_gain + delayed_learning_effect - rework * 0.015;
        backlog = backlog + demand * 0.10 + rework * 0.30 - capacity * 0.09 - redesign_gain * 0.80;
        rework = rework + service_gap * p.rework_rate + pressure_gain * 0.15 - redesign_gain * 0.45;
        trust = trust - backlog * 0.006 + service_quality * 0.006 + redesign_gain * 0.10;
        learning = learning + p.uncertainty_humility * 1.3 + p.systems_redesign_strength * 1.1 - p.intervention_pressure * 0.45;

        demand = clamp(demand, 0.0, 200.0);
        capacity = clamp(capacity, 0.0, 200.0);
        backlog = clamp(backlog, 0.0, 200.0);
        trust = clamp(trust, 0.0, 100.0);
        rework = clamp(rework, 0.0, 120.0);
        learning = clamp(learning, 0.0, 100.0);
    }

    return {
        final_conceptual_score,
        final_modeled_score,
        final_conceptual_score - final_modeled_score,
        maximum_backlog,
        minimum_trust
    };
}

int main() {
    std::mt19937 rng(202606);
    std::uniform_real_distribution<double> demand_growth(0.012, 0.024);
    std::uniform_real_distribution<double> capacity_growth(0.004, 0.020);
    std::uniform_real_distribution<double> rework_rate(0.008, 0.030);
    std::uniform_real_distribution<double> intervention_pressure(0.10, 0.90);
    std::uniform_real_distribution<double> systems_redesign_strength(0.10, 0.90);
    std::uniform_real_distribution<double> delay_factor(0.10, 0.90);
    std::uniform_real_distribution<double> uncertainty_humility(0.10, 0.90);

    std::cout << "run_id,demand_growth,capacity_growth,rework_rate,intervention_pressure,systems_redesign_strength,delay_factor,uncertainty_humility,final_conceptual_score,final_modeled_score,conceptual_model_gap,maximum_backlog,minimum_trust\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        Parameters p{
            run_id,
            demand_growth(rng),
            capacity_growth(rng),
            rework_rate(rng),
            intervention_pressure(rng),
            systems_redesign_strength(rng),
            delay_factor(rng),
            uncertainty_humility(rng)
        };

        Result result = simulate(p);

        std::cout
            << p.run_id << ","
            << p.demand_growth << ","
            << p.capacity_growth << ","
            << p.rework_rate << ","
            << p.intervention_pressure << ","
            << p.systems_redesign_strength << ","
            << p.delay_factor << ","
            << p.uncertainty_humility << ","
            << result.final_conceptual_score << ","
            << result.final_modeled_score << ","
            << result.conceptual_model_gap << ","
            << result.maximum_backlog << ","
            << result.minimum_trust << "\n";
    }

    return 0;
}
