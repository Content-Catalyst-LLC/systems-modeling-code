#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct Scenario {
    std::string name;
    double arrival_multiplier;
    double completion_shift;
    double extraction_before;
    double extraction_after;
    int resource_policy_time;
    double maintenance_before;
    double maintenance_after;
    int maintenance_policy_time;
};

struct Values {
    double backlog;
    double resource;
    double condition;
    double backlog_net;
    double resource_net;
    double condition_net;
};

std::vector<Values> simulate(const Scenario& scenario, int steps) {
    double backlog = 80.0;
    double resource = 600.0;
    double condition = 72.0;

    std::vector<Values> rows;

    for (int time = 1; time <= steps; ++time) {
        double arrivals = 18.0 * scenario.arrival_multiplier;

        if ((scenario.name == "capacity_and_conservation" || scenario.name == "adaptive_recovery") && time >= 50) {
            arrivals = 18.0 * 0.72 * scenario.arrival_multiplier;
        }
        if (scenario.name == "delayed_response" && time >= 75) {
            arrivals = 18.0 * 0.72 * scenario.arrival_multiplier;
        }

        double extraction = time >= scenario.resource_policy_time ? scenario.extraction_after : scenario.extraction_before;
        double maintenance = time >= scenario.maintenance_policy_time ? scenario.maintenance_after : scenario.maintenance_before;

        double completions = std::min(backlog + arrivals, 12.0 + scenario.completion_shift + 0.08 * backlog);
        double backlog_net = arrivals - completions;
        backlog = std::max(0.0, backlog + backlog_net);

        double regeneration = 0.045 * resource * (1.0 - resource / 1000.0);
        double resource_net = regeneration - extraction;
        resource = std::max(0.0, resource + resource_net);

        double wear = 1.4 + 0.012 * std::max(0.0, 100.0 - condition);
        double condition_net = maintenance - wear;
        condition = std::min(100.0, std::max(0.0, condition + condition_net));

        rows.push_back({backlog, resource, condition, backlog_net, resource_net, condition_net});
    }

    return rows;
}

double mean_net(const std::vector<Values>& rows, const std::string& stock) {
    double total = 0.0;
    for (const Values& row : rows) {
        if (stock == "backlog") {
            total += row.backlog_net;
        } else if (stock == "resource") {
            total += row.resource_net;
        } else {
            total += row.condition_net;
        }
    }
    return total / static_cast<double>(rows.size());
}

int main() {
    std::vector<Scenario> scenarios = {
        {"baseline", 1.00, 0.0, 24.0, 24.0, 999, 0.9, 0.9, 999},
        {"capacity_and_conservation", 0.85, 2.0, 22.0, 12.0, 70, 1.2, 2.8, 60},
        {"delayed_response", 1.00, 1.5, 24.0, 12.0, 85, 0.9, 2.8, 85},
        {"adaptive_recovery", 0.90, 3.0, 22.0, 10.0, 55, 1.4, 3.4, 50}
    };

    std::cout << "scenario,stock,initial_value,final_value,minimum_value,maximum_value,mean_net_flow\n";
    std::cout << std::fixed << std::setprecision(6);

    for (const Scenario& scenario : scenarios) {
        std::vector<Values> rows = simulate(scenario, 120);

        std::vector<std::pair<std::string, std::vector<double>>> stock_values = {
            {"backlog", {}},
            {"resource", {}},
            {"infrastructure_condition", {}}
        };

        for (const Values& row : rows) {
            stock_values[0].second.push_back(row.backlog);
            stock_values[1].second.push_back(row.resource);
            stock_values[2].second.push_back(row.condition);
        }

        for (const auto& pair : stock_values) {
            const std::string& stock = pair.first;
            const std::vector<double>& values = pair.second;

            double minimum = *std::min_element(values.begin(), values.end());
            double maximum = *std::max_element(values.begin(), values.end());

            std::cout
                << scenario.name << ","
                << stock << ","
                << values.front() << ","
                << values.back() << ","
                << minimum << ","
                << maximum << ","
                << mean_net(rows, stock) << "\n";
        }
    }

    return 0;
}
