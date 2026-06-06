#include <algorithm>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <random>
#include <string>
#include <vector>

struct Parameters {
    int run_id;
    int n_agents;
    int n_steps;
    int initial_adopters;
    double threshold_low;
    double threshold_high;
    int neighbor_radius;
    unsigned seed;
};

struct Metrics {
    double initial_adoption_rate;
    double final_adoption_rate;
    int peak_new_adopters;
    int time_to_half_adoption;
    double mean_threshold;
};

Metrics simulate(const Parameters& p) {
    std::mt19937 rng(p.seed);
    std::uniform_real_distribution<double> threshold_dist(p.threshold_low, p.threshold_high);

    std::vector<double> thresholds(p.n_agents);
    for (int i = 0; i < p.n_agents; ++i) {
        thresholds[i] = threshold_dist(rng);
    }

    std::vector<bool> adopted(p.n_agents, false);
    std::vector<int> indices(p.n_agents);
    std::iota(indices.begin(), indices.end(), 0);
    std::shuffle(indices.begin(), indices.end(), rng);

    for (int i = 0; i < std::min(p.initial_adopters, p.n_agents); ++i) {
        adopted[indices[i]] = true;
    }

    auto rate = [&]() {
        int count = 0;
        for (bool value : adopted) {
            if (value) count++;
        }
        return static_cast<double>(count) / static_cast<double>(p.n_agents);
    };

    double initial_rate = rate();
    double final_rate = initial_rate;
    int peak_new = 0;
    int time_to_half = 0;

    for (int time = 1; time <= p.n_steps; ++time) {
        std::vector<bool> previous = adopted;

        for (int i = 0; i < p.n_agents; ++i) {
            if (previous[i]) continue;

            int local_count = 0;
            int adopted_count = 0;

            for (int offset = 1; offset <= p.neighbor_radius; ++offset) {
                int left = (i + p.n_agents - offset) % p.n_agents;
                int right = (i + offset) % p.n_agents;

                local_count += 2;
                if (previous[left]) adopted_count++;
                if (previous[right]) adopted_count++;
            }

            double local_share = static_cast<double>(adopted_count) / static_cast<double>(local_count);
            if (local_share >= thresholds[i]) {
                adopted[i] = true;
            }
        }

        int new_adopters = 0;
        for (int i = 0; i < p.n_agents; ++i) {
            if (adopted[i] && !previous[i]) new_adopters++;
        }

        peak_new = std::max(peak_new, new_adopters);
        final_rate = rate();

        if (time_to_half == 0 && final_rate >= 0.5) {
            time_to_half = time;
        }
    }

    double mean_threshold = std::accumulate(thresholds.begin(), thresholds.end(), 0.0) / thresholds.size();

    return {
        initial_rate,
        final_rate,
        peak_new,
        time_to_half,
        mean_threshold
    };
}

int main() {
    std::mt19937 rng(90606);
    std::uniform_int_distribution<int> initial_adopters(4, 35);
    std::uniform_real_distribution<double> threshold_low(0.03, 0.35);
    std::uniform_real_distribution<double> threshold_width(0.20, 0.55);
    std::uniform_int_distribution<int> radius(1, 5);

    std::cout << "run_id,n_agents,n_steps,initial_adopters,threshold_low,threshold_high,neighbor_radius,initial_adoption_rate,final_adoption_rate,peak_new_adopters,time_to_half_adoption,mean_threshold\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        double low = threshold_low(rng);
        double high = std::min(0.95, low + threshold_width(rng));

        Parameters p{
            run_id,
            180,
            50,
            initial_adopters(rng),
            low,
            high,
            radius(rng),
            static_cast<unsigned>(9000 + run_id)
        };

        Metrics m = simulate(p);

        std::cout
            << p.run_id << ","
            << p.n_agents << ","
            << p.n_steps << ","
            << p.initial_adopters << ","
            << p.threshold_low << ","
            << p.threshold_high << ","
            << p.neighbor_radius << ","
            << m.initial_adoption_rate << ","
            << m.final_adoption_rate << ","
            << m.peak_new_adopters << ","
            << m.time_to_half_adoption << ","
            << m.mean_threshold << "\n";
    }

    return 0;
}
