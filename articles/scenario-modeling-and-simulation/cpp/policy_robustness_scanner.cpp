#include <algorithm>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

struct Policy {
    std::string name;
    double policy_drag;
    double resilience_buffer;
};

struct Result {
    int scenario_id;
    std::string policy;
    double growth;
    double external_shock;
    int shock_time;
    double final_state;
    double maximum_state;
    double cumulative_cost;
    double resilience_score;
};

double resilience_score(double final_state, double maximum_state, double cumulative_cost) {
    double score = 100.0 - 0.8 * final_state - 0.3 * maximum_state - 0.2 * cumulative_cost;
    return std::max(0.0, std::min(100.0, score));
}

Result simulate_policy(int scenario_id, const Policy& policy, double growth, double external_shock, int shock_time) {
    double state = 20.0;
    double maximum_state = state;
    double cumulative_cost = 0.0;

    for (int time = 1; time <= 60; ++time) {
        state = state + growth * state - policy.policy_drag * state;

        if (time == shock_time) {
            state = std::max(0.0, state - external_shock / std::max(1.0, policy.resilience_buffer));
        }

        double policy_cost = 4.0 * policy.policy_drag + 0.08 * policy.resilience_buffer;
        double stress_cost = 0.03 * std::max(0.0, state - 35.0) * std::max(0.0, state - 35.0);
        cumulative_cost += policy_cost + stress_cost;
        maximum_state = std::max(maximum_state, state);
    }

    return {
        scenario_id,
        policy.name,
        growth,
        external_shock,
        shock_time,
        state,
        maximum_state,
        cumulative_cost,
        resilience_score(state, maximum_state, cumulative_cost)
    };
}

int main() {
    std::mt19937 rng(4242);
    std::uniform_real_distribution<double> growth_dist(0.030, 0.075);
    std::uniform_real_distribution<double> shock_dist(0.0, 18.0);
    std::uniform_int_distribution<int> shock_time_dist(20, 45);

    std::vector<Policy> policies = {
        {"Policy_A_low_intervention", 0.010, 4.0},
        {"Policy_B_moderate_intervention", 0.025, 7.0},
        {"Policy_C_high_resilience", 0.020, 12.0}
    };

    std::cout << "scenario_id,policy,growth,external_shock,shock_time,final_state,maximum_state,cumulative_cost,resilience_score\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int scenario_id = 1; scenario_id <= 300; ++scenario_id) {
        double growth = growth_dist(rng);
        double shock = shock_dist(rng);
        int shock_time = shock_time_dist(rng);

        for (const Policy& policy : policies) {
            Result result = simulate_policy(scenario_id, policy, growth, shock, shock_time);

            std::cout
                << result.scenario_id << ","
                << result.policy << ","
                << result.growth << ","
                << result.external_shock << ","
                << result.shock_time << ","
                << result.final_state << ","
                << result.maximum_state << ","
                << result.cumulative_cost << ","
                << result.resilience_score << "\n";
        }
    }

    return 0;
}
