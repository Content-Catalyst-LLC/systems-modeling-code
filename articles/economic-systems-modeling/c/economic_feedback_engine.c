#include <math.h>
#include <stdio.h>

#define STEPS 120

void simulate(const char *scenario, double demand_sensitivity, double investment_sensitivity, double interest_rate, double depreciation, double credit_sensitivity, int shock_step, double shock_size) {
    double output = 100.0;
    double capital = 190.0;
    double debt = 60.0;
    double government = 22.0;

    for (int step = 1; step <= STEPS; ++step) {
        double consumption = fmax(0.0, 18.0 + demand_sensitivity * output - 0.025 * debt);
        double investment = fmax(0.0, investment_sensitivity * output - interest_rate * debt);

        if (step > 1) {
            capital = fmax(0.0, capital + investment - depreciation * capital);

            double new_credit = fmax(0.0, credit_sensitivity * investment);
            double repayment = 0.025 * debt;
            debt = fmax(0.0, debt + new_credit - repayment);

            double shock = (step == shock_step) ? shock_size : 0.0;
            double noise = sin((double)step * 1.61803398875) * 0.35;

            output = fmax(0.0, 0.33 * capital + consumption + government + shock + noise);
        }

        double debt_service = interest_rate * debt;
        double fragility = debt / fmax(capital, 1.0);
        double demand_gap = output - consumption - investment - government;

        printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
               scenario,
               step,
               output,
               consumption,
               investment,
               capital,
               debt,
               debt_service,
               fragility,
               government,
               demand_gap);
    }
}

int main(void) {
    printf("scenario,time,output,consumption,investment,capital,debt,debt_service,fragility,government,demand_gap\n");

    simulate("baseline_feedback", 0.62, 0.16, 0.035, 0.045, 0.10, 70, -8.0);
    simulate("higher_investment", 0.62, 0.21, 0.035, 0.045, 0.10, 70, -8.0);
    simulate("tighter_credit", 0.62, 0.16, 0.055, 0.045, 0.10, 70, -8.0);
    simulate("larger_shock", 0.62, 0.16, 0.035, 0.045, 0.10, 70, -18.0);

    return 0;
}
