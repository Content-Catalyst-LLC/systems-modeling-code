#include <algorithm>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    double coupling;
    double recovery;
    double redundancy;
    double shock;
};

double clamp(double value, double low, double high) {
    return std::max(low, std::min(high, value));
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline", 0.18, 0.075, 0.20, -0.55},
        {"high_coupling", 0.28, 0.070, 0.12, -0.55},
        {"higher_redundancy", 0.16, 0.105, 0.42, -0.55},
        {"severe_shock", 0.18, 0.065, 0.20, -0.72}
    };

    std::cout << "scenario,minimum_state,maximum_loss,final_state,unrecovered_loss\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& scenario : scenarios) {
        double state = 1.0;
        double min_state = state;

        for (int t = 1; t < 120; ++t) {
            double dependency_loss = scenario.coupling * (state - 1.0) * (1.0 - scenario.redundancy);
            double recovery = scenario.recovery * (1.0 - state);
            double shock = (t == 40) ? scenario.shock : 0.0;
            state = clamp(state + dependency_loss + recovery + shock, 0.0, 1.25);
            min_state = std::min(min_state, state);
        }

        std::cout
            << scenario.name << ","
            << min_state << ","
            << 1.0 - min_state << ","
            << state << ","
            << 1.0 - state << "\n";
    }

    return 0;
}
