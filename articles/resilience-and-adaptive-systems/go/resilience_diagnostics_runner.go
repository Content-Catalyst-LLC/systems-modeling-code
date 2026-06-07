package main
import (
  "encoding/csv"
  "fmt"
  "math"
  "os"
  "path/filepath"
)
type Scenario struct{Name string; InitialCapacity, Erosion, LearningGain, ShockMultiplier, CapacityFloor float64}
func shockAt(t int, m float64) float64 { switch t {case 25: return 1.5*m; case 55: return 1.7*m; case 90: return 2.0*m; case 125: return 2.2*m; case 155: return 2.5*m}; return 0 }
func main(){
  scenarios := []Scenario{{"baseline_adaptation",0.22,0.0009,0.0007,1,0.03},{"weakened_capacity",0.16,0.0014,0.0003,1,0.03},{"compound_stress",0.18,0.0012,0.0004,1.35,0.03},{"learning_investment",0.24,0.0006,0.0012,1,0.03},{"high_redundancy",0.27,0.0008,0.0008,0.85,0.05},{"fragile_efficiency",0.14,0.0018,0.0002,1.2,0.02}}
  os.MkdirAll(filepath.Join("outputs","tables"),0755)
  path:=filepath.Join("outputs","tables","go_resilience_adaptive_system_summary.csv")
  file,err:=os.Create(path); if err!=nil{panic(err)}; defer file.Close()
  w:=csv.NewWriter(file); defer w.Flush()
  w.Write([]string{"scenario","final_state","maximum_abs_state","minimum_performance","mean_performance","initial_adaptive_capacity","final_adaptive_capacity","adaptive_capacity_change","cumulative_performance_loss"})
  for _,s:=range scenarios{state:=0.0; cap:=s.InitialCapacity; maxAbs:=0.0; minPerf:=1.0; totalPerf:=0.0; totalLoss:=0.0; for t:=1;t<=180;t++{sh:=shockAt(t,s.ShockMultiplier); if t>1{cap=math.Max(s.CapacityFloor,cap-s.Erosion+s.LearningGain*math.Max(0,1-math.Abs(state))); state=state-cap*state+sh}; abs:=math.Abs(state); perf:=math.Max(0,1-abs/4); maxAbs=math.Max(maxAbs,abs); minPerf=math.Min(minPerf,perf); totalPerf+=perf; totalLoss+=1-perf}; w.Write([]string{s.Name,fmt.Sprintf("%.6f",state),fmt.Sprintf("%.6f",maxAbs),fmt.Sprintf("%.6f",minPerf),fmt.Sprintf("%.6f",totalPerf/180),fmt.Sprintf("%.6f",s.InitialCapacity),fmt.Sprintf("%.6f",cap),fmt.Sprintf("%.6f",cap-s.InitialCapacity),fmt.Sprintf("%.6f",totalLoss)})}
  fmt.Println("Go resilience diagnostics runner complete."); fmt.Println(path)
}
