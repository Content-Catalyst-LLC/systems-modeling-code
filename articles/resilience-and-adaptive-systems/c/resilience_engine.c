#include <math.h>
#include <stdio.h>
#define STEPS 180
static double shock_at(int t, double m){ if(t==25)return 1.5*m; if(t==55)return 1.7*m; if(t==90)return 2.0*m; if(t==125)return 2.2*m; if(t==155)return 2.5*m; return 0.0; }
static void simulate(const char *name,double cap0,double erosion,double learning,double mult,double floorv){ double state=0.0, cap=cap0; for(int t=1;t<=STEPS;t++){ double shock=shock_at(t,mult); if(t>1){ cap=fmax(floorv,cap-erosion+learning*fmax(0.0,1.0-fabs(state))); state=state-cap*state+shock; } double abs_state=fabs(state); double performance=fmax(0.0,1.0-abs_state/4.0); printf("%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f\n",name,t,state,abs_state,cap,shock,performance); }}
int main(void){ printf("scenario,time,state,absolute_state,adaptive_capacity,shock,performance\n"); simulate("baseline_adaptation",0.22,0.0009,0.0007,1.00,0.03); simulate("weakened_capacity",0.16,0.0014,0.0003,1.00,0.03); simulate("compound_stress",0.18,0.0012,0.0004,1.35,0.03); simulate("learning_investment",0.24,0.0006,0.0012,1.00,0.03); simulate("high_redundancy",0.27,0.0008,0.0008,0.85,0.05); simulate("fragile_efficiency",0.14,0.0018,0.0002,1.20,0.02); return 0; }
