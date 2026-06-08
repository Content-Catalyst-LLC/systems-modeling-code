#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct PolicySummary {
    std::string policy;
    double average_score;
    double worst_case_score;
    double best_case_score;
    double maximum_regret;
    double acceptable_share;
    double robustness_score;
};

int main() {
    std::vector<PolicySummary> summaries = {
        {"adaptive_pathway", 0.617, 0.557, 0.684, 0.000, 1.000, 0.591},
        {"targeted_intervention", 0.550, 0.493, 0.622, 0.093, 0.833, 0.502},
        {"universal_program", 0.545, 0.473, 0.628, 0.112, 0.667, 0.485},
        {"status_quo_maintenance", 0.380, 0.338, 0.423, 0.275, 0.000, 0.292}
    };

    std::cout << "policy,average_score,worst_case_score,best_case_score,maximum_regret,acceptable_scenario_share,robustness_score\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& item : summaries) {
        std::cout
            << item.policy << ","
            << item.average_score << ","
            << item.worst_case_score << ","
            << item.best_case_score << ","
            << item.maximum_regret << ","
            << item.acceptable_share << ","
            << item.robustness_score << "\n";
    }

    return 0;
}
