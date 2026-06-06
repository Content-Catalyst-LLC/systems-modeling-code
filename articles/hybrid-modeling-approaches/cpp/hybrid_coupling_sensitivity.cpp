#include <algorithm>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

struct Parameters {
    int run_id;
    int n_agents;
    int n_steps;
    int service_capacity;
    double pressure_sensitivity;
    double baseline_low;
    double baseline_high;
    unsigned seed;
};

struct Metrics {
    int total_arrivals;
    double average_queue_length;
    int maximum_queue_length;
    double average_utilization;
    int final_queue_length;
};

double clamp(double value) {
    return std::max(0.0, std::min(1.0, value));
}

Metrics simulate(const Parameters& p) {
    std::mt19937 rng(p.seed);
    std::uniform_real_distribution<double> baseline_dist(p.baseline_low, p.baseline_high);
    std::uniform_real_distribution<double> unit(0.0, 1.0);

    std::vector<double> propensities(p.n_agents);
    for (int i = 0; i < p.n_agents; ++i) {
        propensities[i] = baseline_dist(rng);
    }

    int queue_length = 0;
    int total_queue = 0;
    int maximum_queue = 0;
    int total_arrivals = 0;
    double total_utilization = 0.0;

    for (int time = 0; time < p.n_steps; ++time) {
        double pressure = static_cast<double>(queue_length) / static_cast<double>(p.service_capacity);
        int arrivals = 0;

        for (double propensity : propensities) {
            double effective = clamp(propensity - p.pressure_sensitivity * pressure);
            if (unit(rng) < effective) {
                arrivals++;
            }
        }

        int available_work = queue_length + arrivals;
        int served = std::min(p.service_capacity, available_work);
        queue_length = available_work - served;

        total_arrivals += arrivals;
        total_queue += queue_length;
        maximum_queue = std::max(maximum_queue, queue_length);
        total_utilization += static_cast<double>(served) / static_cast<double>(p.service_capacity);
    }

    return {
        total_arrivals,
        static_cast<double>(total_queue) / static_cast<double>(p.n_steps),
        maximum_queue,
        total_utilization / static_cast<double>(p.n_steps),
        queue_length
    };
}

int main() {
    std::mt19937 rng(60606);
    std::uniform_int_distribution<int> capacity_dist(16, 44);
    std::uniform_real_distribution<double> sensitivity_dist(0.02, 0.38);
    std::uniform_real_distribution<double> low_dist(0.06, 0.20);
    std::uniform_real_distribution<double> width_dist(0.18, 0.36);

    std::cout << "run_id,n_agents,n_steps,service_capacity,pressure_sensitivity,baseline_low,baseline_high,total_arrivals,average_queue_length,maximum_queue_length,average_utilization,final_queue_length\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        double baseline_low = low_dist(rng);
        double baseline_high = std::min(0.90, baseline_low + width_dist(rng));

        Parameters p{
            run_id,
            160,
            80,
            capacity_dist(rng),
            sensitivity_dist(rng),
            baseline_low,
            baseline_high,
            static_cast<unsigned>(9000 + run_id)
        };

        Metrics m = simulate(p);

        std::cout
            << p.run_id << ","
            << p.n_agents << ","
            << p.n_steps << ","
            << p.service_capacity << ","
            << p.pressure_sensitivity << ","
            << p.baseline_low << ","
            << p.baseline_high << ","
            << m.total_arrivals << ","
            << m.average_queue_length << ","
            << m.maximum_queue_length << ","
            << m.average_utilization << ","
            << m.final_queue_length << "\n";
    }

    return 0;
}
