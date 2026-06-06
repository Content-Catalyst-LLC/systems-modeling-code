#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

static double clamp(double value, double low, double high) {
    return std::max(low, std::min(high, value));
}

struct Parameters {
    int run_id;
    double growth_rate;
    double carrying_capacity;
    double balancing_strength;
    double target;
    int delay;
    double shock_size;
};

struct Metrics {
    double final_exponential;
    double final_logistic;
    double final_delayed_feedback;
    double maximum_delayed_feedback;
    int time_to_peak;
    double maximum_outflow;
};

Metrics simulate(const Parameters& p) {
    std::vector<double> exponential;
    std::vector<double> logistic;
    std::vector<double> delayed_feedback;

    exponential.reserve(200);
    logistic.reserve(200);
    delayed_feedback.reserve(200);

    exponential.push_back(10.0);
    logistic.push_back(10.0);
    delayed_feedback.push_back(10.0);

    double maximum_delayed = 10.0;
    int time_to_peak = 0;
    double maximum_outflow = 0.0;

    for (int time = 0; time <= 160; ++time) {
        double current_exponential = exponential.back();
        double current_logistic = logistic.back();
        double current_delayed = delayed_feedback.back();

        int delayed_index = static_cast<int>(delayed_feedback.size()) - 1 - p.delay;
        if (delayed_index < 0) delayed_index = 0;

        double delayed_state = delayed_feedback[delayed_index];
        double inflow = p.growth_rate * current_delayed;
        double outflow = p.balancing_strength * std::max(delayed_state - p.target, 0.0);
        double shock = (time == 90) ? p.shock_size : 0.0;

        exponential.push_back(clamp(current_exponential + p.growth_rate * current_exponential, 0.0, 250.0));
        logistic.push_back(clamp(current_logistic + p.growth_rate * current_logistic * (1.0 - current_logistic / p.carrying_capacity), 0.0, 250.0));
        delayed_feedback.push_back(clamp(current_delayed + inflow - outflow + shock, 0.0, 250.0));

        if (current_delayed > maximum_delayed) {
            maximum_delayed = current_delayed;
            time_to_peak = time;
        }

        maximum_outflow = std::max(maximum_outflow, outflow);
    }

    return {
        exponential[exponential.size() - 2],
        logistic[logistic.size() - 2],
        delayed_feedback[delayed_feedback.size() - 2],
        maximum_delayed,
        time_to_peak,
        maximum_outflow
    };
}

int main() {
    std::mt19937 rng(60606);
    std::uniform_real_distribution<double> growth_rate(0.055, 0.115);
    std::uniform_real_distribution<double> carrying_capacity(55.0, 105.0);
    std::uniform_real_distribution<double> balancing_strength(0.025, 0.095);
    std::uniform_real_distribution<double> target(45.0, 70.0);
    std::uniform_int_distribution<int> delay(2, 16);
    std::uniform_real_distribution<double> shock_size(-16.0, -4.0);

    std::cout << "run_id,growth_rate,carrying_capacity,balancing_strength,target,delay,shock_size,final_exponential,final_logistic,final_delayed_feedback,maximum_delayed_feedback,time_to_peak,maximum_outflow\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        Parameters p{
            run_id,
            growth_rate(rng),
            carrying_capacity(rng),
            balancing_strength(rng),
            target(rng),
            delay(rng),
            shock_size(rng)
        };

        Metrics m = simulate(p);

        std::cout
            << p.run_id << ","
            << p.growth_rate << ","
            << p.carrying_capacity << ","
            << p.balancing_strength << ","
            << p.target << ","
            << p.delay << ","
            << p.shock_size << ","
            << m.final_exponential << ","
            << m.final_logistic << ","
            << m.final_delayed_feedback << ","
            << m.maximum_delayed_feedback << ","
            << m.time_to_peak << ","
            << m.maximum_outflow << "\n";
    }

    return 0;
}
