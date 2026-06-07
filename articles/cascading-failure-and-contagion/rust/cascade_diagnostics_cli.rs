use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

struct Scenario {
    name: &'static str,
    node_count: usize,
    link_probability: f64,
    threshold: f64,
    seed_count: usize,
    max_steps: usize,
}

struct Summary {
    scenario: &'static str,
    final_affected_count: usize,
    final_affected_share: f64,
    cascade_duration: usize,
    maximum_new_failures: usize,
    mean_degree: f64,
    maximum_degree: usize,
}

fn deterministic_edge(source: usize, target: usize, probability: f64) -> bool {
    let raw = (((source + 1) * (target + 3)) as f64 * 12.9898).sin() * 43758.5453;
    let value = raw.fract().abs();
    value < probability
}

fn build_network(node_count: usize, probability: f64) -> Vec<Vec<usize>> {
    let mut graph = vec![Vec::<usize>::new(); node_count];

    for source in 0..node_count {
        for target in (source + 1)..node_count {
            if deterministic_edge(source, target, probability) {
                graph[source].push(target);
                graph[target].push(source);
            }
        }
    }

    graph
}

fn simulate(s: &Scenario) -> Summary {
    let graph = build_network(s.node_count, s.link_probability);
    let degrees: Vec<usize> = graph.iter().map(|neighbors| neighbors.len()).collect();

    let total_degree: usize = degrees.iter().sum();
    let maximum_degree: usize = *degrees.iter().max().unwrap_or(&0);
    let mean_degree = total_degree as f64 / s.node_count as f64;

    let mut affected = vec![false; s.node_count];

    for _ in 0..s.seed_count {
        let mut best_node: Option<usize> = None;
        let mut best_degree = 0usize;

        for node in 0..s.node_count {
            if !affected[node] && (best_node.is_none() || degrees[node] > best_degree) {
                best_node = Some(node);
                best_degree = degrees[node];
            }
        }

        if let Some(node) = best_node {
            affected[node] = true;
        }
    }

    let mut affected_count = affected.iter().filter(|value| **value).count();
    let mut maximum_new_failures = affected_count;
    let mut cascade_duration = 0usize;

    for step in 1..=s.max_steps {
        let mut newly_affected: Vec<usize> = Vec::new();

        for node in 0..s.node_count {
            if affected[node] || degrees[node] == 0 {
                continue;
            }

            let affected_neighbors = graph[node]
                .iter()
                .filter(|neighbor| affected[**neighbor])
                .count();

            let exposure_share = affected_neighbors as f64 / degrees[node] as f64;

            if exposure_share >= s.threshold {
                newly_affected.push(node);
            }
        }

        if newly_affected.is_empty() {
            break;
        }

        for node in &newly_affected {
            affected[*node] = true;
        }

        affected_count += newly_affected.len();
        maximum_new_failures = maximum_new_failures.max(newly_affected.len());
        cascade_duration = step;
    }

    Summary {
        scenario: s.name,
        final_affected_count: affected_count,
        final_affected_share: affected_count as f64 / s.node_count as f64,
        cascade_duration,
        maximum_new_failures,
        mean_degree,
        maximum_degree,
    }
}

fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario { name: "baseline_threshold", node_count: 90, link_probability: 0.055, threshold: 0.25, seed_count: 4, max_steps: 40 },
        Scenario { name: "lower_threshold", node_count: 90, link_probability: 0.055, threshold: 0.18, seed_count: 4, max_steps: 40 },
        Scenario { name: "higher_connectivity", node_count: 90, link_probability: 0.075, threshold: 0.25, seed_count: 4, max_steps: 40 },
        Scenario { name: "larger_initial_shock", node_count: 90, link_probability: 0.055, threshold: 0.25, seed_count: 8, max_steps: 40 },
    ];

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_threshold_cascade_summary.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(
        writer,
        "scenario,final_affected_count,final_affected_share,cascade_duration,maximum_new_failures,mean_degree,maximum_degree,diagnostic_label"
    )?;

    for scenario in &scenarios {
        let result = simulate(scenario);
        let label = if result.final_affected_share >= 0.5 {
            "systemic cascade"
        } else {
            "contained cascade"
        };

        writeln!(
            writer,
            "{},{},{:.6},{},{},{:.6},{},{}",
            result.scenario,
            result.final_affected_count,
            result.final_affected_share,
            result.cascade_duration,
            result.maximum_new_failures,
            result.mean_degree,
            result.maximum_degree,
            label
        )?;
    }

    println!("Rust cascade diagnostics complete.");
    println!("outputs/tables/rust_threshold_cascade_summary.csv");

    Ok(())
}
