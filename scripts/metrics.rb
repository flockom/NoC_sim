# metrics.rb
# Author: Frank Lockom
#
# metrics for comparison of different mappings without simulation results
# used to implement remapping algorithims





# averages traffic_flow_occupancy() for every edge in tg
# tg      - the task graph. see read_TG(infile) for format
# mapping - the replacement stratedgy
# n,m     - n colums * m row mesh
def avg_traffic_flow_occupancy(tg,mapping,n,m)
  return tg[1].inject(0){ |sum,edge|
    sum += traffic_flow_occupancy(tg,mapping,edge[0],edge[1],n,m)
  }/tg[1].size
end



# gets the traffic_flow_occupancy as defined in KE's paper
# tg      - the task graph. see read_TG(infile) for format
# mapping - the replacement stratedgy
# i,j     - get the occupancy from virtual cores i->j
# n,m     - n colums * m row mesh
def traffic_flow_occupancy(tg,mapping,i,j,n,m)
  # get the physical core location
  pi = (mapping[i] == nil)? i : mapping[i]
  pj = (mapping[j] == nil)? j : mapping[j]
  volume = 0
  # get the volume
  tg[1].each do |edge|
    if(tg[1][edge][0] == i && tg[1][edge][1] == j )
      volume = tg[1][edge][3] 
    end
  end
  return volume * hop_count_XY(pi,pj,n,m)
end


# gets the hop count from physical core i to j
# using XY routing with a mesh of size n columns * m rows
def hop_count_XY(i,j,n,m)
  return (i%n - j%n).abs + (i/m - j/m).abs
end
