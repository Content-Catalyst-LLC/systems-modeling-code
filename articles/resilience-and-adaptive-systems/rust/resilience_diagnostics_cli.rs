use std::fs::{create_dir_all, File};
use std::io::{BufWriter, Write};
struct Scenario { name: &'static str, initial_capacity: f64, erosion: f64, learning_gain: f64, shock_multiplier: f64, capacity_floor: f64 }
fn shock_at(t: usize, m: f64) -> f64 { match t {25 => 1.5*m, 55 => 1.7*m, 90 => 2.0*m, 125 => 2.2*m, 155 => 2.5*m, _ => 0.0} }
fn main() -> std::io::Result<()> {
    let scenarios = vec![
        Scenario{name:"baseline_adaptation",initial_capacity:0.22,erosion:0.0009,learning_gain:0.0007,shock_multiplier:1.0,capacity_floor:0.03},
        Scenario{name:"weakened_capacity",initial_capacity:0.16,erosion:0.0014,learning_gain:0.0003,shock_multiplier:1.0,capacity_floor:0.03},
        Scenario{name:"compound_stress",initial_capacity:0.18,erosion:0.0012,learning_gain:0.0004,shock_multiplier:1.35,capacity_floor:0.03},
        Scenario{name:"learning_investment",initial_capacity:0.24,erosion:0.0006,learning_gain:0.0012,shock_multiplier:1.0,capacity_floor:0.03},
        Scenario{name:"high_redundancy",initial_capacity:0.27,erosion:0.0008,learning_gain:0.0008,shock_multiplier:0.85,capacity_floor:0.05},
        Scenario{name:"fragile_efficiency",initial_capacity:0.14,erosion:0.0018,learning_gain:0.0002,shock_multiplier:1.2,capacity_floor:0.02},
    ];
    create_dir_all("outputs/tables")?;
    let file = File::create("outputs/tables/rust_resilience_adaptive_system_summary.csv")?;
    let mut w = BufWriter::new(file);
    writeln!(w,"scenario,final_state,maximum_abs_state,minimum_performance,mean_performance,initial_adaptive_capacity,final_adaptive_capacity,adaptive_capacity_change,cumulative_performance_loss")?;
    for s in &scenarios { let mut state=0.0_f64; let mut cap=s.initial_capacity; let mut max_abs=0.0_f64; let mut min_perf=1.0_f64; let mut total_perf=0.0_f64; let mut total_loss=0.0_f64; for t in 1..=180 { let sh=shock_at(t,s.shock_multiplier); if t>1 { cap=(cap-s.erosion+s.learning_gain*(1.0-state.abs()).max(0.0)).max(s.capacity_floor); state=state-cap*state+sh; } let abs=state.abs(); let perf=(1.0-abs/4.0).max(0.0); max_abs=max_abs.max(abs); min_perf=min_perf.min(perf); total_perf+=perf; total_loss+=1.0-perf; } writeln!(w,"{},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6},{:.6}",s.name,state,max_abs,min_perf,total_perf/180.0,s.initial_capacity,cap,cap-s.initial_capacity,total_loss)?; }
    println!("Rust resilience diagnostics complete."); println!("outputs/tables/rust_resilience_adaptive_system_summary.csv"); Ok(())
}
