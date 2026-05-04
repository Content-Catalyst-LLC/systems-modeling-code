#include <algorithm>
#include <iostream>
#include <vector>

int main() {
    const int steps = 140;
    std::vector<double> stock_a(steps, 0.0);
    std::vector<double> stock_b(steps, 0.0);

    stock_a[0] = 20.0;
    stock_b[0] = 10.0;

    const double growth_a_rate = 0.06;
    const double growth_b_rate = 0.04;
    const double b_to_a_pressure = 0.02;
    const double a_to_b_support = 0.04;
    const double b_balancing_rate = 0.03;
    const double target_b = 45.0;

    for (int t = 1; t < steps; ++t) {
        double reinforcing_a = growth_a_rate * stock_a[t - 1];
        double pressure_from_b = -b_to_a_pressure * stock_b[t - 1];

        double reinforcing_b = growth_b_rate * stock_b[t - 1];
        double support_from_a = a_to_b_support * stock_a[t - 1];
        double balancing_b = b_balancing_rate * std::max(stock_b[t - 1] - target_b, 0.0);

        stock_a[t] = stock_a[t - 1] + reinforcing_a + pressure_from_b;
        stock_b[t] = stock_b[t - 1] + reinforcing_b + support_from_a - balancing_b;
    }

    std::cout << "Final stock A: " << stock_a.back() << "\n";
    std::cout << "Final stock B: " << stock_b.back() << "\n";

    return 0;
}
