#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>
struct Scenario{std::string name; double cap0, erosion, learning, mult, floorv;};
double shock_at(int t,double m){if(t==25)return 1.5*m;if(t==55)return 1.7*m;if(t==90)return 2.0*m;if(t==125)return 2.2*m;if(t==155)return 2.5*m;return 0.0;}
int main(){std::vector<Scenario> ss={{"baseline_adaptation",0.22,0.0009,0.0007,1,0.03},{"weakened_capacity",0.16,0.0014,0.0003,1,0.03},{"compound_stress",0.18,0.0012,0.0004,1.35,0.03},{"learning_investment",0.24,0.0006,0.0012,1,0.03},{"high_redundancy",0.27,0.0008,0.0008,0.85,0.05},{"fragile_efficiency",0.14,0.0018,0.0002,1.2,0.02}}; std::cout<<"scenario,final_state,maximum_abs_state,minimum_performance,mean_performance,initial_adaptive_capacity,final_adaptive_capacity,adaptive_capacity_change,cumulative_performance_loss\n"<<std::fixed<<std::setprecision(6); for(auto&s:ss){double state=0,cap=s.cap0,maxabs=0,minperf=1,totalperf=0,totalloss=0; for(int t=1;t<=180;t++){double sh=shock_at(t,s.mult); if(t>1){cap=std::max(s.floorv,cap-s.erosion+s.learning*std::max(0.0,1.0-std::abs(state))); state=state-cap*state+sh;} double abs=std::abs(state); double perf=std::max(0.0,1.0-abs/4.0); maxabs=std::max(maxabs,abs); minperf=std::min(minperf,perf); totalperf+=perf; totalloss+=1-perf;} std::cout<<s.name<<","<<state<<","<<maxabs<<","<<minperf<<","<<totalperf/180.0<<","<<s.cap0<<","<<cap<<","<<cap-s.cap0<<","<<totalloss<<"\n";} }
