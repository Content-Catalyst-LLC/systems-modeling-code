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
    double growth_rate;
    double balancing_strength;
    double target;
    int delay;
    double threshold;
    double threshold_correction;
    double shock_size;
};

struct Metrics {
    double minimum_state;
    double maximum_state;
    double final_state;
    double maximum_overshoot;
    int time_to_peak;
    int threshold_active_periods;
};

Metrics simulate(const Parameters& p) {
    std::vector<double> state;
    state.reserve(200);
    state.push_back(12.0);

    double minimum_state = 12.0;
    double maximum_state = 12.0;
    int time_to_peak = 0;
    int threshold_active_periods = 0;

    for (int time = 0; time <= 160; ++time) {
        double current = state.back();
        int delayed_index = static_cast<int>(state.size()) - 1 - p.delay;
        if (delayed_index < 0) delayed_index = 0;

        double delayed_state = state[delayed_index];
        double inflow = p.growth_rate * current;
        double balancing_outflow = p.balancing_strength * std::max(delayed_state - p.target, 0.0);

        double threshold_penalty = 0.0;
        if (current >= p.threshold) {
            threshold_penalty = p.threshold_correction * (current - p.threshold);
            threshold_active_periods += 1;
        }

        double shock = (time == 70) ? p.shock_size : 0.0;
        double next_state = clamp(current + inflow - balancing_outflow - threshold_penalty + shock, 0.0, 250.0);

        if (current > maximum_state) {
            maximum_state = current;
            time_to_peak = time;
        }

        minimum_state = std::min(minimum_state, current);
        state.push_back(next_state);
    }

    return {
        minimum_state,
        maximum_state,
        state[state.size() - 2],
        maximum_state - 12.0,
        time_to_peak,
        threshold_active_periods
    };
}

int main() {
    std::mt19937 rng(60606);
    std::uniform_real_distribution<double> growth_rate(0.055, 0.115);
    std::uniform_real_distribution<double> balancing_strength(0.025, 0.085);
    std::uniform_real_distribution<double> target(40.0, 65.0);
    std::uniform_int_distribution<int> delay(2, 16);
    std::uniform_real_distribution<double> threshold(70.0, 105.0);
    std::uniform_real_distribution<double> threshold_correction(0.020, 0.095);
    std::uniform_real_distribution<double> shock_size(-18.0, -4.0);

    std::cout << "run_id,growth_rate,balancing_strength,target,delay,threshold,threshold_correction,shock_size,minimum_state,maximum_state,final_state,maximum_overshoot,time_to_peak,threshold_active_periods\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        Parameters p{
            run_id,
            growth_rate(rng),
            balancing_strength(rng),
            target(rng),
            delay(rng),
            threshold(rng),
            threshold_correction(rng),
            shock_size(rng)
        };

        Metrics m = simulate(p);

        std::cout
            << p.run_id << ","
            << p.growth_rate << ","
            << p.balancing_strength << ","
            << p.target << ","
            << p.delay << ","
            << p.threshold << ","
            << p.threshold_correction << ","
            << p.shock_size << ","
            << m.minimum_state << ","
            << m.maximum_state << ","
            << m.final_state << ","
            << m.maximum_overshoot << ","
            << m.time_to_peak << ","
            << m.threshold_active_periods << "\n";
    }

    return 0;
}
