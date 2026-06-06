#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Result {
    double growth_a;
    double coupling_ab;
    double final_total;
    double minimum_total;
    double recovery_ratio;
};

Result simulate(double growth_a, double coupling_ab) {
    const int n_steps = 160;
    double stock_a = 24.0;
    double stock_b = 18.0;
    double pressure = 30.0;
    double pre_shock_total = 0.0;
    double minimum_after_shock = 1e12;

    for (int t = 1; t <= n_steps; ++t) {
        double total = stock_a + stock_b;
        if (t == 74) pre_shock_total = total;
        if (t >= 75) minimum_after_shock = std::min(minimum_after_shock, total);

        double shock = (t == 75) ? -12.0 : 0.0;
        double reinforcing_a = growth_a * stock_a;
        double pressure_from_b = -coupling_ab * stock_b;
        double reinforcing_b = 0.032 * stock_b;
        double support_from_a = 0.041 * stock_a;
        double correction_b = 0.026 * std::max(stock_b - 55.0, 0.0);
        double pressure_feedback = 0.018 * std::max(stock_b - 55.0, 0.0) + 0.012 * std::max(stock_a - 70.0, 0.0);

        stock_a = std::max(0.0, stock_a + reinforcing_a + pressure_from_b + shock - 0.018 * pressure);
        stock_b = std::max(0.0, stock_b + reinforcing_b + support_from_a - correction_b - 0.010 * pressure);
        pressure = std::max(0.0, pressure + pressure_feedback - 0.045 * pressure);
    }

    double final_total = stock_a + stock_b;
    return {growth_a, coupling_ab, final_total, minimum_after_shock, final_total / pre_shock_total};
}

int main() {
    std::vector<Result> results;

    for (double growth = 0.025; growth <= 0.065 + 1e-9; growth += 0.005) {
        for (double coupling = 0.010; coupling <= 0.030 + 1e-9; coupling += 0.005) {
            results.push_back(simulate(growth, coupling));
        }
    }

    std::cout << "growth_a,coupling_ab,final_total,minimum_total,recovery_ratio\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const auto& result : results) {
        std::cout
            << result.growth_a << ","
            << result.coupling_ab << ","
            << result.final_total << ","
            << result.minimum_total << ","
            << result.recovery_ratio << "\n";
    }

    return 0;
}
