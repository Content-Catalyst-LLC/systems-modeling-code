#include <algorithm>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

struct Policy {
    std::string name;
    double policy_strength;
    double adaptive_capacity;
};

struct Result {
    int scenario_id;
    std::string policy;
    double growth;
    double shock_intensity;
    int shock_timing;
    double final_state;
    double maximum_state;
    double cumulative_stress;
    double resilience_score;
};

Result simulate_policy(int scenario_id, const Policy& policy, double growth, double shock_intensity, int shock_timing) {
    double state = 20.0;
    double maximum_state = state;
    double cumulative_stress = 0.0;

    for (int time = 1; time <= 60; ++time) {
        double shock_wave = (time == shock_timing) ? shock_intensity : 0.0;
        double adaptation_effect = policy.adaptive_capacity * std::max(0.0, state - 35.0);

        state = state + growth * state - policy.policy_strength * state - adaptation_effect - shock_wave;
        state = std::max(0.0, state);
        maximum_state = std::max(maximum_state, state);
        cumulative_stress += std::max(0.0, state - 40.0);
    }

    double score = 100.0 - 0.60 * state - 0.25 * maximum_state - 0.10 * cumulative_stress;
    score = std::max(0.0, std::min(100.0, score));

    return {
        scenario_id,
        policy.name,
        growth,
        shock_intensity,
        shock_timing,
        state,
        maximum_state,
        cumulative_stress,
        score
    };
}

int main() {
    std::mt19937 rng(42);
    std::uniform_real_distribution<double> growth_dist(0.035, 0.095);
    std::uniform_real_distribution<double> shock_dist(0.0, 24.0);
    std::uniform_int_distribution<int> timing_dist(20, 45);

    std::vector<Policy> policies = {
        {"Policy_A_low_control", 0.025, 0.010},
        {"Policy_B_balanced", 0.045, 0.020},
        {"Policy_C_high_adaptation", 0.035, 0.045},
        {"Policy_D_precautionary", 0.055, 0.040}
    };

    std::cout << "scenario_id,policy,growth,shock_intensity,shock_timing,final_state,maximum_state,cumulative_stress,resilience_score\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int scenario_id = 1; scenario_id <= 500; ++scenario_id) {
        double growth = growth_dist(rng);
        double shock = shock_dist(rng);
        int shock_timing = timing_dist(rng);

        for (const Policy& policy : policies) {
            Result result = simulate_policy(scenario_id, policy, growth, shock, shock_timing);

            std::cout
                << result.scenario_id << ","
                << result.policy << ","
                << result.growth << ","
                << result.shock_intensity << ","
                << result.shock_timing << ","
                << result.final_state << ","
                << result.maximum_state << ","
                << result.cumulative_stress << ","
                << result.resilience_score << "\n";
        }
    }

    return 0;
}
