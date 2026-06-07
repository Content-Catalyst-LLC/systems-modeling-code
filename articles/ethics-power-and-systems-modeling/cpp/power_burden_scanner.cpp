#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Stakeholder {
    std::string name;
    double affected;
    int represented;
    double influence;
    double expected_benefit;
    double expected_burden;
};

std::string burden_label(double score) {
    if (score >= 0.45) {
        return "high_power_burden_gap";
    }
    if (score >= 0.20) {
        return "moderate_power_burden_gap";
    }
    return "lower_power_burden_gap";
}

int main() {
    std::vector<Stakeholder> stakeholders = {
        {"public_agency", 0.40, 1, 0.95, 0.80, 0.20},
        {"technical_modelers", 0.20, 1, 0.85, 0.65, 0.15},
        {"frontline_workers", 0.70, 1, 0.45, 0.55, 0.35},
        {"affected_residents", 0.95, 1, 0.35, 0.50, 0.60},
        {"low_access_households", 1.00, 0, 0.10, 0.35, 0.80},
        {"future_generations", 0.90, 0, 0.00, 0.40, 0.75},
        {"local_environment", 0.85, 0, 0.05, 0.30, 0.70}
    };

    std::cout
        << "group,affected,represented,influence,expected_benefit,expected_burden,"
        << "net_benefit,burden_gap,power_burden_gap,risk_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const auto& s : stakeholders) {
        double net_benefit = s.expected_benefit - s.expected_burden;
        double burden_gap = s.expected_burden - s.expected_benefit;
        double power_burden_gap = s.affected * s.expected_burden * (1.0 - s.influence);

        std::cout
            << s.name << ","
            << s.affected << ","
            << s.represented << ","
            << s.influence << ","
            << s.expected_benefit << ","
            << s.expected_burden << ","
            << net_benefit << ","
            << burden_gap << ","
            << power_burden_gap << ","
            << burden_label(power_burden_gap) << "\n";
    }

    return 0;
}
