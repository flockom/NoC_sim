#ifndef _App_test_H_
#define _App_test_H_

#include "../../core/ipcore.h"
#include <fstream>
#include <string>
#include <math.h>
#include <map>

using namespace std;

struct App_test : public ipcore {
	
	/// Constructor
	SC_CTOR(App_test);
	
	// PROCESSES /////////////////////////////////////////////////////
	void send();			///< send flits
	void recv();			///< recieve flits
	void init();                    // read config files
	// PROCESSES END /////////////////////////////////////////////////////

	//HELPERS
	bool dcheck(); /*checks if dependencies are satisfied*/
	//HELPERS
	
	//VARIABLES
	ULL execution_time;             /* the execution time for this node in clock cycles see ipcore.sim_count*/
	UI period_count;                /* #times this task has executed. better name?*/
	

	vector<UI> child;               /*list of child tiles ctid*/
	map<UI,UI> child_volume;        /*map of ptid->volume*/
  
	vector<UI> parent;              /*list of parent tiles ptid*/	
	map<UI,UI> parent_volume;       /*map of ctid->volume*/     
	map<UI,UI> recv_buf;            /*map of ptid -> #bytes recieved between (0 and volume)*/  
	map<UI,UI> parent_period_count; /*map of ptid -> finished periods*/	
	// VARIABLES END 
	
};

#endif
