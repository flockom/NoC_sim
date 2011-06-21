#include "test.h"
#include "../../config/extern.h"

App_test::App_test(sc_module_name App_test): ipcore(App_test){
  SC_CTHREAD(init, clock.pos());
}

void App_test::init(){
  period_count = 0;
  char str_id[20];     // 20 digits in UL, log(2^64)
  sprintf(str_id,"%d",tileID);
  string traffic_filename = string("config/traffic/tile-") + string(str_id);
  ifstream instream;
  instream.open(traffic_filename.c_str());
  if(!instream.is_open()){
    cout << "TaskGraphNode:ERROR: config file \""
	 <<traffic_filename<< "\" not found!\n";
    exit(1);
  }
  
  while(!instream.eof()){
    string field;
    instream >> field;
    
    if(field == "PARENT"){
      UI tid;
      instream >> tid;
      parent.push_back(tid);
      
      UI volume;
      instream >> volume;
      parent_volume[tid] = volume;
      
      recv_buf[tid] = 0;
      parent_period_count[tid] = 0;	   	   
    }
    else if(field == "CHILD"){
      UI tid;
      instream >> tid;
      child.push_back(tid);
      
      UI volume;
      instream >> volume;
      child_volume[tid] = volume;
    }
    else if(field == "EXEC"){
      UI exec;
      instream >> execution_time;
    }
  }
  instream.close();
}

void App_test::send(){
  wait(WARMUP);
  int pkt_id = 0;
  while(sim_count < TG_NUM){      
    if(dcheck()){
      wait(execution_time);
      if(child.size() > 0){	
	flit *flit_out;
	for(int i = 0;i < child.size();i++){
	  for(int ii = 0; ii < child_volume[child[i]];ii++){
	    flit_out = create_hdt_flit(pkt_id++,0,child[i]);
	    flit_outport.write(*flit_out);	
	    wait(2);
	  }
	}
      }
      period_count++;
      printf("Tile-%d: Completed period #%d\n",tileID,period_count);
    }
    else{
      wait();
    }
  }
}

void App_test::recv(){
  while(true){
    wait();
    if(flit_inport.event()){
      flit flit_in = flit_inport.read();
      UI src = flit_in.src;
      //printf("Tile-%d: Recieved packet from %d at %lld\n",tileID,src,sim_count);
      if(++recv_buf[src] == parent_volume[src]){
	parent_period_count[src]++;
	recv_buf[src] = 0;
	printf("Tile-%d: Dependency #%d satisfied from %d\n",tileID,parent_period_count[src],src);
      }      
    }
  }
}

bool App_test::dcheck(){  
  for(int i=0;i<parent.size();i++){
    if(parent_period_count[parent[i]]<=period_count)
      return false;
  }
  return true;
}


extern "C"{
    ipcore *maker(){
      return new App_test("App_test");
    }
}

