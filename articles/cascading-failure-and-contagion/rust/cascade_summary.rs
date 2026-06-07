struct Node {
    sector: &'static str,
    capacity: f64,
    load: f64,
    threshold: f64,
}

fn main() {
    let nodes = vec![
        Node { sector: "energy", capacity: 100.0, load: 62.0, threshold: 0.75 },
        Node { sector: "water", capacity: 85.0, load: 70.0, threshold: 0.70 },
        Node { sector: "telecom", capacity: 90.0, load: 58.0, threshold: 0.72 },
        Node { sector: "health", capacity: 95.0, load: 82.0, threshold: 0.78 },
    ];

    println!("Cascade capacity diagnostics");

    for node in nodes {
        let load_ratio = node.load / node.capacity;
        let status = if load_ratio >= node.threshold { "failure risk" } else { "within threshold" };
        println!("{} load_ratio={:.3} threshold={:.3} status={}", node.sector, load_ratio, node.threshold, status);
    }
}
