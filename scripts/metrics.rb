# metrics.rb
# Author: Frank Lockom
#
# metrics for comparison of different mappings without simulation results
# used to implement remapping algorithims


# gets the similarity between the default and replacement stratedgy
# tg      - the default mapping
# mapping - the replacement stratedgy
# n       - n column mesh
# weight  - weight given to average, weight given to variance is 1-weight
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def similarity(tg,mapping,n,weight,sim = nil, default = nil)
  return weight*normalized_avg_tfo_delta(tg,mapping,n,sim,default) + 
    (1-weight)*tfo_delta_variance(tg,mapping,n,sim,default)
end

# normalized average variation of traffic flow occupancy difference
# tg      - the task graph(default mapping). see read_TG(infile) for format
# mapping - the replacement stratedgy
# n       - n column mesh
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def tfo_delta_variance(tg,mapping,n,sim = nil, default = nil)
  avg = avg_traffic_flow_occupancy(tg,{},n,sim,default)
  avg_dif = normalized_avg_tfo_delta(tg,mapping,n,sim,default)
  Math.sqrt(tg[1].inject(0.0){ |sum,edge|
              sum + (tfo_delta(tg,mapping,edge[0],edge[1],n,sim,default)/avg - avg_dif)**2
            }/tg[1].size)
end


# normalized average traffic flow occupancy delta
# tg      - the task graph(default mapping). see read_TG(infile) for format
# mapping - the replacement stratedgy
# n       - n column mesh
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def normalized_avg_tfo_delta(tg,mapping,n,sim = nil, default = nil)
  tg[1].inject(0.0){ |sum,edge|
    sum + tfo_delta(tg,mapping,edge[0],edge[1],n,sim,default)
  }/(avg_traffic_flow_occupancy(tg,{},n,sim,default)*tg[1].size)
end

# averages traffic_flow_occupancy() for every edge in tg
# tg      - the task graph. see read_TG(infile) for format
# mapping - the replacement stratedgy
# n       - n column mesh
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def avg_traffic_flow_occupancy(tg,mapping,n, sim = nil, default = nil)
  tg[1].inject(0.0){ |sum,edge|
    sum + traffic_flow_occupancy(tg,mapping,edge[0],edge[1],n,sim,default)
  }/tg[1].size
end

# gets the delta between the default tg and the mapping on the edge from i to j
# tg      - the task graph(default). see read_TG(infile) for format
# mapping - the replacement stratedgy
# i,j     - get the difference on edge i->j
# n       - n column mesh
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def tfo_delta(tg,mapping,i,j,n,sim = nil,default = nil)
  (traffic_flow_occupancy(tg,{},i,j,n,sim,default) - traffic_flow_occupancy(tg,mapping,i,j,n,sim,default)).abs
end


# gets the sum of all the tfos for each edge which invovles node i
# tg      - the task graph
# mapping - a replacement stratedgy
# i       - total_tfo for core i(in tg not mapping)
# n       - n column mesh
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def total_tfo(tg,mapping,i,n,sim = nil,default = nil)  
  tg[1].inject(0) {|sum,edge|
    if(edge[0] == i || edge[1] == i)
      sum + traffic_flow_occupancy(tg,mapping,edge[0],edge[1],n,sim,default)
    else
      sum
    end
  }
end

# gets the traffic_flow_occupancy as defined in KE's paper
# tg      - the task graph. see read_TG(infile) for format
# mapping - the replacement stratedgy
# i,j     - get the occupancy from virtual cores i->j
# n       - n column mesh
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def traffic_flow_occupancy(tg,mapping,i,j,n,sim = nil,default = nil)  
  # get the physical core location
  pi = (mapping[i] == nil)? i : mapping[i]
  pj = (mapping[j] == nil)? j : mapping[j]
  
  if sim != nil    
    return sim[{pi=>pj}]     if mapping != {}
    return default[{pi=>pj}] 
  end

  volume = 0
  # get the volume
  tg[1].each do |edge|
    if(edge[0] == i && edge[1] == j )
      volume = edge[2] 
    end
  end
  volume + hop_count_XY(pi,pj,n)
end


# gets the hop count from physical core i to j
# using XY routing with a mesh of size n columns
def hop_count_XY(i,j,n)
  (i%n - j%n).abs + (i/n - j/n).abs
end
