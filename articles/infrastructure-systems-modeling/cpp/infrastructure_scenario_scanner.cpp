#include <algorithm>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    int shock_start;
    int shock_end;
    double power_loss_rate;
    double power_recovery_rate;
    double communications_dependency;
    double water_power_dependency;
    double water_comms_dependency;
    double transport_power_dependency;
    double transport_comms_dependency;
};

struct Summary {
    std::string scenario;
    double final_composite_service;
    double minimum_power;
    double minimum_communications;
    double minimum_water;
    double minimum_transport;
    double maximum_unmet_service;
    double total_unmet_service;
};

Summary simulate(const Scenario& scenario) {
    double power = 1.0;
    double communications = 1.0;
    double water = 1.0;
    double transport = 1.0;

    double minimum_power = 1.0;
    double minimum_communications = 1.0;
    double minimum_water = 1.0;
    double minimum_transport = 1.0;
    double maximum_unmet_service = 0.0;
    double total_unmet_service = 0.0;
    double final_composite_service = 1.0;

    for (int time = 0; time < scenario.steps; ++time) {
        if (time >= scenario.shock_start && time <= scenario.shock_end) {
            power = std::max(0.45, power - scenario.power_loss_rate);
        } else if (time > scenario.shock_end) {
            power = std::min(1.0, power + scenario.power_recovery_rate);
        } else {
            power = 1.0;
        }

        communications = std::max(
            0.40,
            scenario.communications_dependency * power +
            (1.0 - scenario.communications_dependency) * communications
        );

        water = std::max(
            0.35,
            scenario.water_power_dependency * power +
            scenario.water_comms_dependency * communications +
            (1.0 - scenario.water_power_dependency - scenario.water_comms_dependency) * water
        );

        transport = std::max(
            0.35,
            scenario.transport_power_dependency * power +
            scenario.transport_comms_dependency * communications +
            (1.0 - scenario.transport_power_dependency - scenario.transport_comms_dependency) * transport
        );

        double composite = (power + communications + water + transport) / 4.0;
        double unmet = 1.0 - composite;

        minimum_power = std::min(minimum_power, power);
        minimum_communications = std::min(minimum_communications, communications);
        minimum_water = std::min(minimum_water, water);
        minimum_transport = std::min(minimum_transport, transport);
        maximum_unmet_service = std::max(maximum_unmet_service, unmet);
        total_unmet_service += unmet;
        final_composite_service = composite;
    }

    return {
        scenario.name,
        final_composite_service,
        minimum_power,
        minimum_communications,
        minimum_water,
        minimum_transport,
        maximum_unmet_service,
        total_unmet_service
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_cascade", 80, 20, 36, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25},
        {"larger_power_loss", 80, 20, 36, 0.055, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25},
        {"faster_recovery", 80, 20, 36, 0.035, 0.045, 0.72, 0.55, 0.25, 0.30, 0.25},
        {"longer_shock", 80, 20, 48, 0.035, 0.025, 0.72, 0.55, 0.25, 0.30, 0.25}
    };

    std::cout
        << "scenario,final_composite_service,minimum_power,minimum_communications,"
        << "minimum_water,minimum_transport,maximum_unmet_service,total_unmet_service,diagnostic_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.maximum_unmet_service > 0.35
            ? "severe cascade pathway"
            : "managed cascade pathway";

        std::cout
            << result.scenario << ","
            << result.final_composite_service << ","
            << result.minimum_power << ","
            << result.minimum_communications << ","
            << result.minimum_water << ","
            << result.minimum_transport << ","
            << result.maximum_unmet_service << ","
            << result.total_unmet_service << ","
            << label << "\n";
    }

    return 0;
}
