# ttlatency.rb
# Author: Frank Lockom
# some routes for automating the nirgam task graph node (TGN) application

require_relative 'scrape.rb'
require_relative 'algorithms.rb'

# TODO: - run_replacement cannot do a replacement to a tile 
#         which is in the default mapping
#       - oal does not check the directory from nirgam.config that
#         sim_results will be in
# 

# get best results from a mapping (like returned from run_all_replacements_given_faulty)
# default:: the default overall average latency(no faulty cores)
# m::       a hash of replacement stratedgy=>[overall average latency,tt_latency]
def get_best_oal(default, m)
  min = 10000 # yes this is dirty
  best = nil
  m.each_pair do |strat,oal|
    tmin = (default-oal[0]).abs
    if tmin < min
      best = strat
      min = tmin
    end
  end
  return [best,m[best]]
end

def get_best_ttl(default,m)
  min = 10000 # yes this is dirty
  best = nil
  m.each_pair do |strat,ttl|
    avgttl = average_tt_latency(ttl[1])
    tmin = (default-avgttl).abs
    if tmin < min
      best = strat
      min = tmin
    end
  end
  return [best,m[best]]
end


# does run_replacement with every possible stratedgy, given the faulty set
# and the possible replacement cores
#  
# nirgam      -  the path to the nirgam root directory with a '/' at the end
# tg          -  the TaskGraph file with default configuration. 
#                ex nirgam/config/traffic/App2TG
# faulty      -  faulty set from default configuration e.g. [3,27,20]
# replacement -  available replacement tiles e.g. [5,11,17,23,29]
def run_all_replacements_given_faulty(nirgam,tg,faulty,replacement)
  results = Hash.new
  mappings = get_mappings(faulty,replacement)
  count = 1
  mappings.each do |map|
    puts "Progress: #{count}/#{mappings.length}"
    count += 1
    results[map] = run_replacement(nirgam,tg,map)
  end
  return results
end

# runs nirgam using the TGN application with a given replacement
# stratedgy.
# nirgam    -  the path to the nirgam root directory with a '/' at the end
# tg        -  the TaskGraph file with default configuration. 
#              ex nirgam/config/traffic/App2TG
# stratedgy -  replacement stratedgy of the form:
#              {dtileID=>rtileID,dtileID=>ntileID}
#              where dtileID is a tileID from tg and
#              rtileID is a replacement tile.
def run_replacement(nirgam,tg,stratedgy)
  # load up tg
  task_graph = read_TG(tg)
  # swap the cores with those in stratedgy
  stratedgy.each_pair do |d,r|
    #change all the nodes
    task_graph[0].each_index do |i|
      task_graph[0][i][0] = r if task_graph[0][i][0] == d
    end
    #change all the edges
    task_graph[1].each_index do |i|
      task_graph[1][i][0] = r if task_graph[1][i][0] == d # source
      task_graph[1][i][1] = r if task_graph[1][i][1] == d # dest
    end
  end
  # write tg
  write_TG(task_graph,nirgam+"config/traffic/TGN")    
  # remove old traffic logs and run nirgam
  `cd #{nirgam};rm ./log/traffic/*;./nirgam`
  # get OAL
  average_latency = oal(nirgam+"results/BTY/stats/sim_results")
  # get tt_latency
  tt_latency = get_average_tt_latency(nirgam+"log/traffic/")
  # return [tt_latency,OAL]  
  return [average_latency,tt_latency]
end

# averages the task-task latencies, as returned by get_tt_latency
# oal gives average per flit, this is average per link(regardless of #flits).
def average_tt_latency(tt_latency)
  result = 0
  tt_latency.each_value do |v|
    result += v/tt_latency.size.to_f
  end
  return result
end
