#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>
struct S{std::string n;double eid,mu,mug,dc,mc;};
int main(){std::vector<S> ss={{"delayed_transition",0.006,0.02,0.010,0.012,0.040},{"moderate_transition",0.012,0.06,0.025,0.010,0.040},{"accelerated_decarbonization",0.018,0.10,0.045,0.008,0.055},{"high_innovation_pathway",0.026,0.08,0.040,0.008,0.038}};std::cout<<"scenario,final_emissions,final_temperature_proxy,cumulative_emissions,cumulative_damages,cumulative_mitigation_cost,discounted_welfare_proxy,average_mitigation_rate,diagnostic_label\n"<<std::fixed<<std::setprecision(6);for(auto s:ss){double output=100,ei=0.42,mu=s.mu,ap=1,temp=1.2,ce=0,cd=0,cc=0,w=0,avg=0,n=0,fe=0;for(int y=2025;y<=2100;y+=5){if(y>2025){output*=pow(1.012,5);ei=std::max(0.02,ei*pow(1-s.eid,5));mu=std::min(0.98,mu+s.mug);}double e=output*ei*(1-mu);if(y>2025){ap=std::max(0.0,ap+0.012*e-0.010*ap);temp=std::max(0.0,temp+0.030*ap-0.012*temp);}double d=s.dc*temp*temp*output,c=s.mc*mu*mu*output,cons=std::max(0.0,output-d-c);double ww=log(cons+1)/pow(1.015,y-2025);ce+=e;cd+=d;cc+=c;w+=ww;avg+=mu;n++;fe=e;}std::string label=temp>3?"high climate pressure pathway":"lower climate pressure pathway";std::cout<<s.n<<","<<fe<<","<<temp<<","<<ce<<","<<cd<<","<<cc<<","<<w<<","<<avg/n<<","<<label<<"\n";}}
