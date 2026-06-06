#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>

struct Parameters {
    int run_id;
    double growth_a;
    double growth_b;
    double coupling_ab;
    double coupling_ba;
    double balancing_b;
    double target_b;
    double shock_size;
};

struct Metrics {
    int run_id;
    double pre_shock_total;
    double minimum_after_shock;
    double final_total;
    double recovery_ratio;
    double max_drawdown;
};

Metrics simulate(const Parameters& p) {
    double stock_a = 24.0;
    double stock_b = 18.0;
    double pressure = 30.0;
    double pre_shock_total = 0.0;
    double minimum_after_shock = 1e12;

    for (int time = 1; time <= 180; ++time) {
        double total = stock_a + stock_b;
        if (time == 74) pre_shock_total = total;
        if (time >= 75) minimum_after_shock = std::min(minimum_after_shock, total);

        double shock = (time == 75) ? p.shock_size : 0.0;

        double reinforcing_a = p.growth_a * stock_a;
        double pressure_from_b = -p.coupling_ab * stock_b;
        double reinforcing_b = p.growth_b * stock_b;
        double support_from_a = p.coupling_ba * stock_a;
        double correction_b = p.balancing_b * std::max(stock_b - p.target_b, 0.0);
        double pressure_feedback = 0.018 * std::max(stock_b - p.target_b, 0.0) + 0.012 * std::max(stock_a - 70.0, 0.0);

        stock_a = std::max(0.0, stock_a + reinforcing_a + pressure_from_b + shock - 0.018 * pressure);
        stock_b = std::max(0.0, stock_b + reinforcing_b + support_from_a - correction_b - 0.010 * pressure);
        pressure = std::max(0.0, pressure + pressure_feedback - 0.045 * pressure);
    }

    double final_total = stock_a + stock_b;
    return {
        p.run_id,
        pre_shock_total,
        minimum_after_shock,
        final_total,
        final_total / pre_shock_total,
        pre_shock_total - minimum_after_shock
    };
}

int main() {
    std::mt19937 rng(60606);
    std::uniform_real_distribution<double> growth_a(0.025, 0.065);
    std::uniform_real_distribution<double> growth_b(0.020, 0.050);
    std::uniform_real_distribution<double> coupling_ab(0.010, 0.030);
    std::uniform_real_distribution<double> coupling_ba(0.025, 0.055);
    std::uniform_real_distribution<double> balancing_b(0.015, 0.040);
    std::uniform_real_distribution<double> target_b(48.0, 65.0);
    std::uniform_real_distribution<double> shock_size(-18.0, -6.0);

    std::cout << "run_id,growth_a,growth_b,coupling_ab,coupling_ba,balancing_b,target_b,shock_size,pre_shock_total,minimum_after_shock,final_total,recovery_ratio,max_drawdown\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int run_id = 1; run_id <= 300; ++run_id) {
        Parameters p{
            run_id,
            growth_a(rng),
            growth_b(rng),
            coupling_ab(rng),
            coupling_ba(rng),
            balancing_b(rng),
            target_b(rng),
            shock_size(rng)
        };

        Metrics m = simulate(p);

        std::cout
            << p.run_id << ","
            << p.growth_a << ","
            << p.growth_b << ","
            << p.coupling_ab << ","
            << p.coupling_ba << ","
            << p.balancing_b << ","
            << p.target_b << ","
            << p.shock_size << ","
            << m.pre_shock_total << ","
            << m.minimum_after_shock << ","
            << m.final_total << ","
            << m.recovery_ratio << ","
            << m.max_drawdown << "\n";
    }

    return 0;
}
