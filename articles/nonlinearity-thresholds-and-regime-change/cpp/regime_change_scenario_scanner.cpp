#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    double collapse_threshold;
    double recovery_threshold;
    int intervention_time;
    double pressure_growth;
    double recovery_effort;
};

struct Summary {
    std::string scenario;
    double initial_state;
    double final_state;
    double minimum_state;
    double maximum_pressure;
    int degraded_periods;
    std::string final_regime;
    double mean_net_flow;
    double hysteresis_gap;
};

Summary simulate(const Scenario& scenario, int steps) {
    double system_state = 82.0;
    double initial_state = system_state;
    double pressure = 20.0;
    std::string regime = "stable";

    double minimum_state = system_state;
    double maximum_pressure = pressure;
    int degraded_periods = 0;
    double total_net_flow = 0.0;

    for (int time = 1; time <= steps; ++time) {
        double net_flow = 0.0;

        if (time > 1) {
            pressure += scenario.pressure_growth;

            if (time >= scenario.intervention_time) {
                pressure = std::max(0.0, pressure - scenario.recovery_effort);
            }

            if (regime == "stable" && pressure >= scenario.collapse_threshold) {
                regime = "degraded";
            } else if (regime == "degraded" && pressure <= scenario.recovery_threshold) {
                regime = "stable";
            }

            double damage_flow;
            double recovery_flow;

            if (regime == "stable") {
                damage_flow = 0.05 * pressure + 0.002 * pressure * pressure;
                recovery_flow = 2.6;
            } else {
                damage_flow = 0.09 * pressure + 0.006 * pressure * pressure + 1.8;
                recovery_flow = 0.8 + 0.03 * system_state;
            }

            net_flow = recovery_flow - damage_flow;
            system_state = std::min(100.0, std::max(0.0, system_state + net_flow));
        }

        if (regime == "degraded") {
            degraded_periods++;
        }

        minimum_state = std::min(minimum_state, system_state);
        maximum_pressure = std::max(maximum_pressure, pressure);
        total_net_flow += net_flow;
    }

    return {
        scenario.name,
        initial_state,
        system_state,
        minimum_state,
        maximum_pressure,
        degraded_periods,
        regime,
        total_net_flow / static_cast<double>(steps),
        scenario.collapse_threshold - scenario.recovery_threshold
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"early_intervention", 70.0, 45.0, 55, 0.85, 1.20},
        {"late_intervention", 70.0, 45.0, 85, 0.85, 1.20},
        {"strong_recovery", 70.0, 45.0, 85, 0.85, 2.00},
        {"lower_threshold_stress", 58.0, 38.0, 70, 0.95, 1.20},
        {"hysteresis_trap", 66.0, 30.0, 88, 0.90, 1.30},
        {"rapid_prevention", 70.0, 45.0, 40, 0.85, 1.80}
    };

    std::cout << "scenario,initial_state,final_state,minimum_state,maximum_pressure,degraded_periods,final_regime,mean_net_flow,hysteresis_gap\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario, 140);
        std::cout
            << result.scenario << ","
            << result.initial_state << ","
            << result.final_state << ","
            << result.minimum_state << ","
            << result.maximum_pressure << ","
            << result.degraded_periods << ","
            << result.final_regime << ","
            << result.mean_net_flow << ","
            << result.hysteresis_gap << "\n";
    }

    return 0;
}
