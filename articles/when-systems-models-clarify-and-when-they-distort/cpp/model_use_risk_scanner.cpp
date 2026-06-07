#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct ModelCase {
    std::string name;
    double structural_clarity;
    double dynamic_clarity;
    double scenario_clarity;
    double assumption_transparency;
    double false_precision_risk;
    double boundary_risk;
    double proxy_risk;
    double misuse_risk;
};

double clarification_score(const ModelCase& m) {
    return 0.30 * m.structural_clarity +
           0.25 * m.dynamic_clarity +
           0.25 * m.scenario_clarity +
           0.20 * m.assumption_transparency;
}

double distortion_risk_score(const ModelCase& m) {
    return 0.25 * m.false_precision_risk +
           0.30 * m.boundary_risk +
           0.20 * m.proxy_risk +
           0.25 * m.misuse_risk;
}

std::string use_label(double net) {
    if (net >= 0.20) {
        return "strong_clarification_with_managed_risk";
    }
    if (net >= 0.0) {
        return "useful_with_strong_caveats";
    }
    return "high_distortion_risk_without_revision";
}

int main() {
    std::vector<ModelCase> cases = {
        {"infrastructure_resilience_model", 0.85, 0.70, 0.80, 0.65, 0.45, 0.65, 0.45, 0.50},
        {"public_health_capacity_model", 0.75, 0.85, 0.70, 0.60, 0.55, 0.70, 0.55, 0.65},
        {"urban_accessibility_model", 0.70, 0.50, 0.60, 0.70, 0.60, 0.75, 0.70, 0.55},
        {"energy_transition_pathway_model", 0.80, 0.80, 0.85, 0.55, 0.50, 0.65, 0.50, 0.60},
        {"machine_learning_risk_model", 0.45, 0.40, 0.35, 0.35, 0.85, 0.70, 0.85, 0.90},
        {"digital_twin_operations_model", 0.75, 0.65, 0.70, 0.50, 0.70, 0.60, 0.50, 0.75}
    };

    std::cout << "model_case,clarification_score,distortion_risk_score,net_interpretive_value,use_label\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& item : cases) {
        double c = clarification_score(item);
        double d = distortion_risk_score(item);
        double n = c - d;

        std::cout
            << item.name << ","
            << c << ","
            << d << ","
            << n << ","
            << use_label(n) << "\n";
    }

    return 0;
}
