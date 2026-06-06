use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};

type Graph = HashMap<usize, HashSet<usize>>;

fn add_edge(graph: &mut Graph, a: usize, b: usize) {
    graph.entry(a).or_insert_with(HashSet::new).insert(b);
    graph.entry(b).or_insert_with(HashSet::new).insert(a);
}

fn build_graph() -> Graph {
    let mut graph: Graph = HashMap::new();

    for node in 0..48 {
        graph.insert(node, HashSet::new());
    }

    let edges = vec![
        (0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (3, 5), (4, 6), (5, 7),
        (6, 8), (7, 9), (8, 10), (9, 11), (10, 12), (11, 13), (12, 14), (13, 15),
        (16, 17), (16, 18), (17, 19), (18, 19), (18, 20), (19, 21), (20, 22), (21, 23),
        (22, 24), (23, 25), (24, 26), (25, 27), (26, 28), (27, 29), (28, 30), (29, 31),
        (32, 33), (32, 34), (33, 35), (34, 35), (34, 36), (35, 37), (36, 38), (37, 39),
        (38, 40), (39, 41), (40, 42), (41, 43), (42, 44), (43, 45), (44, 46), (45, 47),
        (3, 19), (7, 25), (21, 35), (29, 42), (12, 37), (2, 18), (18, 34), (2, 34),
    ];

    for (a, b) in edges {
        add_edge(&mut graph, a, b);
    }

    graph
}

fn component_sizes(graph: &Graph) -> Vec<usize> {
    let mut seen: HashSet<usize> = HashSet::new();
    let mut sizes: Vec<usize> = Vec::new();

    for node in graph.keys() {
        if seen.contains(node) {
            continue;
        }

        let mut queue = VecDeque::new();
        queue.push_back(*node);
        seen.insert(*node);
        let mut size = 0usize;

        while let Some(current) = queue.pop_front() {
            size += 1;
            if let Some(neighbors) = graph.get(&current) {
                for neighbor in neighbors {
                    if !seen.contains(neighbor) {
                        seen.insert(*neighbor);
                        queue.push_back(*neighbor);
                    }
                }
            }
        }

        sizes.push(size);
    }

    sizes
}

fn main() -> std::io::Result<()> {
    let graph = build_graph();
    let node_count = graph.len();
    let edge_count: usize = graph.values().map(|neighbors| neighbors.len()).sum::<usize>() / 2;
    let degrees: Vec<usize> = graph.values().map(|neighbors| neighbors.len()).collect();
    let max_degree = degrees.iter().max().unwrap_or(&0);
    let average_degree = degrees.iter().sum::<usize>() as f64 / node_count as f64;
    let possible_edges = node_count * (node_count - 1) / 2;
    let density = edge_count as f64 / possible_edges as f64;
    let sizes = component_sizes(&graph);
    let largest = sizes.iter().max().unwrap_or(&0);

    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_network_diagnostics.csv")?;
    let mut writer = BufWriter::new(file);

    writeln!(writer, "metric,value")?;
    writeln!(writer, "nodes,{}", node_count)?;
    writeln!(writer, "edges,{}", edge_count)?;
    writeln!(writer, "density,{:.6}", density)?;
    writeln!(writer, "average_degree,{:.6}", average_degree)?;
    writeln!(writer, "maximum_degree,{}", max_degree)?;
    writeln!(writer, "component_count,{}", sizes.len())?;
    writeln!(writer, "largest_component_size,{}", largest)?;
    writeln!(writer, "largest_component_share,{:.6}", *largest as f64 / node_count as f64)?;

    println!("Rust network diagnostics complete.");
    println!("outputs/tables/rust_network_diagnostics.csv");

    Ok(())
}
