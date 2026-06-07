#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>

double linear_value(double start, double stop, int index, int count) {
    double step = (stop - start) / static_cast<double>(count - 1);
    return start + static_cast<double>(index) * step;
}

int main() {
    int count = 301;

    std::cout << "step,control_parameter,stable_state_positive,stable_state_negative,neutral_state,order_parameter_magnitude,phase_label\n";
    std::cout << std::fixed << std::setprecision(6);

    for (int index = 0; index < count; ++index) {
        double control = linear_value(-1.5, 1.5, index, count);
        double positive = 0.0;
        double negative = 0.0;
        double magnitude = 0.0;
        std::string label = "single neutral phase";

        if (control > 0.0) {
            positive = std::sqrt(control);
            negative = -std::sqrt(control);
            magnitude = positive;
            label = "two ordered phases";
        }

        std::cout
            << index + 1 << ","
            << control << ","
            << positive << ","
            << negative << ","
            << 0.0 << ","
            << magnitude << ","
            << label << "\n";
    }

    return 0;
}
