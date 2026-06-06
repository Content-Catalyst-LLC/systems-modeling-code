#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

static double clamp(double value, double low, double high) {
    return std::max(low, std::min(high, value));
}

struct Parameters {
    int run_id;
    double growth_rate;
    double balancing_strength;
    double target;
    int delay;
    double capacity;
    double threshold;
    double threshold_correction;
    double shock_size;
};

struct Metrics {
    double minimum_stock;
    double maximum_stock;
    double final_stock;
    int time_to_peak;
    double maximum_inflow;
    double maximum_outflow;
    int threshold_active_periods;
};

Metrics simulate(const Parameters& p) {
    std::vector<double> stock;
    stock.reserve(200);
    stock.push_back(20.0);

    double min_stock = 20.0;
    double max_stock = 20.0;
    int time_to_peak = 0;
    double max_inflow = 0.0;
    double max_outflow = 0.0;
    int threshold_active_periods = 0;

    for (int time = 0; time <= 160; ++time) {
        double current = stock.back();
        int delayed_index = static_cast<int>(stock.size()) - 1 - p.delay;
        if (delayed_index < 0) delayed_index = 0;

        double delayed_stock = stock[delayed_index];
        double inflow = p.growth_rate * current * (1.0 - current / p.capacity);
        double outflow = p.balancing_strength * std::max(delayed_stock - p.target, 0.0);

        double threshold_penalty = 0.0;
        if (current >= p.threshold) {
            threshold_penalty = p.threshold_correction * (current - p.threshold);
            threshold_active_periods += 1;
        }

        double shock = (time == 95) ? p.shock_size : 0.0;
        double next_stock = clamp(current + inflow - outflow - threshold_penalty + shock, 0.0, 250.0);

        if (current > max_stock) {
            max_stock = current;
            time_to_peak = time;
        }

        min_stock = std::min(min_stock, current);
        max_inflow = std::max(max_inflow, inflow);
        max_outflow = std::max(max_outflow, outflow);

        stock.push_back(next_stock);
    }

    return {
        min_stock,
        max_stock,
        stock[stock.size() - 2],
        time_to_peak,
        max_inflow,
        max_outflow,
        threshold_active_periods
    };
}

int main() {
    std::mt19937 rng(80606);
    std::uniform_real_distribution<double> growth_rate(0.060, 0.135);
    std::uniform_real_distribution<double> balancing_strength(0.020, 0.095);
    std::uniform_real_distribution<double> target(50.0, 78.0);
    std::uniform_int_distribution<int> delay(2, 16);
    std::uniform_real_distribution<double> capacity(75.0, 130.0);
    std::uniform_real_distribution<double> threshold(70.0, 105.0);
    std::uniform_real_distribution<double> threshold_correction(0.020, 0.115);
    std::uniform_real_distribution<double> shock_size(-18.0, -4.0);

    std::cout << "run_id,growth_rate,balancing_strength,target,delay,capacity,threshold,threshold_correction,shock_size,minimum_stock,maximum_stock,final_stock,time_to_peak,maximum_inflow,maximum_outflow,threshold_active_periods\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        Parameters p{
            run_id,
            growth_rate(rng),
            balancing_strength(rng),
            target(rng),
            delay(rng),
            capacity(rng),
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
            << p.capacity << ","
            << p.threshold << ","
            << p.threshold_correction << ","
            << p.shock_size << ","
            << m.minimum_stock << ","
            << m.maximum_stock << ","
            << m.final_stock << ","
            << m.time_to_peak << ","
            << m.maximum_inflow << ","
            << m.maximum_outflow << ","
            << m.threshold_active_periods << "\n";
    }

    return 0;
}
