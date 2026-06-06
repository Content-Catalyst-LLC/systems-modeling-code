#include <algorithm>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

struct Strategy {
    std::string name;
    double redundancy;
    double adaptive_response;
};

struct Result {
    double minimum_service;
    double cumulative_unmet;
    double failure_frequency;
    double resilience_score;
};

Result simulate_strategy(double demand_growth, double capacity_loss, int shock_duration, double recovery_drag, const Strategy& strategy) {
    const int steps = 72;
    const int shock_start = 28;
    const double baseline_capacity = 100.0;

    double demand = 55.0;
    double capacity = baseline_capacity * (1.0 + strategy.redundancy);
    double minimum_service = 1.0;
    double cumulative_unmet = 0.0;
    int failure_count = 0;

    for (int time = 1; time <= steps; ++time) {
        demand *= 1.0 + demand_growth;
        bool shock_active = time >= shock_start && time < shock_start + shock_duration;

        if (time == shock_start) {
            capacity = std::max(0.0, capacity - capacity_loss);
        }

        if (shock_active) {
            demand *= 1.010;
        } else {
            double recovery_rate = std::max(0.0, 0.12 + strategy.adaptive_response - recovery_drag);
            double target_capacity = baseline_capacity * (1.0 + strategy.redundancy);
            capacity += recovery_rate * (target_capacity - capacity);
        }

        double service_ratio = demand <= 0.0 ? 1.0 : std::min(capacity / demand, 1.0);
        double unmet = std::max(0.0, demand - capacity);

        minimum_service = std::min(minimum_service, service_ratio);
        cumulative_unmet += unmet;

        if (service_ratio < 0.85) {
            failure_count++;
        }
    }

    double score = 100.0 - 70.0 * (1.0 - minimum_service) - 0.05 * cumulative_unmet - 0.40 * static_cast<double>(failure_count);
    score = std::max(0.0, std::min(100.0, score));

    return {
        minimum_service,
        cumulative_unmet,
        static_cast<double>(failure_count) / static_cast<double>(steps),
        score
    };
}

int main() {
    std::mt19937 rng(42);
    std::uniform_real_distribution<double> demand_dist(0.008, 0.035);
    std::uniform_real_distribution<double> loss_dist(0.0, 45.0);
    std::uniform_int_distribution<int> duration_dist(1, 20);
    std::uniform_real_distribution<double> drag_dist(0.0, 0.09);

    std::vector<Strategy> strategies = {
        {"Strategy_A_efficiency", 0.02, 0.02},
        {"Strategy_B_balanced_resilience", 0.12, 0.06},
        {"Strategy_C_high_redundancy", 0.25, 0.03},
        {"Strategy_D_adaptive_pathway", 0.08, 0.11}
    };

    std::cout << "scenario_id,strategy,demand_growth,capacity_loss,shock_duration,recovery_drag,minimum_service_ratio,cumulative_unmet_demand,failure_frequency,resilience_score\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int scenario_id = 1; scenario_id <= 600; ++scenario_id) {
        double demand_growth = demand_dist(rng);
        double capacity_loss = loss_dist(rng);
        int shock_duration = duration_dist(rng);
        double recovery_drag = drag_dist(rng);

        for (const Strategy& strategy : strategies) {
            Result result = simulate_strategy(demand_growth, capacity_loss, shock_duration, recovery_drag, strategy);

            std::cout
                << scenario_id << ","
                << strategy.name << ","
                << demand_growth << ","
                << capacity_loss << ","
                << shock_duration << ","
                << recovery_drag << ","
                << result.minimum_service << ","
                << result.cumulative_unmet << ","
                << result.failure_frequency << ","
                << result.resilience_score << "\n";
        }
    }

    return 0;
}
