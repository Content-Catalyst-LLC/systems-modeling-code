#include <algorithm>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

struct Parameters {
    int run_id;
    double growth_rate;
    double carrying_capacity;
    double extraction_pressure;
    int recovery_delay;
    double feedback_strength;
    double shock_intensity;
};

struct Result {
    double final_state;
    double maximum_state;
    double minimum_state;
    double mean_state;
};

Result simulate(const Parameters& p) {
    const int steps = 80;
    std::vector<double> state(steps, 0.0);
    state[0] = 10.0;
    int shock_time = steps / 2;

    for (int time = 1; time < steps; ++time) {
        int delayed_index = std::max(0, time - p.recovery_delay);
        double delayed_recovery = p.feedback_strength * state[delayed_index];
        double shock_effect = (time == shock_time) ? p.shock_intensity : 0.0;
        double previous = state[time - 1];

        double next_state =
            previous +
            p.growth_rate * previous * (1.0 - previous / p.carrying_capacity) -
            p.extraction_pressure * previous +
            delayed_recovery -
            shock_effect;

        state[time] = std::max(0.0, next_state);
    }

    double maximum_state = *std::max_element(state.begin(), state.end());
    double minimum_state = *std::min_element(state.begin(), state.end());
    double total = 0.0;
    for (double value : state) {
        total += value;
    }

    return {state.back(), maximum_state, minimum_state, total / steps};
}

int main() {
    std::mt19937 rng(60606);

    std::uniform_real_distribution<double> growth_dist(0.04, 0.12);
    std::uniform_real_distribution<double> capacity_dist(60.0, 140.0);
    std::uniform_real_distribution<double> extraction_dist(0.005, 0.060);
    std::uniform_int_distribution<int> delay_dist(1, 12);
    std::uniform_real_distribution<double> feedback_dist(0.005, 0.050);
    std::uniform_real_distribution<double> shock_dist(0.0, 24.0);

    std::cout << "run_id,growth_rate,carrying_capacity,extraction_pressure,recovery_delay,feedback_strength,shock_intensity,final_state,maximum_state,minimum_state,mean_state\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 400; ++run_id) {
        Parameters p{
            run_id,
            growth_dist(rng),
            capacity_dist(rng),
            extraction_dist(rng),
            delay_dist(rng),
            feedback_dist(rng),
            shock_dist(rng)
        };

        Result result = simulate(p);

        std::cout
            << p.run_id << ","
            << p.growth_rate << ","
            << p.carrying_capacity << ","
            << p.extraction_pressure << ","
            << p.recovery_delay << ","
            << p.feedback_strength << ","
            << p.shock_intensity << ","
            << result.final_state << ","
            << result.maximum_state << ","
            << result.minimum_state << ","
            << result.mean_state << "\n";
    }

    return 0;
}
