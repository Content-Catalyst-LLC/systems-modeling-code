#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    int steps;
    double demand_sensitivity;
    double investment_sensitivity;
    double interest_rate;
    double depreciation;
    double credit_sensitivity;
    int shock_step;
    double shock_size;
};

struct Summary {
    std::string scenario;
    double final_output;
    double final_capital;
    double final_debt;
    double final_fragility;
    double maximum_fragility;
    double minimum_output;
    double average_output;
};

double deterministic_noise(int step) {
    return std::sin(static_cast<double>(step) * 1.61803398875) * 0.35;
}

Summary simulate(const Scenario& scenario) {
    double output = 100.0;
    double capital = 190.0;
    double debt = 60.0;
    double government = 22.0;

    double maximum_fragility = debt / capital;
    double minimum_output = output;
    double total_output = 0.0;

    for (int step = 1; step <= scenario.steps; ++step) {
        double consumption = std::max(0.0, 18.0 + scenario.demand_sensitivity * output - 0.025 * debt);
        double investment = std::max(0.0, scenario.investment_sensitivity * output - scenario.interest_rate * debt);

        if (step > 1) {
            capital = std::max(0.0, capital + investment - scenario.depreciation * capital);

            double new_credit = std::max(0.0, scenario.credit_sensitivity * investment);
            double repayment = 0.025 * debt;
            debt = std::max(0.0, debt + new_credit - repayment);

            double shock = step == scenario.shock_step ? scenario.shock_size : 0.0;
            output = std::max(0.0, 0.33 * capital + consumption + government + shock + deterministic_noise(step));
        }

        double fragility = debt / std::max(capital, 1.0);

        maximum_fragility = std::max(maximum_fragility, fragility);
        minimum_output = std::min(minimum_output, output);
        total_output += output;
    }

    return {
        scenario.name,
        output,
        capital,
        debt,
        debt / std::max(capital, 1.0),
        maximum_fragility,
        minimum_output,
        total_output / static_cast<double>(scenario.steps)
    };
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline_feedback", 120, 0.62, 0.16, 0.035, 0.045, 0.10, 70, -8.0},
        {"higher_investment", 120, 0.62, 0.21, 0.035, 0.045, 0.10, 70, -8.0},
        {"tighter_credit", 120, 0.62, 0.16, 0.055, 0.045, 0.10, 70, -8.0},
        {"larger_shock", 120, 0.62, 0.16, 0.035, 0.045, 0.10, 70, -18.0}
    };

    std::cout << "scenario,final_output,final_capital,final_debt,final_fragility,maximum_fragility,minimum_output,average_output,diagnostic_label\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        Summary result = simulate(scenario);
        std::string label = result.maximum_fragility > 0.75 ? "high fragility pathway" : "moderate fragility pathway";

        std::cout
            << result.scenario << ","
            << result.final_output << ","
            << result.final_capital << ","
            << result.final_debt << ","
            << result.final_fragility << ","
            << result.maximum_fragility << ","
            << result.minimum_output << ","
            << result.average_output << ","
            << label << "\n";
    }

    return 0;
}
