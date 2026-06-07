#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int grid_size;
    double hazard_multiplier;
    double vulnerability_multiplier;
    double population_multiplier;
    double service_capacity_multiplier;
    int service_shift;
};

struct Service {
    std::string id;
    double x;
    double y;
    double capacity;
};

struct Summary {
    std::string scenario;
    int cell_count;
    double population;
    double total_risk;
    double average_risk;
    double average_access;
    double average_gap;
};

double distance_value(double x1, double y1, double x2, double y2) {
    return std::sqrt(std::pow(x1 - x2, 2.0) + std::pow(y1 - y2, 2.0));
}

std::vector<Service> make_services(int shift, double multiplier) {
    return {
        {"clinic_a", 5.0 + shift, 6.0, 900.0 * multiplier},
        {"clinic_b", 9.0, 20.0 - shift, 650.0 * multiplier},
        {"clinic_c", 18.0 - shift, 10.0 + shift, 800.0 * multiplier},
        {"clinic_d", 22.0, 21.0, 500.0 * multiplier}
    };
}

Summary simulate(const Scenario& scenario) {
    double center = (static_cast<double>(scenario.grid_size) + 1.0) / 2.0;
    std::vector<Service> services = make_services(scenario.service_shift, scenario.service_capacity_multiplier);

    int cell_count = 0;
    double total_population = 0.0;
    double total_risk = 0.0;
    double total_access = 0.0;
    double total_gap = 0.0;

    for (int x = 1; x <= scenario.grid_size; ++x) {
        for (int y = 1; y <= scenario.grid_size; ++y) {
            double d_center = distance_value(x, y, center, center);
            double d_river = std::abs(static_cast<double>(y) - (0.45 * static_cast<double>(x) + 4.0));

            double population = std::max(0.0, (120.0 + 500.0 * std::exp(-d_center / 7.0) + std::sin(x * y) * 25.0) * scenario.population_multiplier);
            double hazard = std::min(1.0, (std::exp(-d_river / 3.0) + 0.06) * scenario.hazard_multiplier);
            double vulnerability = std::min(1.0, std::max(0.0, (0.25 + 0.45 * std::exp(-d_center / 9.0) + 0.03 * std::sin(x + y)) * scenario.vulnerability_multiplier));
            double risk = hazard * population * vulnerability;

            double access = 0.0;
            for (const auto& service : services) {
                double d = distance_value(x, y, service.x, service.y);
                access += service.capacity * (1.0 / (1.0 + d * d));
            }

            double gap = population / (access + 1.0);

            cell_count += 1;
            total_population += population;
            total_risk += risk;
            total_access += access;
            total_gap += gap;
        }
    }

    double count = std::max(static_cast<double>(cell_count), 1.0);

    return {
        scenario.name,
        cell_count,
        total_population,
        total_risk,
        total_risk / count,
        total_access / count,
        total_gap / count
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_spatial_system", 25, 1.00, 1.00, 1.00, 1.00, 0},
        {"higher_hazard_system", 25, 1.35, 1.00, 1.00, 1.00, 0},
        {"high_vulnerability_system", 25, 1.00, 1.35, 1.00, 1.00, 0},
        {"low_access_system", 25, 1.00, 1.00, 1.00, 0.65, 0},
        {"resilient_service_system", 25, 0.90, 0.90, 1.00, 1.30, 3}
    };

    std::cout
        << "scenario,cell_count,population,total_risk_score,average_risk_score,"
        << "average_accessibility,average_service_gap_score,diagnostic_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const auto& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.average_risk > 140.0
            ? "elevated spatial risk pressure"
            : "standard spatial pressure";

        std::cout
            << result.scenario << ","
            << result.cell_count << ","
            << result.population << ","
            << result.total_risk << ","
            << result.average_risk << ","
            << result.average_access << ","
            << result.average_gap << ","
            << label << "\n";
    }

    return 0;
}
