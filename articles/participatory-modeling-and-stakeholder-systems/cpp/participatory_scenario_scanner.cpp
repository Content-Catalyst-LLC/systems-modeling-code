#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Stakeholder {
    std::string name;
    double access;
    double cost;
    double resilience;
    double equity;
    double feasibility;
};

struct Scenario {
    std::string name;
    double access;
    double cost;
    double resilience;
    double equity;
    double feasibility;
};

double score(const Stakeholder& stakeholder, const Scenario& scenario) {
    return stakeholder.access * scenario.access +
           stakeholder.cost * scenario.cost +
           stakeholder.resilience * scenario.resilience +
           stakeholder.equity * scenario.equity +
           stakeholder.feasibility * scenario.feasibility;
}

double mean(const std::vector<double>& values) {
    double total = 0.0;
    for (double value : values) {
        total += value;
    }
    return total / std::max(static_cast<double>(values.size()), 1.0);
}

double stddev(const std::vector<double>& values) {
    double mu = mean(values);
    double total = 0.0;
    for (double value : values) {
        total += (value - mu) * (value - mu);
    }
    return std::sqrt(total / std::max(static_cast<double>(values.size()), 1.0));
}

int main() {
    std::vector<Stakeholder> stakeholders = {
        {"community_residents", 0.30, 0.10, 0.20, 0.30, 0.10},
        {"frontline_staff", 0.20, 0.15, 0.25, 0.20, 0.20},
        {"technical_experts", 0.15, 0.20, 0.30, 0.15, 0.20},
        {"public_agency", 0.20, 0.25, 0.25, 0.15, 0.15},
        {"service_users", 0.35, 0.10, 0.15, 0.30, 0.10},
        {"resource_managers", 0.15, 0.20, 0.30, 0.15, 0.20}
    };

    std::vector<Scenario> scenarios = {
        {"targeted_service_expansion", 0.85, 0.55, 0.65, 0.90, 0.60},
        {"infrastructure_repair_priority", 0.55, 0.65, 0.85, 0.50, 0.75},
        {"digital_monitoring_platform", 0.60, 0.50, 0.70, 0.45, 0.70},
        {"community_led_resilience", 0.75, 0.70, 0.80, 0.85, 0.55},
        {"baseline_policy_continuation", 0.40, 0.90, 0.35, 0.30, 0.85}
    };

    std::cout
        << "scenario,mean_score,disagreement_sd,minimum_score,maximum_score,"
        << "score_range,legitimacy_adjusted_score,consensus_label\n";

    std::cout << std::fixed << std::setprecision(6);

    for (const auto& scenario : scenarios) {
        std::vector<double> scores;

        for (const auto& stakeholder : stakeholders) {
            scores.push_back(score(stakeholder, scenario));
        }

        double mu = mean(scores);
        double sd = stddev(scores);
        double minimum = *std::min_element(scores.begin(), scores.end());
        double maximum = *std::max_element(scores.begin(), scores.end());
        double legitimacy_adjusted = mu - 0.50 * sd;

        std::string label = "low disagreement";
        if (sd >= 0.08) {
            label = "high disagreement";
        } else if (sd >= 0.04) {
            label = "moderate disagreement";
        }

        std::cout
            << scenario.name << ","
            << mu << ","
            << sd << ","
            << minimum << ","
            << maximum << ","
            << maximum - minimum << ","
            << legitimacy_adjusted << ","
            << label << "\n";
    }

    return 0;
}
