fn main() {
    let steps = 140;
    let mut stock_a = vec![0.0; steps];
    let mut stock_b = vec![0.0; steps];

    stock_a[0] = 20.0;
    stock_b[0] = 10.0;

    let growth_a_rate = 0.06;
    let growth_b_rate = 0.04;
    let b_to_a_pressure = 0.02;
    let a_to_b_support = 0.04;
    let b_balancing_rate = 0.03;
    let target_b = 45.0;

    for t in 1..steps {
        let reinforcing_a = growth_a_rate * stock_a[t - 1];
        let pressure_from_b = -b_to_a_pressure * stock_b[t - 1];

        let reinforcing_b = growth_b_rate * stock_b[t - 1];
        let support_from_a = a_to_b_support * stock_a[t - 1];
        let balancing_b = b_balancing_rate * f64::max(stock_b[t - 1] - target_b, 0.0);

        stock_a[t] = stock_a[t - 1] + reinforcing_a + pressure_from_b;
        stock_b[t] = stock_b[t - 1] + reinforcing_b + support_from_a - balancing_b;
    }

    println!("Final stock A: {:.6}", stock_a[steps - 1]);
    println!("Final stock B: {:.6}", stock_b[steps - 1]);
}
