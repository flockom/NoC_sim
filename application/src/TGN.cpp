#include "TGN.h"
#include "../../config/extern.h"

TGN::TGN(sc_module_name TGN): ipcore(TGN){
  SC_CTHREAD(init, clock.pos());
}

void TGN::init(){
  /*set the period count*/
  period_count = 0;
 
  /*get the tileID*/
  char str_id[20];     // 20 digits in UL, log(2^64)
  sprintf(str_id,"%d",tileID);

  /*traffic log file log/traffic/tile-n*/
  string logfile = string("./log/traffic/tile-") + string(str_id);


  /*open the traffic stream*/  
  trafstream.open(logfile.c_str());
  
  /*load the config files config/traffic/tile-n*/  
  ifstream instream;
  instream.open("config/traffic/TGN");
  if(!instream.is_open()){
    cout << "TaskGraphNode:ERROR: config file \"config/traffic/TGN\" not found!\n";
    exit(1);
  }
  
  while(!instream.eof()){
    string field;
    instream >> field;
    
    if(field == "EDGE"){
      UI ptid;
      UI ctid;
      UI volume;
      instream >> ptid >> ctid >> volume;
      if(ptid == tileID){        /*this is the parent of this edge*/
	child.push_back(ctid);      
	child_volume[ctid] = volume;
      }else if (ctid == tileID){ /*child of this edge*/
	parent.push_back(ptid);
	parent_volume[ptid] = volume;      
	recv_buf[ptid] = 0;
	parent_period_count[ptid] = 0;	   	   
      }
    }
    else if(field == "NODE"){
      UI exec;
      UI tid;
      instream >> tid >> exec;
      if(tid == tileID)
	execution_time = exec;
    }
  }
  instream.close();
}

void TGN::send(){
  wait(WARMUP);
  if(child.size() < 1) return;
  int pkt_id = 0;
  while(sim_count < TG_NUM){      
    if(dcheck()){
      wait(execution_time);
      if(child.size() > 0){	
	flit *flit_out;
	for(int i = 0;i < child.size();i++){
	  for(int ii = 0; ii < child_volume[child[i]];ii++){
	    flit_out = create_hdt_flit(pkt_id++,0,child[i]);
	    while (!credit_in[0].read().freeBuf){
	      printf("Tile-%d: Buffer is full!!!!zomg\n",tileID);
	      wait();            
	    }
	    flit_outport.write(*flit_out);	
	    wait(6);
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

void TGN::recv(){

  /*~+~+~+~+~+~+~+~+~For Nirgam sim_results+~+~+~+~+~+~+~+~+~+~+~+~+~*/      
  int difference;
  sum = 0;
  /*~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~*/
  int communication_start; /*to measure communication time*/
  while(true){
    wait();
    if(flit_inport.event()){
      flit flit_in = flit_inport.read();

      /*~+~+~+~+~+~+~+~+~For Nirgam sim_results+~+~+~+~+~+~+~+~*/      
      flit_in.simdata.atimestamp = sim_count;  
      flit_in.simdata.atime = sc_time_stamp(); 
      difference = 0;
      difference = flit_in.simdata.atimestamp-flit_in.simdata.gtimestamp;
      count_total++;
      sum+=difference;
      /*~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~*/

      UI src = flit_in.src;
      //printf("Tile-%d: Recieved packet from %d at %lld\n",tileID,src,sim_count);
      trafstream<<"recv "<< src << " " 
		<< flit_in.simdata.gtimestamp << " " 
		<< sim_count << " "
		<< difference <<endl;
      if(recv_buf[src] == 0){ /*first packet in communication period*/
	communication_start = flit_in.simdata.gtimestamp;
      }
      if(++recv_buf[src] == parent_volume[src]){/*last packet in communication period*/
	parent_period_count[src]++;
	recv_buf[src] = 0;
	//printf("Tile-%d: Dependency #%d satisfied from %d\n",tileID,parent_period_count[src],src);
	trafstream << "communication_time " << sim_count - communication_start
		   << " on period "<< parent_period_count[src]
		   << " from tile "<< src<<endl;
      }      
    }
  }
}

bool TGN::dcheck(){  
  for(int i=0;i<parent.size();i++){
    if(parent_period_count[parent[i]]<=period_count)
      return false;
  }
  return true;
}


extern "C"{
    ipcore *maker(){
      return new TGN("TGN");
    }
}

