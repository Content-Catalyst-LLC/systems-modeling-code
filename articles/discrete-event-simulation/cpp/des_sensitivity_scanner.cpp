#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

struct Parameters {
    int run_id;
    double arrival_rate;
    double service_rate;
    int entities;
    unsigned seed;
};

struct Metrics {
    double average_waiting_time;
    double maximum_waiting_time;
    double service_level_share;
    double implied_utilization;
};

double exponential_time(std::mt19937& rng, double rate) {
    std::uniform_real_distribution<double> dist(0.0, 1.0);
    double draw = std::max(1e-12, 1.0 - dist(rng));
    return -std::log(draw) / rate;
}

Metrics simulate(const Parameters& p) {
    std::mt19937 rng(p.seed);

    std::vector<double> arrival_time(p.entities, 0.0);
    std::vector<double> service_time(p.entities, 0.0);
    std::vector<double> service_start(p.entities, 0.0);
    std::vector<double> departure_time(p.entities, 0.0);
    std::vector<double> waiting_time(p.entities, 0.0);

    for (int i = 0; i < p.entities; ++i) {
        if (i == 0) {
            arrival_time[i] = exponential_time(rng, p.arrival_rate);
        } else {
            arrival_time[i] = arrival_time[i - 1] + exponential_time(rng, p.arrival_rate);
        }
        service_time[i] = exponential_time(rng, p.service_rate);
    }

    service_start[0] = arrival_time[0];
    departure_time[0] = service_start[0] + service_time[0];

    for (int i = 1; i < p.entities; ++i) {
        service_start[i] = std::max(arrival_time[i], departure_time[i - 1]);
        departure_time[i] = service_start[i] + service_time[i];
        waiting_time[i] = service_start[i] - arrival_time[i];
    }

    double total_wait = 0.0;
    double max_wait = 0.0;
    int service_count = 0;

    for (double value : waiting_time) {
        total_wait += value;
        max_wait = std::max(max_wait, value);
        if (value <= 12.0) {
            service_count += 1;
        }
    }

    return {
        total_wait / p.entities,
        max_wait,
        static_cast<double>(service_count) / p.entities,
        p.arrival_rate / p.service_rate
    };
}

int main() {
    std::mt19937 rng(60606);
    std::uniform_real_distribution<double> arrival_rate(0.12, 0.28);
    std::uniform_real_distribution<double> service_rate(0.18, 0.36);

    std::cout << "run_id,arrival_rate,service_rate,entities,average_waiting_time,maximum_waiting_time,service_level_share,implied_utilization\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        Parameters p{
            run_id,
            arrival_rate(rng),
            service_rate(rng),
            240,
            static_cast<unsigned>(9000 + run_id)
        };

        Metrics m = simulate(p);

        std::cout
            << p.run_id << ","
            << p.arrival_rate << ","
            << p.service_rate << ","
            << p.entities << ","
            << m.average_waiting_time << ","
            << m.maximum_waiting_time << ","
            << m.service_level_share << ","
            << m.implied_utilization << "\n";
    }

    return 0;
}
