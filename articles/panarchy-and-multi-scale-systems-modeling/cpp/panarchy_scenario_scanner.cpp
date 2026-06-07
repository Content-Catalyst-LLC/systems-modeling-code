#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    double fast_growth;
    double fast_capacity;
    double slow_constraint;
    double release_threshold;
    double release_magnitude;
    double revolt_strength;
    double remember_strength;
    double slow_adjustment;
    double slow_target;
};

struct Summary {
    std::string scenario;
    double final_fast_cycle;
    double final_slow_memory;
    int release_events;
    double maximum_fast_cycle;
    double maximum_slow_memory;
    double mean_cross_scale_coupling;
};

Summary simulate(const Scenario& s, int steps) {
    double fast_cycle = 0.5;
    double slow_memory = 1.0;
    double maximum_fast_cycle = fast_cycle;
    double maximum_slow_memory = slow_memory;
    double total_coupling = 0.0;
    int release_events = 0;

    for (int time = 1; time <= steps; ++time) {
        if (time > 1) {
            fast_cycle = fast_cycle + s.fast_growth * fast_cycle * (1.0 - fast_cycle / s.fast_capacity) - s.slow_constraint * slow_memory;

            if (fast_cycle > s.release_threshold) {
                fast_cycle = std::max(0.0, fast_cycle - s.release_magnitude);
                slow_memory += s.revolt_strength;
                release_events++;
            } else {
                slow_memory = slow_memory + s.slow_adjustment * (s.slow_target - slow_memory);
            }

            fast_cycle = std::max(0.0, fast_cycle + s.remember_strength * slow_memory);
        }

        maximum_fast_cycle = std::max(maximum_fast_cycle, fast_cycle);
        maximum_slow_memory = std::max(maximum_slow_memory, slow_memory);
        total_coupling += fast_cycle * slow_memory;
    }

    return {
        s.name,
        fast_cycle,
        slow_memory,
        release_events,
        maximum_fast_cycle,
        maximum_slow_memory,
        total_coupling / static_cast<double>(steps)
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_panarchy", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.035, 0.010, 1.60},
        {"strong_revolt", 0.16, 3.20, 0.08, 2.35, 1.35, 0.24, 0.035, 0.010, 1.60},
        {"strong_remember", 0.16, 3.20, 0.08, 2.50, 1.35, 0.14, 0.065, 0.014, 1.60},
        {"rigid_slow_structure", 0.16, 3.20, 0.13, 2.50, 1.35, 0.14, 0.020, 0.004, 1.60},
        {"weak_memory_high_volatility", 0.17, 3.10, 0.06, 2.30, 1.45, 0.20, 0.015, 0.008, 1.45}
    };

    std::cout << "scenario,final_fast_cycle,final_slow_memory,release_events,maximum_fast_cycle,maximum_slow_memory,mean_cross_scale_coupling\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario, 160);
        std::cout
            << result.scenario << ","
            << result.final_fast_cycle << ","
            << result.final_slow_memory << ","
            << result.release_events << ","
            << result.maximum_fast_cycle << ","
            << result.maximum_slow_memory << ","
            << result.mean_cross_scale_coupling << "\n";
    }

    return 0;
}
